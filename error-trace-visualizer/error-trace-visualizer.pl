#! /usr/bin/perl -w


use English;
use Env qw(LDV_DEBUG LDV_ERROR_TRACE_VISUALIZER_DEBUG);
use FindBin;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../shared/perl", "$FindBin::RealBin/../shared/perl/error-trace-visualizer");

# Add some nonstandard local Perl packages.
use LDV::Utils;
require Entity;
require Annotation;


################################################################################
# Subroutine prototypes.
################################################################################

# Add spaces around some operators to make output more nice.
# args: some string.
# retn: this string with formatted operators.
sub add_mising_spaces($);

# Check wether the given engine is supported.
# args: no.
# retn: nothing.
sub check_engine();

# Determine the debug level in depend on the environment variable value.
# args: no.
# retn: nothing.
sub get_debug_level();

# Process command-line options. To see detailed description of these options 
# run script with --help option.
# args: no.
# retn: nothing.
sub get_opt();

# Print help message on the screen and exit.
# args: no.
# retn: nothing.
sub help();

# Debug functions. They print some information in depend on the debug level.
# args: string to be printed.
# retn: nothing.
sub print_debug_normal($);
sub print_debug_info($);
sub print_debug_debug($);
sub print_debug_trace($);
sub print_debug_all($);

# Pretty print an error trace.
# args: the tree root node.
# retn: nothing.
sub print_error_trace($);

# Pretty print a blast error trace.
# args: the tree root node.
# retn: nothing.
sub print_error_trace_blast($);

# Pretty print a blast error trace node with all its children and corresponding indent.
# args: the tree root node and space indent.
# retn: nothing.
sub print_error_trace_node_blast($$);

# Print the required number of spaces.
# args: the number of spaces.
# retn: nothing.
sub print_spaces($);

# Process an error trace passed through options.
# args: no.
# retn: nothing.
sub process_error_trace();

# Process a blast error trace.
# args: no.
# retn: the tree root node.
sub process_error_trace_blast();

# Read something placed into brackets.
# args: some string.
# retn: the content of brackets or undef if it can't be read.
sub read_brackets($);

# Read equality and integer number (line number in source).
# args: some string.
# retn: the corresponding integer line number or undef if it can't be read.
sub read_equal_int($);

# Read equality and path to source file.
# args: some string.
# retn: the corresponding source file path or undef if it can't be read.
sub read_equal_src($);

# Read ldv comment.
# args: some string.
# retn: the processed ldv comment or undef if it can't be read.
sub read_ldv_comment($);

# Read the next line and process it a bit.
# args: no.
# retn: a processed line or undef when no lines is rest.
sub read_line();

# Read locals (function parameter names).
# args: some string.
# retn: the processed names or undef if it can't be read.
sub read_locals($);

# Read location. Location includes an useless location, a path to the source 
# file and a line number.
# args: some string.
# retn: the processed path to file and line number or undef if it can't be read.
sub read_location($);


################################################################################
# Global variables.
################################################################################

# Blast error trace tree nodes, annotations and their processing functions:
#   tree node
#     Block
#     FunctionCall
#     Pred
#     Skip
#   annotation
#     LDV
#     Location
#     Locals
my %blast = (
  'tree node' => {
    my $element_kind_block = 'Block', \&read_brackets,
    my $element_kind_func_call = 'FunctionCall', \&read_brackets,
    my $element_kind_cond = 'Pred', \&read_brackets,
    my $element_kind_skip = 'Skip', ''
  },
  'annotation' => {
    my $element_kind_ldv_comment = 'LDV', \&read_ldv_comment,
    my $element_kind_params = 'Locals', \&read_locals,
    my $element_kind_location = 'Location', \&read_location
  });

# Prefix for all debug messages.
my $debug_name = 'error-trace-visualizer';

# Hash that keeps all dependencies required by the given error trace. Keys are
# pathes to corresponding dependencies files.
my %dependencies;

# Engines which reports can be processed are keys and values are 
# corresponding processing subroutines.
my %engines = (my $engine_blast = 'blast' => 
                 {'print', \&print_error_trace_blast, 
                  'process', \&process_error_trace_blast});

# File handlers.
my $file_report_in;
my $file_report_out;
my $file_reqs_out;

# The unique html tags identifier.
my $html_id = 0;

# Command-line options. Use --help option to see detailed description of them.
my $opt_engine;
my $opt_help;
my $opt_report_in;
my $opt_report_out;
my $opt_reqs_out;

# Some usefull reqular expressions.
my $regexp_element_kind = '^([^=\(:]+)';

# The number of indentation spaces.
my $space_indent = 2;


################################################################################
# Main section.
################################################################################

# Obtain the debug level.
get_debug_level();

print_debug_normal("Process the command-line options.");
get_opt();

print_debug_normal("Process trace.");
my $tree_root = process_error_trace();

if ($opt_report_out)
{
  print_error_trace($tree_root);	
}

# TODO this must be fixed!!!!!!
if ($opt_reqs_out)
{
      if ($opt_engine eq $engine_blast)
         { 
  foreach my $dep (keys(%dependencies))
  {
    print($file_reqs_out "$dep\n") unless ($dep =~ /\.i$/);
  }
         }
}

print_debug_trace("Close file handlers.");
close($file_report_in) 
  or die("Can't close the file '$opt_report_in': $ERRNO\n");
if ($opt_report_out)
{
  close($file_report_out) 
    or die("Can't close the file '$opt_report_out': $ERRNO\n");
}
if ($opt_reqs_out)
{
  close($file_reqs_out) 
    or die("Can't close the file '$opt_reqs_out': $ERRNO\n");
}
  
print_debug_normal("Make all successfully.");


################################################################################
# Subroutines.
################################################################################

sub add_mising_spaces($)
{
  my $str = shift;

  # Add mising spaces around equality sign.
  $str =~ s/([^ ])=/$1 =/g;  	
  $str =~ s/=([^ ])/= $1/g;
  
  return $str;
}

sub get_debug_level()
{
  LDV::Utils::push_instrument($debug_name);

  # By default (in case when neither LDV_DEBUG nor 
  # LDV_ERROR_TRACE_VISUALIZER_DEBUG environment variables aren't specified) or 
  # when LDV_DEBUG and LDV_ERROR_TRACE_VISUALIZER_DEBUG are 0 just information 
  # on errors is printed. 
  # Otherwise:  
  if (defined($LDV_ERROR_TRACE_VISUALIZER_DEBUG))
  {
    LDV::Utils::set_verbosity($LDV_ERROR_TRACE_VISUALIZER_DEBUG);
    print_debug_debug("The debug level is set correspondingly to the LDV_ERROR_TRACE_VISUALIZER_DEBUG environment variable value '$LDV_ERROR_TRACE_VISUALIZER_DEBUG'.");
  }
  elsif (defined($LDV_DEBUG))
  {
    LDV::Utils::set_verbosity($LDV_DEBUG);
    print_debug_debug("The debug level is set correspondingly to the LDV_DEBUG environment variable value '$LDV_DEBUG'.");
  }
}

sub get_opt()
{
  if (scalar(@ARGV) == 0)
  {
    warn("No options were specified through the command-line. Please see help to understand how to use this tool");
    help();
  }
  print_debug_trace("The options '@ARGV' were passed to the instrument through the command-line.");

  unless (GetOptions(
    'engine=s' => \$opt_engine,
    'help|h' => \$opt_help,
    'report|c=s' => \$opt_report_in,
    'report-out|o=s' => \$opt_report_out,
    'reqs-out=s' => \$opt_reqs_out))
  {
    warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
    help();
  }

  help() if ($opt_help);
  
  unless ($opt_engine and $opt_report_in) 
  {
    warn("You must specify the options --engine, --report|c in the command-line");
    help();
  }

  unless (defined($engines{$opt_engine}))
  {
    warn("The specified static verifier engine '$opt_engine' isn't supported. Please use one of the following engines: \n");
    foreach my $engine (keys(%engines))
    {
      warn("  - '$engine'\n");
	}
	die();
  }

  unless ($opt_report_out or $opt_reqs_out)
  {
    warn("You must specify either the option --report-out|o or --reqs-out in the command-line");
    help();    
  }

  if ($opt_report_out)
  {
    open($file_report_out, '>', "$opt_report_out")
      or die("Can't open the file '$opt_report_out' specified through the option --report-out|o for write: $ERRNO");
    print_debug_debug("The report output file is '$opt_report_out'.");
  }
  
  if ($opt_reqs_out)
  {
    open($file_reqs_out, '>', "$opt_reqs_out")
      or die("Can't open the file '$opt_reqs_out' specified through the option --reqs-out for write: $ERRNO");
    print_debug_debug("The requrements output file is '$opt_reqs_out'.");
  }
  
  open($file_report_in, '<', "$opt_report_in")
    or die("Can't open the file '$opt_report_in' specified through the option --report-in|c for read: $ERRNO");
  print_debug_debug("The report input file is '$opt_report_in'.");
  
  print_debug_debug("The command-line options are processed successfully.");
}

sub help()
{
    print(STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to visualize error traces 
    obtained from different static verifiers.

SYNOPSIS
  $PROGRAM_NAME [option...]

OPTIONS

  --engine <id>
    <id> is an engine identifier (like 'blast' and so on).

  -h, --help
    Print this help and exit with a error.

  -c, --report <file>
    <file> is an absolute path to a file containing error trace.

  -o, --report-out <file>
    <file> is an absolute path to a file that will contain error trace
    processed by the tool. This is needed in the visualization mode.

  --reqs-out <file>
    <file> is an absolute path to a file that will contain a list of
    required for report files. This is needed to gather all 
    requirements that will be used then in the visualization mode.
    
ENVIRONMENT VARIABLES

  LDV_DEBUG
    It's an optional environment variable that specifies a debug 
    level. It uses the standard designatures to distinguish different
    debug information printings. Each next level includes all previous
    levels and its own messages.
    
  LDV_ERROR_TRACE_VISUALIZER_DEBUG 
    Like LDV_DEBUG but it has more priority. It specifies a debug 
    level just for this instrument.

EOM

  exit(1);
}

sub print_debug_normal($)
{
  my $message = shift;
  
  vsay('NORMAL', "$message\n");
}

sub print_debug_info($)
{
  my $message = shift;
  
  vsay('INFO', "$message\n");
}

sub print_debug_debug($)
{
  my $message = shift;
  
  vsay('DEBUG', "$message\n");
}

sub print_debug_trace($)
{
  my $message = shift;
  
  vsay('TRACE', "$message\n");
}

sub print_debug_all($)
{
  my $message = shift;
  
  vsay('ALL', "$message\n");
}

sub print_error_trace($)
{
  my $tree_root = shift;
  	
  print_debug_debug("Print the '$opt_engine' static verifier error trace.");
  $engines{$opt_engine}{'print'}->($tree_root);  
  print_debug_debug("'$opt_engine' static verifier error trace is printed successfully.");
}

sub print_error_trace_blast($)
{
  my $tree_root = shift;
  	
  # Print tree recursively.	
  print_error_trace_node_blast($tree_root, 0);
}

sub print_error_trace_node_blast($$)
{
  my $tree_node = shift;
  my $indent = shift;
  
  print_debug_trace("Print the '$tree_node->{'kind'}' tree node.");

  # Process tree node values a bit.
  if (${$tree_node->{'values'}}[0])
  {
    # Remove names scope for all tree nodes.
    ${$tree_node->{'values'}}[0] =~ s/@[_a-zA-Z0-9]+//g;
    # Add spaces around some operators.
    ${$tree_node->{'values'}}[0] = add_mising_spaces(${$tree_node->{'values'}}[0]);
  }
  
  # Get source and line if so.
  my $src = '';
  my $line = '';
  if ($tree_node->{'pre annotations'})
  {
	foreach my $pre_annotation (@{$tree_node->{'pre annotations'}})
	{
	  if ($pre_annotation->{'kind'} eq 'Location')
	  {
		$src = $pre_annotation->{'values'}[0];
	    $line = $pre_annotation->{'values'}[1];  
	  }
	}
  }
  
  # Print tree node declaration.
  if ($tree_node->{'kind'} eq 'Root')
  {
    print($file_report_out "\n<div class='ETVEntryPoint' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print($file_report_out "entry_point()", ";</div>");
    print($file_report_out "\n<div class='ETVEntryPointBody' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print($file_report_out "{");    
  }
  elsif ($tree_node->{'kind'} eq 'FunctionCall')
  {
    print($file_report_out "\n<div class='ETVFunctionCall' title='$src:$line' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print($file_report_out ${$tree_node->{'values'}}[0], ";</div>");
    print($file_report_out "\n<div class='ETVFunctionBody' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print($file_report_out "{");    
  }
  elsif ($tree_node->{'kind'} eq 'FunctionCallWithoutBody')
  {
    print($file_report_out "\n<div class='ETVFunctionCallWithoutBody' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print($file_report_out ${$tree_node->{'values'}}[0], "  { /* The function body is undefined. */ };</div>");
  }
  elsif ($tree_node->{'kind'} eq 'Block')
  {
	# Split expressions joined together into one block.
	my @exprs = split(/;/, ${$tree_node->{'values'}}[0]);
	print($file_report_out "\n<div class='ETVBlock' title='$src:$line' id='ETV", ($html_id++), "'>");
	
	foreach my $expr (@exprs)
	{	
	  print_spaces($indent);
	  print($file_report_out $expr, ";<br>");
    }
    
    print($file_report_out "</div>");	 
  }
  elsif ($tree_node->{'kind'} eq 'Return')
  {
    print($file_report_out "\n<div class='ETVReturn' title='$src:$line' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print($file_report_out "return ", "<span class='ETVReturnValue'>", ${$tree_node->{'values'}}[0], "</span>;</div>");    
  }
  elsif ($tree_node->{'kind'} eq 'Pred')
  {
    print($file_report_out "\n<div class='ETVAssert' title='$src:$line' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print($file_report_out "assert(", "<span class='ETVAssertCondition'>", ${$tree_node->{'values'}}[0], "</span>);</div>");    
  }
      
  # Print all tree node children with enlarged indentation.
  if ($tree_node->{'children'})
  {
    foreach my $child (@{$tree_node->{'children'}})
    {
	  print_error_trace_node_blast($child, ($indent + $space_indent));
	}
  }
  
  # Print the close brace after the body of root and function calls nodes.
  if ($tree_node->{'kind'} eq 'Root' 
    or $tree_node->{'kind'} eq 'FunctionCall')
  {
    print_spaces($indent);
    print($file_report_out "}</div>");
  }
}

sub print_spaces($)
{
  my $space_number = shift;
  
  # Print identation spaces.
  print($file_report_out "<span class='ETVIdentation'>");
  
  for (my $i = 1; $i <= $space_number; $i++)
  {
	print($file_report_out ' ');
  }
  
  print($file_report_out "</span>");
}

sub process_error_trace()
{
  print_debug_debug("Process the '$opt_engine' static verifier error trace.");
  my $tree_root = $engines{$opt_engine}{'process'}->();  
  print_debug_debug("'$opt_engine' static verifier error trace is processed successfully.");
  
  return $tree_root;
}

sub process_error_trace_blast()
{
  # The list of current parents.	
  my @parents = ();	

  # Currently processed entity and annotation.
  my $entity;
  my $annotation;
  
  # Stored pre annotations.
  my @pre_annotations = ();
	
  # Create the tree root corresponding to the entry point or main.
  $entity = Entity->new({'engine' => 'blast', 'kind' => 'Root'});	
  push(@parents, $entity);
				
  while(1)
  {
    # Read some element, either tree node (like function call) or annotation
    # (like source code file path). Note that some elements may be divided into
    # several lines so process all needed lines. Finish when there is no more
    # lines.
    my $iselement_read = 0;
    my $element = '';
    while ($iselement_read == 0)
    {
      my $element_part = read_line();
        
      unless (defined($element_part))
      {
        $iselement_read = -1;
        last;
      }
      
      # Empty lines are meanigless.
      next unless($element_part);
      
      $element .= $element_part;
      
      # Detect the element kind and call the corresponding handler to read it.
      die("Can't find the element '$element' kind.") unless ($element =~ /$regexp_element_kind/);
      my $element_kind = $1;
      my $element_content = $POSTMATCH;

      die("The element kind '$element_kind' belongs neither to tree nodes nor to annotations.") 
        unless ($element_kind 
          or defined($blast{'tree node'}{$element_kind}) 
          or defined($blast{'annotation'}{$element_kind}));  

      # When handler is available then run it. If an element is processed 
      # successfully then a handler returns some defined value.  
      if ($blast{'tree node'}{$element_kind})
      {
        if (defined(my $element_value = $blast{'tree node'}{$element_kind}->($element_content)))
        {
		  print_debug_trace("Process the '$element_kind' tree node.");
		  	
		  # Ignore skips at all.	
		  if ($element_value)
		  {
			$entity = Entity->new({'engine' => 'blast', 'kind' => $element_kind, 'values' => $element_value});

			# Process entities as tree.
    		$entity->set_parent($parents[$#parents])
    		  if (@parents);
			push(@parents, $entity) 
			  if ($entity->ismay_have_children());
			pop(@parents)
			  if ($entity->isparent_end());
	  
    		# Add pre annotations.
    		$entity->set_pre_annotations(@pre_annotations);
    		@pre_annotations = ();  
		  }
        }
        # The following line is needed. So read it and concatenate with the 
        # previous one(s).
        else
        {
          next;
        }          
      }
      elsif ($blast{'annotation'}{$element_kind})
      {
        if (defined(my $element_value = $blast{'annotation'}{$element_kind}->($element_content)))
        {
		  print_debug_trace("Process the '$element_kind' annotation.");
		  
          # Ignore arificial locations at all.  
          if ($element_value) 
          {
            # Story dependencies. TODO make it entity specific!!!!!!!!!!!!!!!!!!!!!!!
            if ($element_kind eq $element_kind_location)
            {
              my ($src, $line) = @{$element_value};
              $dependencies{$src} = 1;
            }
            
			$annotation = Annotation->new({'engine' => 'blast', 'kind' => $element_kind, 'values' => $element_value});

            # Process annotation in depend on whether it pre or post.
            push(@pre_annotations, $annotation)
              if ($annotation->ispre_annotation());
            if ($annotation->ispost_annotation())
            {
              $entity->set_post_annotations(($annotation));
              
              # Update parents since post annotation may change the entity kind.
              pop(@parents)
			    if ($entity->isparent_end());  
			}
          }
        }
        # The following line is needed. So read it and concatenate with the 
        # previous one(s). Does it happen whenever for annotations?
        else
        {
          next;
        }          
      }
      
      # Element was read sucessfully.
      $iselement_read = 1;
    }
    
    # All was read.
    last if ($iselement_read == -1);
  }
  
  # Return the tree root node.
  return $parents[0];
}

sub read_brackets($)
{
  my $line = shift;
  
  # Check that line begins with open bracket. It'll be so if there is no 
  # critical error in trace.
  return undef unless ($line =~ /^\(/);
  
  # Check that line finishes with close bracket. If it's not so then additional
  # line must be read. It seems that every time close bracket will be found
  # after all.
  return undef unless ($line =~ /\)$/);
  
  # Check the balance of open and close brackets. If it isn't correct
  # then additional strings are needed.
  my $open_bracket_numb = ($line =~ tr/\(//);
  my $close_bracket_numb = ($line =~ tr/\)//);
  return undef if ($open_bracket_numb != $close_bracket_numb);
  
  # Remove brackets surrounding the line.
  $line =~ /^\(/;
  $line = $POSTMATCH;
  $line =~ /\)$/;
  $line = $PREMATCH;
  
  my @content = ($line);
  
  return \@content;
}

sub read_equal_int($)
{
  my $line = shift;
  
  # Check that line begins with equality and consists just of integer digits. 
  # It'll be so if there is no critical error in trace.
  return undef unless ($line =~ /^=\d+$/);

  # Remove equality beginning the line.
  $line =~ /^=/;
  $line = $POSTMATCH;
  
  return $line;
}

sub read_equal_src($)
{
  my $line = shift;
  
  # Check that line begins with equality and open double quote. It'll be so if 
  # there is no critical error in trace.
  return undef unless ($line =~ /^="/);

  # Check that line finishes with close quote and semicolon. If it's not so then 
  # additional line must be read. It seems that every time close bracket will be 
  # found after all. And it seems that it isn't actual for the source annotation 
  # at all.
  return undef unless ($line =~ /";$/);
  
  # Remove equality, semicolon and quotes surrounding the line.
  $line =~ /^="/;
  $line = $POSTMATCH;
  $line =~ /";$/;
  $line = $PREMATCH;
  
  return $line;
}

sub read_ldv_comment($)
{
  my $line = shift;
  
  # Check that line begins with colon. It'll be so if there is no critical error 
  # in trace.
  return undef unless ($line =~ /^:/);

  # Remove colon beginning the line and all formatting spaces and tabs placed at the beginning of the line.
  $line =~ /^:[\s]*/;
  $line = $POSTMATCH;

  # LDV comments are splited by colons.
  my @comments = split(/:/, $line);

  return \@comments;
}

sub read_line()
{
  # Read the next line from the input report file if so.
  return undef unless (defined(my $line = <$file_report_in>));
  
  # Remove the end of line.
  chomp($line);
  # Remove all formatting spaces and tabs placed at the beginning of the line.
  $line =~ /^[\s]*/;
  $line = $POSTMATCH;

  # Return the processed line.
  return $line;
}

sub read_locals($)
{
  my $line = shift;

  # Check that line begins with colon. It'll be so if there is no critical error 
  # in trace.
  return undef unless ($line =~ /^:/);

  # Remove colon beginning the line and all formatting spaces and tabs placed at the beginning of the line.
  $line =~ /^:[\s]*/;
  $line = $POSTMATCH;

  # Function parameters names are splited by spaces.
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
   
  # There may be no source file and line number (for artificial locations).
  return '' unless ($line);
  
  # The rest path of location contains path to the source file and line number.     
  my @location = split(/\s+/, $line);
  
  die("Can't find a source path in the '$location[0]'.") 
    unless ($location[0] =~ /$regexp_element_kind/);
  my $src_content = $POSTMATCH;       
  my $src = read_equal_src($src_content);
  
  die("Can't find a line number in the $line '$location[1]'.") 
    unless ($location[1] =~ /$regexp_element_kind/);
  my $line_numb_content = $POSTMATCH;       
  my $line_numb = read_equal_int($line_numb_content);

  @location = ($src, $line_numb);

  return \@location;
}
