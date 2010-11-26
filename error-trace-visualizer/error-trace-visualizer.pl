#! /usr/bin/perl -w


use English;
use Env qw(LDV_DEBUG LDV_ERROR_TRACE_VISUALIZER_DEBUG);
use FindBin;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../shared/perl", "$FindBin::RealBin/../shared/perl/error-trace-visualizer");

use Text::Highlight;

# Add some nonstandard local Perl packages.
use LDV::Utils;
require Entity;
require Annotation;
require CPAchecker;
use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info
  print_debug_debug print_debug_trace print_debug_all get_debug_level);


################################################################################
# Subroutine prototypes.
################################################################################

# Add spaces around some operators to make output more nice.
# args: some string.
# retn: this string with formatted operators.
sub add_mising_spaces($);

# Replace some characters from file path to make link from it.
# args: a file path.
# retn: link corresponding to the given file path.
sub convert_file_to_link($);

# Process command-line options. To see detailed description of these options
# run script with --help option.
# args: no.
# retn: nothing.
sub get_opt();

# Print help message on the screen and exit.
# args: no.
# retn: nothing.
sub help();

# Pretty print an error trace.
# args: the tree root node.
# retn: nothing.
sub print_error_trace($);

# Pretty print a blast error trace.
# args: the tree root node.
# retn: nothing.
sub print_error_trace_blast($);

# Pretty print a cpachecker error trace.
# args: the tree root node.
# retn: nothing.
sub print_error_trace_cpachecker($);

# Pretty print an unknown engine error trace.
# args: the error trace.
# retn: nothing.
sub print_error_trace_unknown($);

# Pretty print a blast error trace node with all its children and corresponding indent.
# args: the tree root node and space indent.
# retn: nothing.
sub print_error_trace_node_blast($$);

# Add entities global show/hide links.
# args: (the entitity class; the human readable entity class).
# retn: nothing.
sub print_show_hide_global($$);

# Add entities local show/hide links.
# args: (the entitity identifier).
# retn: nothing.
sub print_show_hide_local($);

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

# Process a cpachecker error trace.
# args: no.
# retn: the tree root node.
sub process_error_trace_cpachecker();

# Process an unknown error trace.
# args: no.
# retn: the error trace formatted a bit.
sub process_error_trace_unknown();

# Process a file containing all source code files and separate them.
# args: no.
# retn: nothing.
sub process_source_code_files();

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

# Read the next line and possibly process it a bit.
# args: a flag that says whether a processing is needed.
# retn: a processed line or undef when no lines is rest.
sub read_line($);

# Read locals (function parameter names).
# args: some string.
# retn: the processed names or undef if it can't be read.
sub read_locals($);

# Read location. Location includes an useless location, a path to the source
# file and a line number.
# args: some string.
# retn: the processed path to file and line number or undef if it can't be read.
sub read_location($);

# Make needed visualization of the error trace.
# args: the tree root node.
# retn: nothing.
sub visualize_error_trace($);


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
our %dependencies;

# Engine to be used during processing and printing of an error trace.
my $engine = '';

# Engines which reports can be processed are keys and values are
# corresponding processing subroutines.
my %engines = (my $engine_blast = 'blast' =>
                 {'print', \&print_error_trace_blast,
                  'process', \&process_error_trace_blast}
               , my $engine_cpachecker = 'cpachecker' =>
                 {'print', \&print_error_trace_cpachecker,
                  'process', \&process_error_trace_cpachecker}
               , my $engine_unknown = 'unknown' =>
                 {'print', \&print_error_trace_unknown,
                  'process', \&process_error_trace_unknown});

# These variables contain a current line number and a current source code file
# if so or 0 and '' otherwise.
my $entity_line = 0;
my $entity_src = '';

# File handlers.
my $file_report_in;
my $file_report_out;
my $file_reqs_out;
my $file_src_files;

# From trace we obtain the full name (absolute pathes). From database we obtain
# corresponding long names with deleted prefix. But we show just short names
# consisting just of file name in titles and tab names.
my %files_long_name;
my %files_short_name;

# The unique html tags identifier.
my $html_id = 0;

# LDV driver environment comments collected from source code. Keys are file
# names and line numbers, values are comments with the corresponding short alias
# names.
my %ldv_driver_env_comments;
# The LDV driver environment comments aliases and names.
my %ldv_driver_env_comment_names = (
    'entry point beginning' => 'LDV_COMMENT_BEGIN_MAIN'
  , 'entry point end' => 'LDV_COMMENT_END_MAIN'
  , my $ldv_driver_env_comment_func_call = 'function call' => 'LDV_COMMENT_FUNCTION_CALL'
  , my $ldv_driver_env_comment_var_init = 'variable initialization' => 'LDV_COMMENT_VAR_INIT');

# LDV model comments collected from source code. Keys are file names and line
# numbers, values are comments with the corresponding short alias names.
my %ldv_model_comments;
# The LDV model comments aliases and names.
my %ldv_model_comment_names = (
    my $ldv_model_comment_assert = 'assert' => 'LDV_COMMENT_ASSERT'
  , my $ldv_model_comment_change_state = 'state changing' => 'LDV_COMMENT_CHANGE_STATE'
  , my $ldv_model_comment_func_def = 'function definition' => 'LDV_COMMENT_MODEL_FUNCTION_DEFINITION'
  , my $ldv_model_comment_func_call = 'function call' => 'LDV_COMMENT_MODEL_FUNCTION_CALL'
  , 'state' => 'LDV_COMMENT_MODEL_STATE'
  , my $ldv_model_comment_other = 'other' => 'LDV_COMMENT_OTHER'
  , my $ldv_model_comment_return = 'return' => 'LDV_COMMENT_RETURN');

# The LDV model function definitions names are keys. Values are 1.
my %ldv_model_func_def;

# Command-line options. Use --help option to see detailed description of them.
my $opt_engine;
my $opt_help;
my $opt_report_in;
my $opt_report_out;
my $opt_reqs_out;
my $opt_src_files;

# Some usefull reqular expressions.
my $regexp_element_kind = '^([^=\(:]+)';

# Global show/hide classes and their defaults.
my %show_hide_global = (
    1 => {'class', my $entity_class_entry_point = 'ETVEntryPoint', 'name', 'Entry point', 'main', 0, 'show', 1}
  , 2 => {'class', my $entity_class_entry_point_body = 'ETVEntryPointBody', 'name', 'Entry point body', 'main', 0, 'show', 1}
  , 3 => {'class', my $entity_class_func_call = 'ETVFunctionCall', 'name', 'Function calls', 'main', 0, 'show', 1}
  , 4 => {'class', my $entity_class_func_call_init = 'ETVFunctionCallInitialization', 'name', 'Initialization function calls', 'main', 0, 'show', 0}
  , 5 => {'class', my $entity_class_func_call_without_body = 'ETVFunctionCallWithoutBody', 'name', 'Function without body calls', 'main', 0, 'show', 1}
  , 6 => {'class', my $entity_class_func_body = 'ETVFunctionBody', 'name', 'Function bodies', 'main', 1, 'show', 1}
  , 7 => {'class', my $entity_class_func_body_init = 'ETVFunctionInitializationBody', 'name', 'Initialization function bodies', 'main', 0, 'show', 0}
  , 8 => {'class', my $entity_class_block = 'ETVBlock', 'name', 'Blocks', 'main', 1, 'show', 1}
  , 9 => {'class', my $entity_class_return = 'ETVReturn', 'name', 'Returns', 'main', 0, 'show', 1}
  , 10 => {'class', my $entity_class_return_val = 'ETVReturnValue', 'name', 'Return values', 'main', 0, 'show', 1}
  , 11 => {'class', my $entity_class_assert = 'ETVAssert', 'name', 'Asserts', 'main', 0, 'show', 1}
  , 12 => {'class', my $entity_class_assert_cond = 'ETVAssertCondition', 'name', 'Assert conditions', 'main', 0, 'show', 1}
  , 13 => {'class', my $entity_class_ident = 'ETVIdentation', 'name', 'Identation', 'main', 0, 'show', 1}
  , 14 => {'class', my $entity_class_driver_env_init = 'ETVDriverEnvInit', 'name', 'Driver environment initialization', 'main', 0, 'show', 0}
  , 15 => {'class', my $entity_class_driver_env_func_call = 'ETVDriverEnvFunctionCall', 'name', 'Driver environment function calls', 'main', 0, 'show', 1}
  , 16 => {'class', my $entity_class_driver_env_func_body = 'ETVDriverEnvFunctionBody', 'name', 'Driver environment function bodies', 'main', 0, 'show', 1}
  , 17 => {'class', my $entity_class_model_assert = 'ETVModelAssert', 'name', 'Model asserts', 'main', 0, 'show', 1}
  , 18 => {'class', my $entity_class_model_change_state = 'ETVModelChangeState', 'name', 'Model state changes', 'main', 0, 'show', 1}
  , 19 => {'class', my $entity_class_model_return = 'ETVModelReturn', 'name', 'Model returns', 'main', 0, 'show', 1}
  , 20 => {'class', my $entity_class_model_func_call = 'ETVModelFuncCall', 'name', 'Model function calls', 'main', 0, 'show', 1}
  , 21 => {'class', my $entity_class_model_func_body = 'ETVModelFuncBody', 'name', 'Model function bodies', 'main', 0, 'show', 0}
  , 22 => {'class', my $entity_class_model_func_func_call = 'ETVModelFuncFuncCall', 'name', 'Model function function calls', 'main', 0, 'show', 1}
  , 23 => {'class', my $entity_class_model_func_func_body = 'ETVModelFuncFuncBody', 'name', 'Model function function bodies', 'main', 0, 'show', 1}
  , 24 => {'class', my $entity_class_model_other = 'ETVModelOther', 'name', 'Model others', 'main', 0, 'show', 1}
  , 25 => {'class', my $entity_class_intellectual_func_body = 'ETVIntellectualFuncBody', 'name', my $entity_class_intellectual_func_body_name = 'Function bodies without model function calls', 'main', 0, 'show', 0}
  );

# The number of indentation spaces.
my $space_indent = 3;

# This tag must be placed at the beginning and at the end of source code file
# name.
my $src_tag = '-------';

# Source code files referenced by the error trace. Keys are source code file
# names, values are their contents.
my %srcs;

# The colors to be used in highlighting.
my $syntax_colors = {
  comment => 'ETVSrcComment',
  string  => 'ETVSrcString',
  number  => 'ETVSrcNumber',
  key1    => 'ETVSrcCKeywords',
  key2    => 'ETVSrcCPPKeywords',
};

################################################################################
# Main section.
################################################################################

# Obtain the debug level.
get_debug_level($debug_name, $LDV_DEBUG, $LDV_ERROR_TRACE_VISUALIZER_DEBUG);

print_debug_normal("Process the command-line options");
get_opt();

print_debug_normal("Process trace");
my $tree_root = process_error_trace();

if ($opt_report_out)
{
  print_debug_normal("Process source code files");
  process_source_code_files();
  print_debug_normal("Visualize trace");
  visualize_error_trace($tree_root);
}

# TODO this must be fixed!!!!!! Add dependency on nodes!
if ($opt_reqs_out)
{
  if ($opt_engine eq $engine_blast)
  {
    foreach my $dep (keys(%dependencies))
    {
      print($file_reqs_out "$dep\n") unless ($dep =~ /\.i$/);
    }
  }
  if ($opt_engine eq $engine_cpachecker)
  {
    foreach my $dep (keys(%dependencies))
    {
      print($file_reqs_out "$dep\n") unless ($dep =~ /\.i$/);
    }
  }
}

print_debug_trace("Close file handlers");
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

print_debug_normal("Make all successfully");


################################################################################
# Subroutines.
################################################################################

sub add_mising_spaces($)
{
  my $str = shift;

  # Add mising spaces around equality sign.
  $str =~ s/([_a-zA-Z\d])=/$1 =/g;
  $str =~ s/=([_a-zA-Z\d])/= $1/g;

  return $str;
}

sub convert_file_to_link($)
{
  my $file_path = shift;

  # Exchange slashes and points with '_'.
  $file_path =~ s/\//_/g;
  $file_path =~ s/\./_/g;

  return $file_path;
}

sub get_opt()
{
  if (scalar(@ARGV) == 0)
  {
    warn("No options were specified through the command-line. Please see help to understand how to use this tool");
    help();
  }
  print_debug_trace("The options '@ARGV' were passed to the instrument through the command-line");

  unless (GetOptions(
    'engine=s' => \$opt_engine,
    'help|h' => \$opt_help,
    'report|c=s' => \$opt_report_in,
    'report-out|o=s' => \$opt_report_out,
    'reqs-out=s' => \$opt_reqs_out,
    'src-files=s' => \$opt_src_files))
  {
    warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool");
    help();
  }

  help() if ($opt_help);

  unless ($opt_engine and $opt_report_in)
  {
    warn("You must specify the options --engine, --report|c in the command-line");
    help();
  }

  $engine = $opt_engine;
  unless (defined($engines{$opt_engine}))
  {
    warn("The specified static verifier engine '$opt_engine' isn't supported. Please use one of the following engines: \n");
    foreach my $engine (keys(%engines))
    {
      if ($engine ne $engine_unknown)
      {
        warn("  - '$engine'\n");
      }
    }
    warn("The unknown engine '$engine_unknown' will be used instead of the specified one '$opt_engine'");
    $engine = $engine_unknown;
  }
  print_debug_debug("The engine '$engine' handlers will be used during an error trace processing and printing");

  unless ($opt_report_out or $opt_reqs_out)
  {
    warn("You must specify either the option --report-out|o or --reqs-out in the command-line");
    help();
  }

  if ($opt_report_out)
  {
    open($file_report_out, '>', "$opt_report_out")
      or die("Can't open the file '$opt_report_out' specified through the option --report-out|o for write: $ERRNO");
    print_debug_debug("The report output file is '$opt_report_out'");

    # When the error trace is visualized it'll good if corresponding sources are
    # presented too.
    if ($opt_src_files)
    {
      open($file_src_files, '<', "$opt_src_files")
        or die("Can't open the file '$opt_src_files' specified through the option --src-files for read: $ERRNO");
      print_debug_debug("The source code file is '$opt_src_files'");
    }
  }

  if ($opt_reqs_out)
  {
    open($file_reqs_out, '>', "$opt_reqs_out")
      or die("Can't open the file '$opt_reqs_out' specified through the option --reqs-out for write: $ERRNO");
    print_debug_debug("The requrements output file is '$opt_reqs_out'");
  }

  open($file_report_in, '<', "$opt_report_in")
    or die("Can't open the file '$opt_report_in' specified through the option --report-in|c for read: $ERRNO");
  print_debug_debug("The report input file is '$opt_report_in'");

  print_debug_debug("The command-line options are processed successfully");
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

  --src-files <file>
    <file> is an absolute path to a file containing source code
    referenced by the given error trace. It's optional. If there is no
    such option then no source code is shown.

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

sub print_error_trace($)
{
  my $tree_root = shift;

  print_debug_debug("Print the '$engine' static verifier error trace");
  $engines{$engine}{'print'}->($tree_root);
  print_debug_debug("'$engine' static verifier error trace is printed successfully");
}

sub print_error_trace_blast($)
{
  my $tree_root = shift;

  # Print show/hide menu plugin.
  print($file_report_out
    "\n<script type='text/javascript'>"
    , "\n\$(document).ready(function() {"
    , "\n  \$('#ETVShowHideMenuOthers li').hover(function() {"
    , "\n    \$(this).addClass('ETVactive');"
    , "\n    \$(this).find('form').show();"
    , "\n  }, function() {"
    , "\n    \$(this).removeClass('ETVactive');"
    , "\n    \$(this).find('form').hide();"
    , "\n  });"
    , "\n});"
    , "\n</script>");

  foreach my $order (sort({$a <=> $b} keys(%show_hide_global)))
  {
    print($file_report_out
      "\n<script type='text/javascript'>"
      , "\n\$(document).ready(function() {"
      , "\n  \$('#${show_hide_global{$order}{'class'}}Menu').change(function() {"
      , "\n    \$('a.#${show_hide_global{$order}{'class'}}ShowHide').click();"
      , "\n  });"
      , "\n});"
      , "\n</script>");
  }

  # Print entities global show/hide menu.
  print($file_report_out
    "\n<div id='ETVErrorTraceHeader'>");
  # First of all print the main entities to be show/hide.
  print($file_report_out
      "\n  <div id='ETVShowHideMenuMain'>"
    , "\n    <form>");
  foreach my $order (sort({$a <=> $b} keys(%show_hide_global)))
  {
    print($file_report_out
      "\n      <div class='ETVShowHideMenuMainItem'><input type='checkbox' id='${show_hide_global{$order}{'class'}}Menu' />$show_hide_global{$order}{'name'}</div>")
      if ($show_hide_global{$order}{'main'});
  }
  print($file_report_out
      "\n    </form>"
    , "\n  </div>");
  # Others are available through the advanced menu.
  print($file_report_out
      "\n  <ul id='ETVShowHideMenuOthers'>"
    , "\n    <li><div>Others...</div>"
    , "\n      <form style='display: none;'>");
  foreach my $order (sort({$a <=> $b} keys(%show_hide_global)))
  {
    print($file_report_out
      "\n        <input type='checkbox' id='${show_hide_global{$order}{'class'}}Menu' />$show_hide_global{$order}{'name'}<br />")
      if (!$show_hide_global{$order}{'main'});
  }
  print($file_report_out
      "\n      </form>"
    , "\n    </li>"
    , "\n  </ul>");
  print($file_report_out
    "\n</div>");

  # Print global show/hide script.
  print($file_report_out
    "\n<div id='ETVErrorTraceHeaderHiddenMenu'>");
  foreach my $order (sort({$a <=> $b} keys(%show_hide_global)))
  {
    print_show_hide_global($show_hide_global{$order}{'class'}, $show_hide_global{$order}{'name'})
     if ($show_hide_global{$order}{'class'} ne $entity_class_intellectual_func_body);
  }

  # Print intellectual global show/hide that allows to collapse all function
  # bodies that don't contain model function calls.
  print($file_report_out
    "\n<script type='text/javascript'>"
    , "\n\$(document).ready(function() {"
    , "\n \$('a.#${entity_class_intellectual_func_body}ShowHide').toggle(function() {"
    , "\n    \$('.$entity_class_func_body, .$entity_class_driver_env_func_body').each(function() {"
    , "\n      var isFuncBodyHasModelFuncCall = false;"
    , "\n      \$(this).children('div').each(function() {"
    , "\n        if (\$(this).hasClass('$entity_class_model_func_call')) {"
    , "\n          isFuncBodyHasModelFuncCall = true;"
    , "\n        }"
    , "\n      });"
    , "\n      if (!isFuncBodyHasModelFuncCall) {"
    , "\n        if (\$(this).css('display') != 'none') {"
    , "\n          \$('#' + \$(this).attr('id') + 'ShowHide').click();"
    , "\n        }"
    , "\n      }"
    , "\n    });"
    , "\n    \$(this).html('Show $entity_class_intellectual_func_body_name');"
    , "\n  }, function() {"
    , "\n    \$('.$entity_class_func_body, .$entity_class_driver_env_func_body').each(function() {"
    , "\n      var isFuncBodyHasModelFuncCall = false;"
    , "\n      \$(this).children('div').each(function() {"
    , "\n        if (\$(this).hasClass('$entity_class_model_func_call')) {"
    , "\n          isFuncBodyHasModelFuncCall = true;"
    , "\n        }"
    , "\n      });"
    , "\n      if (!isFuncBodyHasModelFuncCall) {"
    , "\n        if (\$(this).css('display') == 'none') {"
    , "\n          \$('#' + \$(this).attr('id') + 'ShowHide').click();"
    , "\n        }"
    , "\n      }"
    , "\n    });"
    , "\n    \$(this).html('Hide $entity_class_intellectual_func_body_name');"
    , "\n  });"
    , "\n});"
    , "\n</script>"
    , "\n<a id='${entity_class_intellectual_func_body}ShowHide' href='#'>Hide $entity_class_intellectual_func_body_name</a>");
  print($file_report_out
    "\n</div>");

  # Make defaults for global show/hide.
  # At the beginning reset all show/hide checkbox since they are stored for the
  # session.
  print($file_report_out
    "\n<script type='text/javascript'>"
    , "\n\$(document).ready(function() {"
    , "\n  \$('#ETVErrorTraceHeader input:checkbox').attr('checked', true);"
    , "\n});"
    , "\n</script>");

  foreach my $order (sort({$a <=> $b} keys(%show_hide_global)))
  {
    print($file_report_out
      "\n<script type='text/javascript'>"
      , "\n\$(document).ready(function() {"
      , "\n  \$('#${show_hide_global{$order}{'class'}}Menu').change().attr('checked', false);"
      , "\n});"
      , "\n</script>")
      if (!$show_hide_global{$order}{'show'});
  }

  # Print error trace tree recursively.
  print($file_report_out
    "\n    <div id='ETVErrorTrace'>");
  print_error_trace_node_blast($tree_root, 0);
  print($file_report_out
    "\n    </div>");
}

sub print_error_trace_cpachecker($)
{
  my $tree_root = shift;

  # Use the same trace printer as for blast since the error trace is converted
  # to its format.
  print_error_trace_blast($tree_root);
}

sub print_error_trace_unknown($)
{
  my $error_trace = shift;

  # Print unknown trace as it (that is keep all its spaces and newlines).
  print($file_report_out "\n    <div id='ETVErrorTrace' style='white-space: pre;'>$error_trace\n    </div>");
}

sub print_error_trace_node_blast($$)
{
  my $tree_node = shift;
  my $indent = shift;

  print_debug_trace("Print the '$tree_node->{'kind'}' tree node");

  # Process tree node values a bit.
  if (${$tree_node->{'values'}}[0])
  {
    # Remove names scope for all tree nodes.
    ${$tree_node->{'values'}}[0] =~ s/@[_a-zA-Z0-9]+//g;
    # Add spaces around some operators.
    ${$tree_node->{'values'}}[0] = add_mising_spaces(${$tree_node->{'values'}}[0]);
  }

  # Get source and line if so.
  my $src_full = '';
  my $src = '';
  my $line = 0;
  if ($tree_node->{'pre annotations'})
  {
    foreach my $pre_annotation (@{$tree_node->{'pre annotations'}})
    {
      if ($pre_annotation->{'kind'} eq 'Location')
      {
        $src_full = $pre_annotation->{'values'}[0];
        $src = $files_short_name{$src_full} || $src_full;
        $line = $pre_annotation->{'values'}[1];
      }
    }
  }
  $entity_line = $line;
  $entity_src = $src_full;
  # This title will be shown for all major entities.
  my $title = "$src:$line";
  # Process special model and driver environment comments.
  my $class = '';
  if (my $model_comment = $ldv_model_comments{$entity_src}{($line - 1)})
  {
    my %model_comment = %{$model_comment};
    $title .= ": Model " . $model_comment{'alias'} . " - " . $model_comment{'comment'};
    $class = $entity_class_model_assert
      if ($model_comment{'alias'} eq $ldv_model_comment_assert);
    $class = $entity_class_model_change_state
      if ($model_comment{'alias'} eq $ldv_model_comment_change_state);
    $class = $entity_class_model_return
      if ($model_comment{'alias'} eq $ldv_model_comment_return);
    $class = $entity_class_model_func_func_call
      if ($model_comment{'alias'} eq $ldv_model_comment_func_call);
    $class = $entity_class_model_other
      if ($model_comment{'alias'} eq $ldv_model_comment_other);
  }
  elsif (my $driver_env_comment = $ldv_driver_env_comments{$entity_src}{($line - 1)})
  {
    my %driver_env_comment = %{$driver_env_comment};
    $title .= ": Driver environment " . $driver_env_comment{'alias'} . " - " . $driver_env_comment{'comment'};
    $class = $entity_class_driver_env_init
      if ($driver_env_comment{'alias'} eq $ldv_driver_env_comment_var_init);
    $class = $entity_class_driver_env_func_call
      if ($driver_env_comment{'alias'} eq $ldv_driver_env_comment_func_call);
  }

  # Get formal parameter names if so.
  my @names = ();
  if ($tree_node->{'post annotations'})
  {
    foreach my $post_annotation (@{$tree_node->{'post annotations'}})
    {
      if ($post_annotation->{'kind'} eq 'Locals')
      {
        foreach my $name (@{$post_annotation->{'values'}})
        {
          # Remove parameter name scope.
          $name =~ s/@[_a-zA-Z0-9]+//g;
          push(@names, $name);
        }
      }
    }
  }

  # Print tree node declaration.
  if ($tree_node->{'kind'} eq 'Root')
  {
    print($file_report_out "\n<div class='$entity_class_entry_point' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print_show_hide_local("ETV$html_id");
    print($file_report_out "entry_point()", ";</div>");
    print($file_report_out "\n<div class='$entity_class_entry_point_body' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print($file_report_out "{");
  }
  elsif ($tree_node->{'kind'} eq 'FunctionCall')
  {
    my $val = ${$tree_node->{'values'}}[0];
    # Get the function name.
    my $func_name;
    if ($val =~ /=\s*([^\(]+)/ or $val =~ /\s*([^\(]+)/)
    {
      $func_name = $1;
      print_debug_trace("Find the function name '$1' in '$val'");

      # Check wether function is a model function.
      if ($ldv_model_func_def{$func_name})
      {
        print_debug_debug("Find the model function '$func_name'");
        $class = $entity_class_model_func_call;

        # Try to get corresponding model comment.
        if (my $model_comment = $ldv_model_comments{$ldv_model_func_def{$func_name}{'src'}}{$ldv_model_func_def{$func_name}{'line'}})
        {
          my %model_comment = %{$model_comment};
          $title .= ": Model " . $model_comment{'alias'} . " - " . $model_comment{'comment'};
        }
        else
        {
          print_debug_warning("Can't find the model comment for the function '$func_name'");
        }
      }
    }
    else
    {
      print_debug_warning("Can't find the function name in '$val'");
    }

    $class = $entity_class_func_call unless ($class);

    print($file_report_out "\n<div class='$class' title='$title' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print_show_hide_local("ETV$html_id");

    # Add formal parameters names comments.
    my $pos = 0;
    while (@names)
    {
      my $name = shift(@names);
      my $comment = " /* $name */";
      my $comment_length = length($comment);

      my $pos_cur;

      # The actual paramet is finished with ',' or ')' finishing function call.
      if (($pos_cur = index($val, ',', $pos)) != -1 or ($pos_cur = rindex($val, ')')) != -1)
      {
        $val = substr($val, 0, $pos_cur) . $comment . substr($val, $pos_cur);
        $pos = $pos_cur + $comment_length + 1;
        next;
      }

      last;
    }

    $val =~ s/(\/\*[^\*\/]*\*\/)/<span class='ETVFunctionFormalParamName'>$1<\/span>/g;

    print($file_report_out $val, ";</div>");

    my $class_body = $entity_class_func_body;

    if ($class eq $entity_class_model_func_call)
    {
      $class_body = $entity_class_model_func_body;
    }
    elsif ($class eq $entity_class_model_func_func_call)
    {
      $class_body = $entity_class_model_func_func_body;
    }
    elsif ($class eq $entity_class_driver_env_init)
    {
      $class_body = $entity_class_driver_env_init;
    }
    elsif ($class eq $entity_class_driver_env_func_call)
    {
      $class_body = $entity_class_driver_env_func_body;
    }

    print($file_report_out "\n<div class='$class_body' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print($file_report_out "{<br />");
  }
  elsif ($tree_node->{'kind'} eq 'FunctionCallInitialization')
  {
    print($file_report_out "\n<div class='$entity_class_func_call_init' title='$title' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print_show_hide_local("ETV$html_id");
    print($file_report_out ${$tree_node->{'values'}}[0], ";</div>");
    print($file_report_out "\n<div class='$entity_class_func_body_init' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print($file_report_out "{");
  }
  elsif ($tree_node->{'kind'} eq 'FunctionCallWithoutBody')
  {
    $class = $entity_class_func_call_without_body unless ($class);
    print($file_report_out "\n<div class='$class' title='$title' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print($file_report_out ${$tree_node->{'values'}}[0], "  { /* The function body is undefined. */ };</div>");
  }
  elsif ($tree_node->{'kind'} eq 'Block')
  {
    # Split expressions joined together into one block.
    my @exprs = split(/;/, ${$tree_node->{'values'}}[0]);
    $class = $entity_class_block unless ($class);
    print($file_report_out "\n<div class='$class' title='$title' id='ETV", ($html_id++), "'>");
    my $isshow_hide = 1;
    $isshow_hide = 0 unless (scalar(@exprs) > 1);

    foreach my $expr (@exprs)
    {
      print_spaces($indent);
      print_show_hide_local("ETV$html_id") if ($isshow_hide);
      print($file_report_out $expr, ";<br />");

      if ($isshow_hide)
      {
        print($file_report_out "\n<span class='ETVBlockContinue' id='ETV", ($html_id++), "'>");
        $isshow_hide = 0;
      }
    }

    print($file_report_out "</span>")
      if (scalar(@exprs) > 1);

    print($file_report_out "</div>");
  }
  elsif ($tree_node->{'kind'} eq 'Return')
  {
    $class = $entity_class_return unless ($class);
    print($file_report_out "\n<div class='$class' title='$title' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print($file_report_out "return ", "<span class='$entity_class_return_val'>", ${$tree_node->{'values'}}[0], "</span>;</div>");
  }
  elsif ($tree_node->{'kind'} eq 'Pred')
  {
    $class = $entity_class_assert
      unless ($class eq $entity_class_model_assert);
    print($file_report_out "\n<div class='$class' title='$title' id='ETV", ($html_id++), "'>");
    print_spaces($indent);
    print($file_report_out "assert(", "<span class='$entity_class_assert_cond'>", ${$tree_node->{'values'}}[0], "</span>);</div>");
  }

  # Print all tree node children with enlarged indentation.
  if ($tree_node->{'children'})
  {
    foreach my $child (@{$tree_node->{'children'}})
    {
      print_error_trace_node_blast($child, ($indent + $space_indent));
    }
  }

  # Print the close brace after the body of root and function bodies nodes.
  if ($tree_node->{'kind'} eq 'Root'
    or $tree_node->{'kind'} eq 'FunctionCall'
    or $tree_node->{'kind'} eq 'FunctionCallInitialization')
  {
    print_spaces($indent);
    print($file_report_out "}</div>");
  }
}

sub print_spaces($)
{
  my $space_number = shift;

  # Print the line number at the beginning of every line. Note that the line
  # number is generated just one time for each entity that has it. If entity
  # occupies more than one line then following to the first line fields are
  # filled with spaces. Because of there is spaces indentation before each line
  # this is done here.
  print($file_report_out "<span class='ETVLineNumber'>");
  if ($entity_line and $entity_src)
  {
    # Generate a link to the source code line if so.
    my $entity_line_str = sprintf("%5d ", $entity_line);

    if ($files_long_name{$entity_src})
    {
      my $file_link = convert_file_to_link($files_long_name{$entity_src});

      $entity_line_str =~ s/(\d+)/<a href='#$file_link:$entity_line'>$1<\/a>/;
      print($file_report_out $entity_line_str)
    }
    else
    {
      print($file_report_out $entity_line_str);
    }

    $entity_line = 0;
    $entity_src = '';
  }
  else
  {
    print($file_report_out "      ");
  }
  print($file_report_out "</span>");

  # Print identation spaces.
  print($file_report_out "<span class='$entity_class_ident'>");

  for (my $i = 1; $i <= $space_number; $i++)
  {
    print($file_report_out ' ');
  }

  print($file_report_out "</span>");
}

sub print_show_hide_global($$)
{
  my $entity_class = shift;
  my $entity_class_human_readable = shift;

  print($file_report_out
    "\n<script type='text/javascript'>"
    , "\n\$(document).ready(function() {"
    , "\n  \$('a.#${entity_class}ShowHide').toggle(function() {"
    , "\n    \$('.$entity_class').each(function() {"
    , "\n      if (\$(this).css('display') != 'none') {"
    , "\n        \$(this).hide();"
    , "\n        \$('#' + \$(this).attr('id') + 'ShowHide').click();"
    , "\n      }"
    , "\n    });"
    , "\n    \$(this).html('Show $entity_class_human_readable');"
    , "\n  }, function() {"
    , "\n    \$('.$entity_class').each(function() {"
    , "\n      if (\$(this).css('display') == 'none') {"
    , "\n        \$(this).show();"
    , "\n        \$('#' + \$(this).attr('id') + 'ShowHide').click();"
    , "\n      }"
    , "\n    });"
    , "\n    \$(this).html('Hide $entity_class_human_readable');"
    , "\n  });"
    , "\n});"
    , "\n</script>"
    , "\n<a id='${entity_class}ShowHide' href='#'>Hide $entity_class_human_readable</a>");
}

sub print_show_hide_local($)
{
  my $entity_id = shift;

  print($file_report_out
    "<a id='${entity_id}ShowHide' href='#' class='ETVShowHide'>-</a>\n");
}

sub process_error_trace()
{
  print_debug_debug("Process the '$engine' static verifier error trace");
  my $tree_root = $engines{$engine}{'process'}->();
  print_debug_debug("'$engine' static verifier error trace is processed successfully");

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
      # Read line with some processing.
      my $element_part = read_line(1);

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
          print_debug_trace("Process the '$element_kind' tree node");

          # Ignore skips at all.
          if ($element_value)
          {
            $entity = Entity->new({'engine' => 'blast', 'kind' => $element_kind, 'values' => $element_value});

            # Some nodes are processed in a special way.
            if ($entity->{'kind'} ne $element_kind)
            {
              print_debug_trace("The tree node kind was changed to the '" . $entity->{'kind'} . "'");
            }

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
          print_debug_trace("Process the '$element_kind' annotation");

          # Ignore arificial locations at all.
          if ($element_value)
          {
            # Story dependencies. TODO make it entity specific!!!!!!!!!!!!!!!!!!!!!!!
            if ($element_kind eq $element_kind_location)
            {
              my ($src, $line) = @{$element_value};
              if(defined($line))
              {
                $dependencies{$src} = 1;
              }
              $files_long_name{$src} = 0;
              $src =~ /([^\/]*)$/;
              $files_short_name{$src} = $1;
              print_debug_trace("The full name '$src' was related with the short name '$1'");
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

sub process_error_trace_cpachecker()
{
  my @error_trace_raw = <$file_report_in>;
  my $error_trace_converted = CPAchecker->convert_cpa_trace_to_blast($opt_reqs_out, \@error_trace_raw);

  # We already gather requirements, so finish processing.
  unless ($opt_reqs_out)
  {
    # Update the error trace file with the converted trace.
    close($file_report_in)
      or die("Can't close the file '$opt_report_in': $ERRNO\n");

    open($file_report_in, '>', "$opt_report_in")
      or die("Can't open the file '$opt_report_in' specified through the option --report-in|c for write: $ERRNO");

    print($file_report_in @{$error_trace_converted});

    close($file_report_in)
      or die("Can't close the file '$opt_report_in': $ERRNO\n");

    open($file_report_in, '<', "$opt_report_in")
      or die("Can't open the file '$opt_report_in' specified through the option --report-in|c for read: $ERRNO");

    # Use the same trace processor as for blast since the error trace is converted
    # to its format.
    return process_error_trace_blast();
  }
}

sub process_error_trace_unknown()
{
  my $error_trace = '';

  # Read lines without any processing.
  while (defined(my $line = read_line(0)))
  {
    $error_trace .= "$line";
  }

  return $error_trace;
}

sub process_source_code_files()
{
  # Do nothing if there is no source code files.
  return 0 unless ($opt_src_files);

  # Otherwise separate files into the source code files hash.
  my $file_name;
  my $isrelated_with;
  my $line_numb;
  while (<$file_src_files>)
  {
    my $line = $_;
    chomp($line);

    if ($line =~ /^$src_tag(.*)$src_tag$/)
    {
      $file_name = $1;
      print_debug_trace("Try to relate file by its long name '$file_name' with some long name");
      $isrelated_with = '';
      foreach my $full_name (keys(%files_long_name))
      {
        if ($full_name =~ /\Q$file_name\E$/ or $file_name =~ /\Q$full_name\E$/)
        {
          if ($files_long_name{$file_name})
          {
            print_debug_warning("The full name '$full_name' corresponds to several long names '$files_long_name{$full_name}' and '$file_name'")
          }
          else
          {
            $files_long_name{$full_name} = $file_name;
            $isrelated_with = $full_name;
            print_debug_trace("The full name '$full_name' was related with the long name '$file_name'");
          }
        }
      }
      print_debug_warning("The long name '$file_name' wasn't related with any full name")
        unless ($isrelated_with);
      $file_name =~ /([^\/]*)$/;
      $files_short_name{$file_name} = $1;
      print_debug_debug("The long name '$file_name' was related with the short name '$1'");
      print_debug_debug("Process the '$file_name' source code file");
      $line_numb = 1;
      next;
    }

    print_debug_warning("The source code file has incorrect format. No file name is specified")
      unless ($file_name);

    # Read LDV model comments.
    foreach my $ldv_model_comment_alias (keys(%ldv_model_comment_names))
    {
      if ($line =~ /^\s*\/\*\s*$ldv_model_comment_names{$ldv_model_comment_alias}\s*([^\*\/]*)\*\/\s*$/)
      {
        my $comment = $1;
        # Attributes hash. Keys are attribute names, values are corresponding
        # attribute values.
        my %attrs;

        # Read auxiliary comment attributes. They are in form:
        # (attr1 = 'attr1 value', attr2 = 'attr2 value', ...)
        if ($comment =~ /\(([^\)]*)\)\s*/)
        {
          my $attr_all = $1;
          $comment = $POSTMATCH;

          my @attrs = split(/,/, $attr_all);
          # Read attribute name and value for each attribute.
          foreach my $attr (@attrs)
          {
            # Attributes must have the correct form.
            if ($attr =~ /^([^\s]+)\s*=\s*'([^']*)'\s*$/)
            {
              $attrs{$1} = $2;
              print_debug_debug("Read the model comment attibute $1='$2'");
            }
            # If not so then warn and skip attribute.
            else
            {
              print_debug_warning("The model comment attribute '$attr' has incorrect form");
            }
          }
        }

        $ldv_model_comments{$isrelated_with}{$line_numb}
          = {'alias' => $ldv_model_comment_alias, 'comment' => $comment, 'attrs' => \%attrs};

        # Remember placement of the ldv functions definitions.
        if ($ldv_model_comment_alias eq $ldv_model_comment_func_def)
        {
          # All model functions definitions must have a name attribute.
          if ($attrs{'name'})
          {
            $ldv_model_func_def{$attrs{'name'}} = {'src' => $isrelated_with, 'line' => $line_numb};
          }
          else
          {
            print_debug_warning("The model function definition hasn't the 'name' attribute");
          }
        }
      }
    }

    # Read LDV driver environment comments.
    foreach my $ldv_driver_env_comment_alias (keys(%ldv_driver_env_comment_names))
    {
      $ldv_driver_env_comments{$isrelated_with}{$line_numb}
        = {'alias' => $ldv_driver_env_comment_alias, 'comment' => $1}
        if ($line =~ /^\s*\/\*\s*$ldv_driver_env_comment_names{$ldv_driver_env_comment_alias}\s*([^\*\/]*)\*\/\s*$/);
    }

    push(@{$srcs{$file_name}}, "$line");
    $line_numb++;
  }
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

sub read_line($)
{
  my $is_processing = shift;

  # Read the next line from the input report file if so.
  return undef unless (defined(my $line = <$file_report_in>));

  # Make processing just in case when it's needed.
  if ($is_processing)
  {
    # Remove the end of line.
    chomp($line);
    # Remove all formatting spaces and tabs placed at the beginning of the line.
    $line =~ /^[\s]*/;
    $line = $POSTMATCH;
  }

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

sub visualize_error_trace($)
{
  my $tree_root = shift;

  # Print javascript global variables at the beginning.
  print($file_report_out
      "\n<script type='text/javascript'>"
    , "\n  var tabNoActiveWidth;"
    , "\n</script>");

  # Print simple tab plugin before its usage.
  print($file_report_out
      "\n<script type='text/javascript'>"
    , "\n  \$(document).ready(function() {"
    , "\n    var tabsNumb = \$('#ETVTabsHeader li').length;"
    , "\n    var tabsHeaderWidth = \$('#ETVTabsHeader li:first').parent().width();"
    , "\n    \$('#ETVTabs div').hide();"
    , "\n    \$('#ETVTabs div:first').show();"
    , "\n    \$('#ETVTabsHeader li:first').addClass('ETVActive');"
    , "\n    var tabActiveWidth = \$('#ETVTabsHeader li.ETVActive').width();"
    , "\n    tabNoActiveWidth = (tabsHeaderWidth - tabActiveWidth - 2) / (tabsNumb - 1);"
    , "\n    tabNoActiveWidth = Math.floor(tabNoActiveWidth) - 2;"
    , "\n    \$('#ETVTabsHeader li').not('.ETVActive').width(tabNoActiveWidth);"
    , "\n    \$('#ETVTabsHeader li a').click(function() {"
    , "\n      \$('#ETVTabsHeader li').removeClass('ETVActive');"
    , "\n      \$(this).parent().removeAttr('style').addClass('ETVActive');"
    , "\n      \$('#ETVTabsHeader li').not('.ETVActive').width(tabNoActiveWidth);"
    , "\n      var currentLink = \$(this).attr('href');"
    , "\n      var linkPosition = currentLink.lastIndexOf('#');"
    , "\n      currentTabShort = currentLink.substring(linkPosition);"
    , "\n      \$('#ETVTabs div').hide();"
    , "\n      \$(currentTabShort).show();"
    , "\n      return false;"
    , "\n    });"
    , "\n  });"
    , "\n</script>");

  # Print error trace with source code relation plugin.
  print($file_report_out
      "\n<script type='text/javascript'>"
    , "\n  \$(document).ready(function() {"
    , "\n    \$('.ETVLineNumber a').click(function() {"
    , "\n      \$('#ETVTabs ul li').removeClass('ETVActive');"
    , "\n      var currentLink = \$(this).attr('href');"
    , "\n      var linkPosition = currentLink.lastIndexOf('#');"
    , "\n      var linePosition = currentLink.lastIndexOf(':');"
    , "\n      currentTab = currentLink.substring(0, linePosition);"
    , "\n      currentTabShort = currentLink.substring(linkPosition, linePosition);"
    , "\n      currentLineShort = currentLink.substring(linkPosition);"
    , "\n      \$('#ETVTabs div').hide();"
    , "\n      \$('#ETVTabsHeader li a[href=' + currentTabShort + ']').parent().removeAttr('style').addClass('ETVActive');"
    , "\n      \$('#ETVTabsHeader li').not('.ETVActive').width(tabNoActiveWidth);"
    , "\n      \$(currentTabShort).show();"
    , "\n      \$('#ETVTabs div span').removeClass('ETVMarked');"
    , "\n      var srcStr = \$('a[name=' + currentLineShort.substring(1) + ']').parent();"
    , "\n      srcStr.addClass('ETVMarked');"
    , "\n      srcStr.parent().scrollTop(0).scrollTop(srcStr.position().top - srcStr.parent().position().top - 50);"
    , "\n      return false;"
    , "\n    });"
    , "\n  });"
    , "\n</script>");

  # Print local show/hide plugin.
  print($file_report_out
      "\n<script type='text/javascript'>"
    , "\n\$(document).ready(function() {"
    , "\n    \$('a.ETVShowHide').toggle(function() {"
    , "\n        var entityId = \$(this).attr('id');"
    , "\n        entityId = entityId.substring(0, entityId.lastIndexOf('ShowHide'));"
    , "\n        \$('#' + entityId).hide();"
    , "\n        \$(this).html('+');"
    , "\n      } , function() {"
    , "\n        var entityId = \$(this).attr('id');"
    , "\n        entityId = entityId.substring(0, entityId.lastIndexOf('ShowHide'));"
    , "\n        \$('#' + entityId).show();"
    , "\n        \$(this).html('-');"
    , "\n    });"
    , "\n  });"
    , "\n</script>");

  # Print short ETV help.
  print($file_report_out
      "\n  <div class='ETVHelp'>"
    , "\n    <p>Here is the <i>explanation</i> of the rule violation arisen in your driver for the corresponding kernel.</p>"
    , "\n    <p>Note that there may be <i>no</i> error indeed. Please <i>see</i> on error trace and source code to <i>understand</i> whether there is an error in your driver.</p>"
    , "\n    <p>The <b>Error trace</b> column contains the <i>path</i> on which rule is violated. You can choose some <i>entity classes</i> to be <i>shown</i> or <i>hiden</i> by clicking on the corresponding <i>checkboxes</i> or in the advanced <i>Others</i> menu. Also you can <i>show</i> or <i>hide</i> each <i>particular entity</i> by clicking on the corresponding <i>-</i> or <i>+</i>. In <i>hovering</i> on some <i>entities</i> you can see their <i>descriptions</i> and <i>meaning</i>. Also the <i>error trace</i> is binded with the <i>source code</i>. <i>Line numbers</i> are shown as <i>links</i> on the left. You can <i>click</i> on them to open the <i>corresponding line</i> in <i>source code</i>. <i>Line numbers</i> and <i>file names</i> are shown in <i>entity descriptions</i>.</p>"
    , "\n    <p>The <b>Source code</b> column contains <i>content</i> of <i>files related</i> with the <i>error trace</i>. There are your <i>driver</i> (<i>note</i> that there are some <i>our modifications</i> at the end), <i>kernel headers</i> and <i>rule</i> source code. <i>Tabs</i> show the currently opened file and other available files. In <i>hovering</i> you can see <i>file names</i> in <i>titles</i>. On <i>clicking</i> the corresponding <i>file content</i> will be shown.</p>"
    , "\n  </div>");

  # Create the table having two cells. The first cell is for the error trace and
  # the second is for the tabed source code.
  print($file_report_out
      "\n<table id='ETVGeneralWindow'>"
    , "\n<tr>"
    , "\n  <td id='ETVErrorTraceWindow'>"
    , "\n    <div class='ETVTableColumnHeader'>"
    , "\n      Error trace"
    , "\n    </div>");
  print_error_trace($tree_root);
  print($file_report_out
      "\n  </td>"
    , "\n  <td id='ETVSrcWindow'>"
    , "\n    <div class='ETVTableColumnHeader'>"
    , "\n      Source code"
    , "\n    </div>"
    , "\n    <div id='ETVTabs'>"
    , "\n      <ul id='ETVTabsHeader'>");
  foreach my $src (sort(keys(%srcs)))
  {
    print($file_report_out
      "\n        <li><a title='$files_short_name{$src}' href='#" . convert_file_to_link($src) . "'>$files_short_name{$src}</a></li>");
  }
  print($file_report_out
      "\n      </ul>");

  foreach my $src (sort(keys(%srcs)))
  {
    print($file_report_out
      "\n      <div id='" . convert_file_to_link($src) . "' class='ETVSrc'>");

    # Make syntax highlighting of the source code.
    my $syntax_highlighter = new Text::Highlight('colors' => $syntax_colors, wrapper => "%s");
    my $src_all = join("\n", @{$srcs{$src}});
    my $src_all_highlighted = $syntax_highlighter->highlight('CPP', $src_all);
    my @src_highlighted = split(/\n/, $src_all_highlighted);
    my $line_numb = 1;
    foreach my $line (@src_highlighted)
    {
      printf($file_report_out "<span class='ETVSrcLineNumber'><a name='" . convert_file_to_link($src) . ":$line_numb'></a>%5d </span>", $line_numb);
      print($file_report_out "$line");
      $line_numb++;
      print($file_report_out "\n") if ($line_numb <= scalar(@src_highlighted));
    }

    print($file_report_out
      "\n      </div>");
  }

  print($file_report_out
      "\n    </div>"
    , "\n  </td>"
    , "\n</tr>"
    , "\n</table>\n");
}
