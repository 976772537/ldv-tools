package Parser;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(parse_error_trace);

use English;
use strict;

# Add some nonstandard local Perl packages.
require Entity;
require Annotation;
use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info
  print_debug_debug print_debug_trace print_debug_all get_debug_level);


################################################################################
# Subroutine prototypes.
################################################################################

# Read something placed into brackets.
# args: some string.
# retn: a content of brackets or undef if it can't be read.
sub read_brackets($);

# Read an equality sign and an integer number (line number in source code).
# args: some string.
# retn: a corresponding integer line number or undef if it can't be read.
sub read_equal_int($);

# Read an equality sign and a path to a source code file.
# args: some string.
# retn: a corresponding source code file path or undef if it can't be read.
sub read_equal_src($);

# Read a next line from a specified file handler and process it a bit.
# args: a file handler from where a new line will be read.
# retn: a processed line or undef when there is no more lines.
sub read_line($);

# Read a LDV comment.
# args: some string.
# retn: a processed ldv comment or undef if it can't be read.
sub read_ldv_comment($);

# Read locals (function parameter names).
# args: some string.
# retn: processed names or undef if it can't be read.
sub read_locals($);

# Read a location. The location includes an useless location, a path to a source
# code file and a line number.
# args: some string.
# retn: a processed path to a file and a line number or undef if it can't be read.
sub read_location($);

# Parse a given error trace and convert it into internal representation (tree).
# args: reference to a parameters hash (error trace, engine, etc.).
# retn: reference to a result hash (root node of a tree, dependencies, etc.).
sub parse_error_trace($);


################################################################################
# Global variables.
################################################################################

# Error trace tree nodes, annotations and their processing functions:
#   tree node
#     Block
#     FunctionCall
#     Pred
#     Skip
#   annotation
#     LDV
#     Location
#     Locals
# Note that at the moment they are the same that are used for BLAST engine, but
# in future this list can be extended if necessary.
my %et_element = (
  'tree node' => {
    my $et_block = 'Block', \&read_brackets,
    my $et_func_call = 'FunctionCall', \&read_brackets,
    my $et_cond = 'Pred', \&read_brackets,
    my $et_root = 'Root', '',
    my $et_skip = 'Skip', ''
  },
  'annotation' => {
    my $et_ldv_comment = 'LDV', \&read_ldv_comment,
    my $et_params = 'Locals', \&read_locals,
    my $et_location = 'Location', \&read_location
  });

# Reqular expression to extract a error trace element kind.
my $et_element_kind = '^([^=\(:]+)';

# A previously processed path to a source code file and a line number. They are
# needed in cases when a current entity location can't be processed
# successfully.
my $src_prev;
my $line_prev;


################################################################################
# Subroutines.
################################################################################

sub parse_error_trace($)
{
  my $params = shift;

  my $engine = $params->{'engine'};
  my $fh = $params->{'error trace file handler'};

  # The list of current parents.
  my @parents = ();

  # Currently processed entity and annotation.
  my $entity;
  my $annotation;

  # Stored pre annotations.
  my @pre_annotations = ();

  # These variables are described in the main script.
  my %dependencies;
  my %files_long_name;
  my %files_short_name;

  # Create the tree root corresponding to the entry point or main.
  $entity = Entity->new({'engine' => $engine, 'kind' => $et_root});
  push(@parents, $entity);

  while(1)
  {
    # Read some element, either tree node (like function call) or annotation
    # (like a path source code file). Note that some elements can be placed
    # into several lines so process all needed lines to obtain the full text of
    # given elements. Finish when there is no more lines.
    my $iselement_read = 0;
    my $element = '';

    while ($iselement_read == 0)
    {
      # Read a part of a given element with simple processing.
      my $element_part = read_line($fh);

      unless (defined($element_part))
      {
        # Without this message users can obtain incomplete error trace html
        # representation and won't understand what has happend.
        if ($element)
        {
          print_debug_warning("You obtain incomplete error trace representation! End of file was reached but some elements weren't still processed!");
        }

        $iselement_read = -1;
        last;
      }

      # Empty lines are meanigless so just skip them.
      next unless($element_part);

      # Add extra space to separate different parts of a given element from
      # each other. Further it'll help to print pretty expressions.
      $element .= " " if ($element);
      $element .= "$element_part";

      # Detect a given element kind and call a corresponding handler to process it.
      die("Can't find a kind of element '$element'.") unless ($element =~ /$et_element_kind/);
      my $element_kind = $1;
      my $element_content = $POSTMATCH;

      die("The element kind '$element_kind' belongs neither to tree nodes nor to annotations.")
        unless ($element_kind
          or defined($et_element{'tree node'}{$element_kind})
          or defined($et_element{'annotation'}{$element_kind}));

      # When a handler is available for a given error trace element then execute
      # it. If an element is processed successfully then a handler should return
      # some defined value.
      if ($et_element{'tree node'}{$element_kind})
      {
        if (defined(my $element_value = $et_element{'tree node'}{$element_kind}->($element_content)))
        {
          print_debug_trace("Process '$element_kind' tree node");

          # Ignore skips error trace elements that have an empty string value at
          # all.
          if ($element_value)
          {
            $entity = Entity->new({'engine' => $engine, 'kind' => $element_kind, 'values' => $element_value});

            # Some nodes are processed in a special way, so report it.
            print_debug_trace("A tree node kind was changed from '$element_kind' to '" . $entity->{'kind'} . "'")
              if ($entity->{'kind'} ne $element_kind);

            # Process entities as tree.
            $entity->set_parent($parents[$#parents])
              if (@parents);

            if ($entity->ismay_have_children())
            {
              push(@parents, $entity);
              print_debug_trace("Increase the parent stack because of a processed entity may have children");
            }

            if ($entity->isparent_end())
            {
              pop(@parents);
              print_debug_trace("Decrease the parent stack due to a processed entity kind");
            }

            # Add pre annotations.
            $entity->set_pre_annotations(@pre_annotations);
            @pre_annotations = ();
          }
        }
        # Following lines should be read to obtain a full representation of a
        # given element.
        else
        {
          next;
        }
      }
      elsif ($et_element{'annotation'}{$element_kind})
      {
        if (defined(my $element_value = $et_element{'annotation'}{$element_kind}->($element_content)))
        {
          print_debug_trace("Process '$element_kind' annotation");

          # Ignore arificial locations at all.
          if ($element_value)
          {
            # Store dependencies. TODO make it entity specific!!!
            if ($element_kind eq $et_location)
            {
              my ($src, $line) = @{$element_value};
              if(defined($line))
              {
                $dependencies{$src} = 1;
              }
              $files_long_name{$src} = 0;
              $src =~ /([^\/]*)$/;
              $files_short_name{$src} = $1;
              print_debug_trace("A full path to a source code file '$src' was related with the short one '$1'");
            }

            $annotation = Annotation->new({'engine' => $engine, 'kind' => $element_kind, 'values' => $element_value});

            # Process annotation in depend on whether it pre or post.
            push(@pre_annotations, $annotation)
              if ($annotation->ispre_annotation());

            if ($annotation->ispost_annotation())
            {
              $entity->set_post_annotations(($annotation));

              # Update parents since post annotations can change an entity kind.
              if ($entity->isparent_end())
              {
                pop(@parents);
                print_debug_trace("Decrease the parent stack due to post annotations");
              }
            }
          }
        }
        # Following lines should be read to obtain a full representation of a
        # given element. Does it happen whenever for annotations?..
        else
        {
          next;
        }
      }

      # Element was read sucessfully.
      $iselement_read = 1;
    }

    # The whole error trace was read either successfully or not.
    last if ($iselement_read == -1);
  }

  # Return the error trace tree root node and collected auxiliary information.
  return {
      'error trace tree root node' => $parents[0]
    , 'dependencies' => \%dependencies
    , 'files long name' => \%files_long_name
    , 'files short name' => \%files_short_name};
}

sub read_brackets($)
{
  my $line = shift;

  # Check that a specified line begins with the open bracket and finishes with
  # the close bracket. If this isn't the case then additional lines should be
  # read. Most likely the close bracket will be found after all.
  return undef unless ($line =~ /^\(.*\)$/);

  # If the number of open brackets doesn't equal to the number of close brackets
  # then additional lines are needed. This is required since an usual string
  # can end with close bracket although it isn't a read element end.
  # We also need to ensure that brackets inside quotes are ignored! So just
  # remove all strings from a given line before we will count the number of
  # brackets. Also take care of escaped quotes inside stings.
  my $line_without_strings = $line;
  $line_without_strings =~ s/\\"//g;
  $line_without_strings =~ s/"[^"]*"//g;
  my $open_bracket_numb = ($line_without_strings =~ tr/\(//);
  my $close_bracket_numb = ($line_without_strings =~ tr/\)//);
  return undef if ($open_bracket_numb != $close_bracket_numb);

  # Remove brackets surrounding the line.
  $line =~ /^\((.*)\)$/;

  my @content = ($1);

  return \@content;
}

sub read_equal_int($)
{
  my $line = shift;

  # Check that a given line begins with the equality sign and its retained part
  # consists just of integer digits.
  # It should be so if there is no critical error in trace.
  return undef unless ($line =~ /^=(\d+)$/);

  return $1;
}

sub read_equal_src($)
{
  my $line = shift;

  # Check that a line begins with the equality sign and the open double quote
  # and finishes with the close double quote and the semicolon. If it isn't the
  # case then additional lines should be read. Most likely additional lines
  # aren't required for source annotations at all.
  return undef unless ($line =~ /^="(.*)";$/);

  # Remove equality, semicolon and quotes surrounding the line.
  $line = $1;

  # We don't consider the empty string as a correct source code file name.
  return undef unless ($line);

  return $line;
}

sub read_line($)
{
  my $file_report_in = shift;

  # Try to read a next line from a specified error trace file handler.
  return undef unless (defined(my $line = <$file_report_in>));

  # Remove the end of line.
  chomp($line);
  # Remove all formatting spaces and tabs placed at the beginning of the line.
  $line =~ /^[\s]*/;
  $line = $POSTMATCH;

  # Return the processed line.
  return $line;
}

sub read_ldv_comment($)
{
  my $line = shift;

  # Check that a line begins with the colon. It should be so if there is no
  # critical error in trace. Then remove the given colon and all formatting
  # spaces and tabs placed at the beginning of the line.
  return undef unless ($line =~ /^:[\s]*/);
  $line = $POSTMATCH;

  # LDV comments are split by colons.
  my @ldv_comments = split(/:/, $line);

  return \@ldv_comments;
}

sub read_locals($)
{
  my $line = shift;

  # Check that a line begins with the colon. It should be so if there is no
  # critical error in trace. Remove the given colon and all formatting spaces
  # and tabs placed at the beginning of the line.
  return undef unless ($line =~ /^:[\s]*/);
  $line = $POSTMATCH;

  # Function parameters names are split by spaces.
  my @params = split(/\s+/, $line);

  return \@params;
}

sub read_location($)
{
  my $line = shift;

  # Location isn't interesting for visualization. So just ignore it.
  return undef unless ($line =~ /^: id=\d+#\d+/);
  $line = $POSTMATCH;
  $line = $POSTMATCH if ($line =~ /^ \(Artificial\)/);

  # Remove all formatting spaces and tabs placed at the beginning of the line.
  $line =~ /^[\s]*/;
  $line = $POSTMATCH;

  # There may be no source code file and line number (for artificial locations).
  return '' unless ($line);

  # The retained path of the location contains a path to a source code file and
  # a line number.
  my @location = split(/\s+/, $line);

  die("Can't find a path to source code file in location '$location[0]'.")
    unless ($location[0] =~ /$et_element_kind/);
  my $src_content = $POSTMATCH;
  my $src = read_equal_src($src_content);

  if (defined($src))
  {
    $src_prev = $src;
  }
  else
  {
    print_debug_warning("A path to a source code file '$src_content' wasn't processed. So a previosly obtained value '$src_prev' will be used for a given error trace entity");
    $src = $src_prev;
  }

  die("Can't find a line number in location '$location[1]'.")
    unless ($location[1] =~ /$et_element_kind/);
  my $line_numb_content = $POSTMATCH;
  my $line_numb = read_equal_int($line_numb_content);

  if (defined($line_numb))
  {
    $line_prev = $line_numb;
  }
  else
  {
    print_debug_warning("A line number '$line_numb_content' wasn't processed. So a previosly obtained value '$line_prev' will be used for a given error trace entity");
    $line_numb = $line_prev;
  }

  @location = ($src, $line_numb);

  return \@location;
}

1;
