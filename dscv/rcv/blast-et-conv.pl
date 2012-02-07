#! /usr/bin/perl -w


use English;
use Env qw(LDV_DEBUG LDV_BLAST_ET_CONV_DEBUG);
use FindBin;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../../shared/perl");

# Add some nonstandard local Perl packages.
use DSCV::RCV::Entity;
use DSCV::RCV::Annotation;
use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info
  print_debug_debug print_debug_trace print_debug_all get_debug_level);


################################################################################
# Subroutine prototypes.
################################################################################

# Convert a parsed error trace to the common format.
# args: reference to a parsing result hash (root node of a tree, dependencies,
#       etc.).
# retn: reference to array of common error trace lines.
sub convert_error_trace_to_common($);

# Convert a given tree node from internal representation to the common format.
# args: tree node.
# retn: reference to array of common error trace lines.
sub convert_tree_node_to_common($);

# Process command-line options. To see detailed description of these options
# run script with --help option.
# args: no.
# retn: nothing.
sub get_opt();

# Print help message on the screen and exit.
# args: no.
# retn: nothing.
sub help();

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

# Read a next line from a specified error trace and process it a bit.
# args: a reference to array of strings representing a given error trace and an
#       index in this array.
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
# args: reference to array of error trace lines.
# retn: reference to a result hash (root node of a tree, dependencies, etc.).
sub parse_error_trace($);


################################################################################
# Global variables.
################################################################################

# Prefix for all debug messages.
my $debug_name = 'blast-et-conv';

# Specify that this converter is for BLAST static verifier.
my $engine = 'blast';

# BLAST error trace tree nodes, annotations and their processing functions:
#   tree node
#     Block
#     FunctionCall
#     Pred
#     Skip
#   annotation
#     LDV
#     Location
#     Locals
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

# Reqular expression to extract a BLAST error trace element kind.
my $et_element_kind = '^([^=\(:]+)';

# A previously processed path to a source code file and a line number. They are
# needed in cases when a current entity location can't be processed
# successfully.
my $src_prev;
my $line_prev;

# Specifies a current context. In fact it's required just to determine where an
# entry point starts, because of there is no explicit entry point in BLAST.
my $context = 'entry';


################################################################################
# Main section.
################################################################################

# Obtain the debug level.
get_debug_level($debug_name, $LDV_DEBUG, $LDV_BLAST_ET_CONV_DEBUG);

print_debug_debug("Process the command-line options");
my $opts = get_opt();
my $fh_in = $opts->{'fh in'};
my @et = <$fh_in>;
print_debug_info("Begin to parse error trace specified");
my $et_parsed = parse_error_trace(\@et);
print_debug_debug("Error trace was parsed successfully");
print_debug_info("Begin to convert error trace to the common format");
my $et_conv = convert_error_trace_to_common($et_parsed);
print_debug_debug("Error trace was converted to the common format successfully");
my $str = join("\n", @{$et_conv});
print_debug_info("Print common error trace");
print({$opts->{'fh out'}} "Error trace common format v0.1\n");
print({$opts->{'fh out'}} $str);
print_debug_debug("Common error trace was printed successfully");


################################################################################
# Subroutines.
################################################################################

sub convert_error_trace_to_common($)
{
  my $et_parsed = shift;

  my $et_root = $et_parsed->{'error trace tree root node'};

  $src_prev = '';
  return convert_tree_node_to_common($et_root);
}

sub convert_tree_node_to_common($)
{
  my $node = shift;

  my $node_common = '';

  # Obtain source and line if so.
  my $src;
  my $line;
  if ($node->{'pre annotations'})
  {
    foreach my $pre (@{$node->{'pre annotations'}})
    {
      if ($pre->{'kind'} eq 'Location')
      {
        $src = $pre->{'values'}[0];
        $line = $pre->{'values'}[1];
      }
    }
  }

  $node_common .= "$line " if ($line);
  if ($src and (!$src_prev or $src ne $src_prev))
  {
    $node_common .= "\"$src\" ";
    $src_prev = $src;
  }

  # Obtain formal parameter names or/and LDV comments if so.
  my @names = ();
  my $ldv_comment1 = '';
  my $ldv_comment2 = '';
  if ($node->{'post annotations'})
  {
    foreach my $post (@{$node->{'post annotations'}})
    {
      if ($post->{'kind'} eq 'Locals')
      {
        foreach my $name (@{$post->{'values'}})
        {
          # Remove parameter name scope.
          $name =~ s/@\w+//g;
          push(@names, $name);
        }
      }
      elsif ($post->{'kind'} eq 'LDV')
      {
        $ldv_comment1 = ${$post->{'values'}}[0];
        $ldv_comment2 = ${$post->{'values'}}[1];
      }
    }
  }

  # Make node specific transformation.
  if ($node->{'kind'} eq 'FunctionCall')
  {
    $node_common .= "CALL ";

    # Add information on formal parameter names.
    if (scalar(@names))
    {
      my @quoted_names = map({"'$ARG'"} @names);
      $node_common .= "@quoted_names";
    }
  }
  elsif ($node->{'kind'} eq 'Return')
  {
    $node_common .= "RETURN ";
    # Leave a current initialization section.
    $context = 'entry' if ($context eq 'init');
  }
  elsif ($node->{'kind'} eq 'Block')
  {
    $node_common .= "BLOCK ";
  }
  elsif ($node->{'kind'} eq 'Pred')
  {
    $node_common .= "ASSUME ";
  }
  elsif ($node->{'kind'} eq 'FunctionCallInitialization')
  {
    $node_common .= "CALL INIT ";
    $context = 'init';
  }
  elsif ($node->{'kind'} eq 'FunctionCallWithoutBody')
  {
    $node_common .= "CALL SKIP(\"Function call is skipped due to function is undefined\") ";
  }
  elsif ($node->{'kind'} eq 'FunctionStackOverflow')
  {
    my $fdepth = $node->{'fdepth'};
    $node_common .= "CALL SKIP(\"Function call is skipped to reduce verification time in accordance with '-fdepth $fdepth' option\") ";
  }
  elsif ($node->{'kind'} eq 'Root')
  {
    # Tree root node is artificial, it's intended just to keep first-level children.
  }

  # Understand if we are at the entry point now. There may be just one entry
  # point for a given error trace, so, leave context if entry point is found.
  my $entry_point = '';
  if ($node->{'kind'} ne 'Root' and $node->{'kind'} ne 'Return' and $context eq 'entry')
  {
    $entry_point = 'CALL ENTRY';
    $context = '';
  }

  if (my $val = ${$node->{'values'}}[0])
  {
    # Remove entities scope.
    $val =~ s/@\w+//g;

    # Replace ' +' with ' ', ' )' with ')' and '* (' with '*('.
    $val =~ s/ +/ /g;
    # TODO is this required?
    $val =~ s/ \)/\)/g;
    $val =~ s/\* \(/\*\(/g;

    $node_common .= ": $val";
  }

  # Obtain common representation for all children.
  my @children_common = ();
  if ($node->{'children'})
  {
    foreach my $child (@{$node->{'children'}})
    {
      my $child_common = convert_tree_node_to_common($child);
      push (@children_common, @{$child_common});
    }
  }

  # Add common representation of the node processed to the beginning of its
  # children common representation list.
  unshift(@children_common, $node_common);

  # Add information on entry point if so.
  unshift(@children_common, $entry_point) if ($entry_point);

  return \@children_common;
}

sub get_opt()
{
  if (scalar(@ARGV) == 0)
  {
    warn("No options were specified through the command-line. Please see help to understand how to use this tool");
    help();
  }
  print_debug_trace("The options '@ARGV' were passed to the instrument through the command-line");

  my ($help, $in, $out);

  unless (GetOptions(
    'help|h' => \$help,
    'report|c=s' => \$in,
    'report-out|o=s' => \$out))
  {
    warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool");
    help();
  }

  help() if ($help);

  unless ($in)
  {
    warn("You must specify the option --report|c in the command-line");
    help();
  }

  my $fh_in;
  open($fh_in, '<', "$in")
    or die("Can't open the file '$in' specified through the option --report-in|c for read: $ERRNO");
  print_debug_debug("The report input file is '$in'");

  unless ($out)
  {
    warn("You must specify the option --report-out|o in the command-line");
    help();
  }

  my $fh_out;
  open($fh_out, '>', "$out")
    or die("Can't open the file '$out' specified through the option --report-out|o for write: $ERRNO");
  print_debug_debug("The report output file is '$out'");

  print_debug_debug("The command-line options are processed successfully");

  return {'fh in' => $fh_in, 'fh out' => $fh_out};
}

sub help()
{
    print(STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to convert BLAST error traces
    to the common format.

SYNOPSIS
  $PROGRAM_NAME [option...]

OPTIONS

  -h, --help
    Print this help and exit with a error.

  -c, --report <file>
    <file> is an absolute path to a file containing error trace.

  -o, --report-out <file>
    <file> is an absolute path to a file that will contain error trace
    processed by the tool. This is needed in the visualization mode.
ENVIRONMENT VARIABLES

  LDV_DEBUG
    It's an optional environment variable that specifies a debug
    level. It uses the standard designatures to distinguish different
    debug information printings. Each next level includes all previous
    levels and its own messages.

  LDV_BLAST_ET_CONV_DEBUG
    Like LDV_DEBUG but it has more priority. It specifies a debug
    level just for this instrument.

EOM

  exit(1);
}

sub parse_error_trace($)
{
  my $et = shift;

  my $et_pos = {'error trace' => $et, 'line number' => 0};

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
  $entity = DSCV::RCV::Entity->new({'engine' => $engine, 'kind' => $et_root});
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
      my $element_part = read_line($et_pos);

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

      # Increase a line number into a specified error trace after successfull
      # reading.
      $et_pos->{'line number'}++;

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
            $entity = DSCV::RCV::Entity->new({'engine' => $engine, 'kind' => $element_kind, 'values' => $element_value});

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

            $annotation = DSCV::RCV::Annotation->new({'engine' => $engine, 'kind' => $element_kind, 'values' => $element_value});

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
  my $et_pos = shift;

  # Try to read a next line.
  return undef unless (defined(my $line = ${$et_pos->{'error trace'}}[$et_pos->{'line number'}]));

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
