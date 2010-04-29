#! /usr/bin/perl -w


use Cwd qw(abs_path cwd);
use English;
use Env qw(LDV_DEBUG LDV_KERNEL_RULES WORK_DIR);
use File::Basename qw(basename fileparse);
use File::Copy qw(mv);
use FindBin;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use File::Path qw(mkpath);
use strict;
use XML::Twig qw();
use XML::Writer qw();

# Add some local Perl packages.
use lib("$FindBin::RealBin/../shared/perl");

use File::Cat qw(cat);
use File::Copy::Recursive qw(rcopy);


################################################################################
# Subroutine prototypes.
################################################################################

# Merge usual and common aspects in the aspect mode.
# args: no.
# retn: nothing.
sub create_general_aspect();

# Determine debug level in depend on LDV_DEBUG environment variable.
# args: no.
# retn: nothing.
sub get_debug_level();

# Obtain information for required model from models database xml.
# args: no.
# retn: nothing.
sub get_model_info();

# Process command-line options. To see detailed description of these options 
# run script with --help option.
# args: no.
# retn: nothing.
sub get_opt();

# Print help message on the screen and exit with syntax error.
# args: no.
# retn: nothing.
sub help();

# Obtain needed files and dirs and check their presence.
# args: no.
# retn: nothing.
sub prepare_files_and_dirs();

# Debug functions group. They print some information in depend on debug level.
# args: string to be printed.
# retn: nothing.
sub print_debug_normal($);
sub print_debug_info($);
sub print_debug_debug($);
sub print_debug_trace($);
sub print_debug_all($);

# Process single cc command from input xml file.
# args: no.
# retn: nothing.
sub process_cmd_cc();

# Process single ld command from input xml file.
# args: no.
# retn: nothing.
sub process_cmd_ld();

# Process commands from input xml file.
# args: no.
# retn: nothing.
sub process_cmds();

# Transform a rcv report to the rule instrumentor one.
# args: no.
# retn: nothing.
sub process_report();


################################################################################
# Global variables.
################################################################################

# Suffix for file that will contain general aspect consisting of usual and 
# common aspects.
my $aspect_general_suffix = '.general';

# Information on a current command.
my %cmd;
# Commands execution status;
my %cmds_status;

# Instrumentor basedir.
my $cmd_basedir;

# Directory where common model is placed. It's needed to find appropriate 
# header files.
my $common_model_dir;
# Suffixes for common models in the plain mode.
my $common_c_suffix = '.common.c';
my $common_o_suffix = '.common.o';

# Debug levels flags. The amount of debug information increases in depend of 
# debug level and each following level includes the previous one:
#   'normal' - show execution progress shortly.
#   'info' - show executed commands.
#   'debug' - full information needed for debug is shown.
#   'trace' - both debug and some additional information is shown.
#   'all' - print so much information as can.
my $debug_normal = 0;
my $debug_info = 0;
my $debug_debug = 0;
my $debug_trace = 0;
my $debug_all = 0;

# Prefix for all debug messages.
my $debug_name = 'rule-instrumentor';

# Stream where debug messages will be printed.
my $debug_stream = \*STDOUT;

# Errors return codes.
my $error_syntax = 1; 
my $error_semantics = 2;

# File handlers.
my $file_cmds_log;
my $file_report_xml_out;
my $file_xml_out;

# Options to the gcc compiler to be turned on/off.
my @gcc_aspect_off_opts;
my @gcc_aspect_on_opts;
my @gcc_plain_off_opts;
my @gcc_plain_on_opts;

# Additional suffixies for id attributes.
my $id_common_model_suffix = '-with-common-model';
my $id_cc_llvm_suffix = '-llvm-cc';
my $id_ld_llvm_suffix = '-llvm-ld';

# Kind of instrumentation.
my $kind_isplain = 0;
my $kind_isaspect = 0;

my $ldv_rule_instrumentor_abs;
my @ldv_rule_instrumentor_path;
my $ldv_rule_instrumentor_dir;
my $LDV_HOME;
my $ldv_rule_instrumentor;
my $ldv_aspectator_bin_dir;
my $ldv_aspectator;
# Environment variable that says that options passed to gcc compiler aren't
# quoted.
my $ldv_no_quoted = 'LDV_NO_QUOTED';
# Environment variable that will keep path to GCC executable.
my $ldv_aspectator_gcc = 'LDV_LLVM_GCC';
my $ldv_c_backend;
my $ldv_gcc;
# Linker.
my $ldv_linker;

# Directory contains rules models database and their source code.
my $ldv_model_dir;

# Name of xml file containing models database. Name is relative to models
# directory. 
my $ldv_model_db_xml = 'model-db.xml';

# Information on needed model.
my %ldv_model;

# Suffix of llvm bitcody files.
my $llvm_bitcode_suffix = '.bc';

# Suffix of llvm bitcode files instrumented with general aspect.
my $llvm_bitcode_general_suffix = '.general';

# Suffix of linked llvm bitcode files.
my $llvm_bitcode_linked_suffix = '.linked';

# Suffix of llvm bitcode files instrumented with usual aspect.
my $llvm_bitcode_usual_suffix = '.usual';

# Options to be passed to llvm C backend.
my @llvm_c_backend_opts = ('-f', '-march=c');

# Suffix for llvm C backend production.
my $llvm_c_backend_suffix = '.cbe.c';

# Options to be passed to llvm linker.
my @llvm_linker_opts = ('-f');

# The commands log file designatures.
my $log_cmds_aspect = 'mode=aspect';
my $log_cmds_cc = 'cc';
my $log_cmds_check = ':check=true';
my $log_cmds_fail = 'fail';
my $log_cmds_ld = 'ld';
my $log_cmds_ok = 'ok';
my $log_cmds_plain = 'mode=plain';

# Command-line options. Use --help option to see detailed description of them.
my $opt_basedir;
my $opt_cmd_xml_in;
my $opt_cmd_xml_out;
my $opt_help;
my $opt_model_id;
my $opt_report_in;
my $opt_report_out;

# This flag says whether usual or report mode is set up.
my $report_mode = 0;

# A path to auxiliary working directory of this tool. The tool places its needed 
# temporaries there. It's relative to WORK_DIR. 
my $tool_aux_dir = 'rule-instrumentor';
# The name of file where commands execution status will be logged. It's relative
# to the tool auxiliary working directory.
my $tool_cmds_log = 'cmds-log';
# An absolute path to working directory of this tool.
my $tool_working_dir;

# Xml nodes names.
my $xml_cmd_attr_id = 'id';
my $xml_cmd_attr_check = 'check';
my $xml_cmd_basedir = 'basedir';
my $xml_cmd_entry_point = 'main';
my $xml_cmd_cc = 'cc';
my $xml_cmd_cwd = 'cwd';
my $xml_cmd_in = 'in';
my $xml_cmd_ld = 'ld';
my $xml_cmd_opt = 'opt';
my $xml_cmd_out = 'out';
my $xml_cmd_root = 'cmdstream';
my $xml_header = '<?xml version="1.0"?>';
my $xml_model_db_attr_id = 'id';
my $xml_model_db_engine = 'engine';
my $xml_model_db_error = 'error';
my $xml_model_db_files = 'files';
my $xml_model_db_files_aspect = 'aspect';
my $xml_model_db_files_common = 'common';
my $xml_model_db_files_filter = 'filter';
my $xml_model_db_hints = 'hints';
my $xml_model_db_kind = 'kind';
my $xml_model_db_model = 'model';
my $xml_model_db_opt_aspect = 'aspect_options';
my $xml_model_db_opt_on = 'on';
my $xml_model_db_opt_off = 'off';
my $xml_model_db_opt_plain = 'plain_options';
my $xml_report_attr_main = 'main';
my $xml_report_attr_model = 'model';
my $xml_report_attr_ref = 'ref';
my $xml_report_cc = 'cc';
my $xml_report_desc = 'desc';
my $xml_report_ld = 'ld';
my $xml_report_rcv = 'rcv';
my $xml_report_rule_instrumentor = 'rule-instrumentor';
my $xml_report_root = 'reports';
my $xml_report_status = 'status';
my $xml_report_status_fail = 'FAILED';
my $xml_report_status_ok = 'OK';
my $xml_report_time = 'time';
my $xml_report_trace = 'trace';
my $xml_report_verdict = 'verdict';


################################################################################
# Main section.
################################################################################

# Specify debug level.
get_debug_level();

print_debug_normal("Obtain the absolute path of the current working directory.");
$tool_working_dir = Cwd::cwd() 
  or die("Couldn't get current working directory");
print_debug_debug("The current working directory is '$tool_working_dir'.");

print_debug_normal("Process the command-line options.");
get_opt();

print_debug_normal("Check presence of needed files, executables and directories. Copy needed files and directories.");
prepare_files_and_dirs();

print_debug_trace("Prepare a twig xml parser for the models database, the input commands and report.");
my $xml_twig = new XML::Twig;
my $xml_writer;

if ($report_mode)
{
  process_report();  

  close($file_report_xml_out) 
    or die("Couldn't close file '$opt_report_out': $ERRNO\n");

  print_debug_normal("Make the report successfully.");
  exit 0;  
}

print_debug_normal("Get and store information on the required model.");
get_model_info();

print_debug_normal("Create a general aspect if it's needed.");
create_general_aspect();

print_debug_trace("Print the standard xml file header.");
print($file_xml_out "$xml_header\n");

# In the aspect mode prepare special xml writer.
if ($kind_isaspect)
{
  print_debug_trace("Prepare a xml writer, open a root node tag and print a base directory in the aspect mode.");  
  $xml_writer = new XML::Writer(OUTPUT => $file_xml_out, NEWLINES => 1, UNSAFE => 1);
  $xml_writer->startTag($xml_cmd_root);
  $xml_writer->dataElement($xml_cmd_basedir => $opt_basedir);
}
else
{
  print_debug_trace("Print a root node open tag in the plain mode.");
  print($file_xml_out "<$xml_cmd_root>");
}

print_debug_normal("Process the commands input file.");
process_cmds();

if ($kind_isaspect)
{
  print_debug_trace("Close the root node tag and peform final checks in the aspect mode.");
  $xml_writer->endTag();
  $xml_writer->end();
}
else
{
  print_debug_trace("Print root node close tag in the plain mode.");
  print($file_xml_out "\n</$xml_cmd_root>\n");
}

close($file_cmds_log) 
  or die("Couldn't close file '$tool_aux_dir': $ERRNO\n");

close($file_xml_out) 
  or die("Couldn't close file '$opt_cmd_xml_out': $ERRNO\n");

print_debug_normal("Make all successfully.");

################################################################################
# Subroutines.
################################################################################

sub create_general_aspect()
{
  if ($kind_isaspect)
  {
    $ldv_model{'general'} = "$ldv_model{'aspect'}$aspect_general_suffix";

    open(my $file_aspect_general, '>', "$ldv_model_dir/$ldv_model{'general'}")
      or die("Couldn't open file '$ldv_model_dir/$ldv_model{'general'}' for write: $ERRNO");
    cat("$ldv_model_dir/$ldv_model{'aspect'}", $file_aspect_general)
      or die("Can't concatenate file '$ldv_model_dir/$ldv_model{'aspect'}' with file '$ldv_model_dir/$ldv_model{'general'}'");
    cat("$ldv_model_dir/$ldv_model{'common'}", $file_aspect_general)
      or die("Can't concatenate file '$ldv_model_dir/$ldv_model{'common'}' with file '$ldv_model_dir/$ldv_model{'general'}'");
    close($file_aspect_general) 
      or die("Couldn't close file '$ldv_model_dir/$ldv_model{'general'}': $ERRNO\n");
    print_debug_debug("The general aspect '$ldv_model_dir/$ldv_model{'general'}' was created.");
  }
}

sub get_debug_level()
{
  # By default (in case when LDV_DEBUG environment variable isn't specified) and
  # when LDV_DEBUG is 0 just information on errors is printed. Otherwise:
  if ($LDV_DEBUG)
  {
    if ($LDV_DEBUG >= 10)
    {
      $debug_normal = 1;
    }
    
    if ($LDV_DEBUG >= 20)
    {
      $debug_info = 1;
    }
    
    if ($LDV_DEBUG >= 30)
    {
      $debug_debug = 1;
    }
    
    if ($LDV_DEBUG >= 40)
    {
      $debug_trace = 1;
    }
    
    if ($LDV_DEBUG == 100)
    {
      $debug_all = 1;
    }
  }
  else
  {
    $LDV_DEBUG = 0;
  }
  
  print_debug_debug("Debug level is set correspondingly to the LDV_DEBUG environment variable value '$LDV_DEBUG'.");
}

sub get_model_info()
{
  print_debug_trace("Read the models database xml file '$ldv_model_dir/$ldv_model_db_xml'.");
  $xml_twig->parsefile("$ldv_model_dir/$ldv_model_db_xml");
  my $model_db = $xml_twig->root;

  print_debug_trace("Obtain all models.");
  my @models = $model_db->children;

  print_debug_trace("Iterate over the all models and try to find the appropriate one.");
  foreach my $model (@models)
  {
    # Process options to be passed to the gcc compiler.
    if ($model->gi eq $xml_model_db_opt_plain || $model->gi eq $xml_model_db_opt_aspect)
    {
      print_debug_trace("Process '" . $model->gi . "' options.");  
      
      # Such options consist of two classes: on and off options. Process them
      # separately.
      print_debug_trace("Read an array of on options.");
      my @on_opts = ();
      for (my $on_opt = $model->first_child($xml_model_db_opt_on)
        ; $on_opt
        ; $on_opt = $on_opt->next_elt($xml_model_db_opt_on))
      {
        push(@on_opts, $on_opt->text);

        last if ($on_opt->is_last_child($xml_model_db_opt_on));
      }
      print_debug_debug("The on options '@on_opts' are specified.");
      
      print_debug_trace("Read an array of off options.");
      my @off_opts = ();
      for (my $off_opt = $model->first_child($xml_model_db_opt_off)
        ; $off_opt
        ; $off_opt = $off_opt->next_elt($xml_model_db_opt_off))
      {
        push(@off_opts, $off_opt->text);

        last if ($off_opt->is_last_child($xml_model_db_opt_off));
      }
      print_debug_debug("The off options '@off_opts' are specified.");
              
      # Separate options in depend on the mode.  
      if ($model->gi eq $xml_model_db_opt_plain)
      {
        @gcc_plain_off_opts = @off_opts;
        @gcc_plain_on_opts = @on_opts;
      }
      else
      {
        @gcc_aspect_off_opts = @off_opts;
        @gcc_aspect_on_opts = @on_opts; 
      }  
        
      # Go to the next 'model'.
      next;
    }
       
    unless ($model->gi eq $xml_model_db_model)
    {
      warn("The models database contains '" . $model->gi . "' tag that can't be parsed.");
      exit($error_semantics);
    }
      
    print_debug_trace("Read id attribute for a model to find the corresponding one."); 
    my $id_attr = $model->att($xml_model_db_attr_id) 
      or die("Models database doesn't contain '$xml_model_db_attr_id' attribute for some model");
    print_debug_debug("Read the '$id_attr' id attribute for a model.");

    # Model is found!
    if ($id_attr eq $opt_model_id)
    {
      print_debug_debug("The required model having id '$id_attr' is found.");

      # Read model information.
      print_debug_trace("Read engine tag.");
      my $engine = $model->first_child_text($xml_model_db_engine)
        or die("Models database doesn't contain '$xml_model_db_engine' tag for '$id_attr' model");
      print_debug_debug("The engine '$engine' is specified for the '$id_attr' model.");

      print_debug_trace("Read error tag.");
      my $error = $model->first_child_text($xml_model_db_error)
        or die("Models database doesn't contain '$xml_model_db_error' tag for '$id_attr' model");
      print_debug_debug("The error label '$error' is specified for the '$id_attr' model.");
        
      # Store hints for static verifier to be passed without any processing.
      print_debug_trace("Read hints tag.");
      my $hints = $model->first_child($xml_model_db_hints);

      print_debug_trace("Read array of kinds.");
      my @kinds;
      for (my $kind = $model->first_child($xml_model_db_kind)
        ; $kind
        ; $kind = $kind->next_elt($xml_model_db_kind))
      {
        push(@kinds, $kind->text);

        last if ($kind->is_last_child($xml_model_db_kind));
      }
      die("Models database doesn't contain '$xml_model_db_kind' tag for '$id_attr' model") 
        unless (scalar(@kinds));
      print_debug_debug("The kinds '@kinds' are specified for the '$id_attr' model.");

      print_debug_trace("Read file names.");
      my $files = $model->first_child($xml_model_db_files)
        or die("Models database doesn't contain '$xml_model_db_files' tag for '$id_attr' model");

      # Aspect file is optional but it's needed in the aspect mode.
      print_debug_trace("Read aspect file name.");
      my $aspect = $files->first_child_text($xml_model_db_files_aspect);
      print_debug_debug("The aspect file '$aspect' is specified for the '$id_attr' model") 
        if ($aspect);

      # Common file (either plain C or aspect file) must be always presented.
      print_debug_trace("Read common file name.");
      my $common = $files->first_child_text($xml_model_db_files_common)
        or die("Models database doesn't contain '$xml_model_db_files_common' tag for '$id_attr' model");
      print_debug_debug("The common file '$common' is specified for the '$id_attr' model."); 
      die("Common file '$ldv_model_dir/$common' doesn't exist (for '$id_attr' model)")
        unless (-f "$ldv_model_dir/$common");

      print_debug_trace("Obtain directory for the common model file to find headers there.");
      my $common_model_dir_abs = abs_path("$ldv_model_dir/$common")
        or die("Can't obtain absolute path of '$ldv_model_dir/$common'");
      my @common_model_dir_path = fileparse($common_model_dir_abs)
        or die("Can't find directory of file '$common_model_dir_abs'");
      $common_model_dir = $common_model_dir_path[1];
      print_debug_debug("The common file '$common' is placed in the directory '$common_model_dir'.");
      
      # Filter is optional as i think.
      print_debug_trace("Read filter file name.");
      my $filter = $files->first_child_text($xml_model_db_files_filter);
      print_debug_debug("The filter file '$filter' is specified for the '$id_attr' model") 
        if ($filter);
        
      print_debug_trace("Store model information into hash.");
      %ldv_model = (
        'id' => $id_attr, 
        'kind' => \@kinds,
        'aspect' => $aspect,
        'common' => $common,
        'filter' => $filter,
        'engine' => $engine,
        'error' => $error,
        'twig hints' => $hints);

      print_debug_trace("Check whether the '$id_attr' model kinds are specified correctly.");
      foreach my $kind (@kinds)
      {
        if ($kind eq 'aspect')
        {
          $kind_isaspect = 1;

          die("Models database doesn't contain '$xml_model_db_files_aspect' tag for '$id_attr' model")
            unless ($aspect);

          die("Aspect file '$ldv_model_dir/$aspect' doesn't exist (for '$id_attr' model)")
            unless (-f "$ldv_model_dir/$aspect");
            
          print_debug_debug("The aspect mode is used for '$id_attr' model");
          
          print($file_cmds_log "$log_cmds_aspect\n");
        }
        elsif ($kind eq 'plain')
        {
          $kind_isplain = 1;
          print_debug_debug("The plain mode is used for '$id_attr' model");

          print($file_cmds_log "$log_cmds_plain\n");
        }
        else
        {
          warn("Kind '$kind' can't be processed");
          exit($error_semantics);
        }
      }

      die("Don't specify both 'plain' and 'aspect' kind for '$id_attr' model")
        if ($kind_isaspect and $kind_isplain);

      die("Neither 'plain' nor 'aspect' kind was specified for '$id_attr' model")
        unless ($kind_isaspect or $kind_isplain);
      
      print_debug_debug("The model '$id_attr' information is processed successfully.");
      
      # Finish models iteration after the first one is found and processed.
      last;
    }
  }

  unless (%ldv_model)
  {
    warn("Specified through option model id '$opt_model_id' doesn't exist in models database");
    exit($error_semantics);
  }
}

sub get_opt()
{
  if (scalar(@ARGV) == 0)
  {
    warn("No options were specified through command-line. Please see help to " .
      "understand how to use this tool");
    help();
  }
  print_debug_trace("Options '@ARGV' were passed to the instrument through the command-line.");
  
  unless (GetOptions(
    'basedir|b=s' => \$opt_basedir,
    'cmdfile|c=s' => \$opt_cmd_xml_in,
    'cmdfile-out|o=s' => \$opt_cmd_xml_out,
    'help|h' => \$opt_help,
    'report=s' => \$opt_report_in,
    'report-out=s' => \$opt_report_out,
    'rule-model|m=s' => \$opt_model_id))
  {
    warn("Incorrect options may completely change the meaning! Please run " .
      "script with --help option to see how you may use this tool.");
    help();
  }

  help() if ($opt_help);

  print_debug_trace("Check whether report mode is activated.");
  if ($opt_report_in && $opt_report_out)
  {
    $report_mode = 1;
    print_debug_debug("Debug mode is active.");
    
    unless(-f $opt_report_in)
    {
      warn("File specified through option --report doesn't exist");
      help();
    }
    print_debug_debug("The input report file is '$opt_report_in'.");
    
    open($file_report_xml_out, '>', "$opt_report_out")
      or die("Couldn't open file '$opt_report_out' specified through option --report-out for write: $ERRNO");
    print_debug_debug("The output report file is '$opt_report_out'.");    

    unless ($opt_model_id) 
    {
      warn("You must specify option --model-id in command-line");
      help();
    }

    print_debug_debug("The model identifier is '$opt_model_id'."); 
    
    print_debug_debug("The command-line options are processed successfully.");
    return 0;
  }
  
  unless ($opt_basedir && $opt_cmd_xml_in && $opt_cmd_xml_out && $opt_model_id) 
  {
    warn("You must specify options --basedir, --cmd-xml-in, --cmd-xml-out, --model-id in command-line");
    help();
  }
  
  unless(-d $opt_basedir)
  {
    warn("Directory specified through option --basedir|-b doesn't exist");
    help();
  }
  print_debug_debug("The tool base directory is '$opt_basedir'."); 

  unless(-f $opt_cmd_xml_in)
  {
    warn("File specified through option --cmdfile|-c doesn't exist");
    help();
  }
  print_debug_debug("The commands input file is '$opt_cmd_xml_in'.");

  open($file_xml_out, '>', "$opt_cmd_xml_out")
    or die("Couldn't open file '$opt_cmd_xml_out' specified through option --cmdfile-out|-o for write: $ERRNO");
  print_debug_debug("The commands output file is '$opt_cmd_xml_out'.");

  print_debug_debug("The model identifier is '$opt_model_id'."); 
  
  print_debug_debug("The command-line options are processed successfully.");
}

sub help()
{
    print(STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to perform an instrumentation of 
    a source code with a model.

SYNOPSIS
  $PROGRAM_NAME [option...]

OPTIONS

  -b, --basedir <dir>
    <dir> is an absolute path to a tool working directory.

  -h, --help
    Print this help and exit with a syntax error.

  -c, --cmdfile <file>
    <file> is an absolute path to a xml file containing commands for 
    the tool.

  -m, --rule-model <id>
    <id> is a model id that specify a model to be instrumented with 
    a source code. This option is necessary to activate both modes.

  -o, --cmdfile-out <file>
    <file> is an absolute path to a xml file that will contain 
    commands generated by thetool.

  --report <file>
    <file> is an absolute path to a xml file containing a rcv report.
    This option is necessary to activate the report mode.

  --report-out <file>
    <file> is an absolute path to a xml file that will contain a 
    report generated by thetool. This option is necessary to activate 
    the report mode.
    
ENVIRONMENT VARIABLES

  LDV_KERNEL_RULES
    It's an optional option that points to an user models directory 
    that will be used instead of the standard one.

EOM

  exit($error_syntax);
}

sub prepare_files_and_dirs()
{
  print_debug_trace("Try to find global working directory.");  
  unless ($WORK_DIR)
  {
    warn("The work directory isn't specified by means of WORK_DIR environment variable.");
    help();      
  }
  unless (-d $WORK_DIR)
  {
    warn("The directory '$WORK_DIR' (work directory) doesn't exist");
    help();      
  }

  $tool_aux_dir = "$WORK_DIR/$tool_aux_dir/$opt_model_id";
  
  unless (-d $tool_aux_dir)
  {
    mkpath($tool_aux_dir)
      or die("Couldn't recursively create directory '$tool_aux_dir': $ERRNO");
  }
  print_debug_debug("The tool auxiliary working directory: '$tool_aux_dir'.");

  print_debug_trace("Try to open a commands log file.");    
  if ($report_mode)
  {
    open($file_cmds_log, '<', "$tool_aux_dir/$tool_cmds_log")
      or die("Couldn't open file '$tool_aux_dir/$tool_cmds_log' for read: $ERRNO");  
  }
  else
  {
    open($file_cmds_log, '>', "$tool_aux_dir/$tool_cmds_log")
      or die("Couldn't open file '$tool_aux_dir/$tool_cmds_log' for write: $ERRNO");  
  }
  print_debug_debug("The commands log file: '$tool_aux_dir/$tool_cmds_log'.");
  
  return 0 if ($report_mode);
    
  # LDV_HOME is obtained through directory of rule-instrumentor.
  # It is assumed that there is such organization of LDV_HOME directory:
  # /LDV_HOME/
  #   bin/
  #     rule_instrumentor.pl (this script)
  #   rule_instrumentor/
  #     aspectator/
  #       bin/
  #         symlinks to aspectator script, gcc, linker, c-backend and so on.
  print_debug_trace("Try to find the instrument absolute path.");
  $ldv_rule_instrumentor_abs = abs_path($0) 
    or die("Can't obtain absolute path of '$0'");
  print_debug_debug("The instrument absolute path is '$ldv_rule_instrumentor_abs'.");
  
  print_debug_trace("Try to find the instrument directory.");
  @ldv_rule_instrumentor_path = fileparse($ldv_rule_instrumentor_abs)
    or die("Can't find directory of file '$ldv_rule_instrumentor_abs'");
  $ldv_rule_instrumentor_dir = $ldv_rule_instrumentor_path[1];
  print_debug_debug("The instrument directory is '$ldv_rule_instrumentor_dir'.");
  
  print_debug_trace("Obtain the LDV_HOME as earlier as possible.");
  $ldv_rule_instrumentor_dir =~ /\/bin\/*$/;
  $LDV_HOME = $PREMATCH;
  unless(-d $LDV_HOME)
  {
    warn("The directory '$LDV_HOME' (LDV home directory) doesn't exist");
    help();
  }
  print_debug_debug("The LDV_HOME is '$LDV_HOME'.");
  
  print_debug_trace("Obtain the directory where all instrumentor auxiliary tools (such as aspectator) are placed.");
  $ldv_rule_instrumentor = "$LDV_HOME/rule-instrumentor";
  unless(-d $ldv_rule_instrumentor)
  {
    warn("Directory '$ldv_rule_instrumentor' (rule instrumentor directory) doesn't exist");
    help();
  }
  print_debug_debug("The instrument auxiliary tools directory is '$ldv_rule_instrumentor'.");
  
  # Directory contains all binaries needed by aspectator.
  $ldv_aspectator_bin_dir = "$ldv_rule_instrumentor/aspectator/bin";
  unless(-d $ldv_aspectator_bin_dir)
  {
    warn("Directory '$ldv_aspectator_bin_dir' (aspectator binaries directory) doesn't exist");
    help();
  }
  print_debug_debug("The aspectator binaries directory is '$ldv_aspectator_bin_dir'.");
  
  # Aspectator script.
  $ldv_aspectator = "$ldv_aspectator_bin_dir/compiler";
  unless(-f $ldv_aspectator)
  {
    warn("File '$ldv_aspectator' (aspectator) doesn't exist");
    help();
  }
  print_debug_debug("The aspectator script (compiler) is '$ldv_aspectator'.");
  
  # C backend.
  $ldv_c_backend = "$ldv_aspectator_bin_dir/c-backend";
  unless(-f $ldv_c_backend)
  {
    warn("File '$ldv_c_backend' (LLVM C backend) doesn't exist");
    help();
  }
  print_debug_debug("The C backend is '$ldv_c_backend'.");
  
  # GCC compiler with aspectator extensions that is used by aspectator
  # script.
  $ldv_gcc = "$ldv_aspectator_bin_dir/compiler-core";
  unless(-f $ldv_gcc)
  {
    warn("File '$ldv_gcc' (GCC compiler) doesn't exist");
    help();
  }
  print_debug_debug("The GCC compiler (compiler core) is '$ldv_gcc'.");
  
  # Linker.
  $ldv_linker = "$ldv_aspectator_bin_dir/linker";
  unless(-f $ldv_linker)
  {
    warn("File '$ldv_linker' (LLVM linker) doesn't exist");
    help();
  }
  print_debug_debug("The linker is '$ldv_linker'.");
  
  # Use environment variable for models instead of standard placement in LDV_HOME.
  if ($LDV_KERNEL_RULES)
  {
    $ldv_model_dir = $LDV_KERNEL_RULES;
    print_debug_debug("The models directory specified through 'LDV_KERNEL_RULES' environment variable is '$ldv_model_dir'.");
  }
  else
  {
    $ldv_model_dir = "$LDV_HOME/kernel-rules";
    print_debug_debug("The models directory is '$ldv_model_dir'.");
  }

  print_debug_trace("Check whether the models are installed properly.");
  unless(-d $ldv_model_dir)
  {
    warn("Directory '$ldv_model_dir' (kernel rules models) doesn't exist");
    help();
  }
  unless(-f "$ldv_model_dir/$ldv_model_db_xml")
  {
    warn("Directory '$ldv_model_dir' doesn't contain models database xml file '$ldv_model_db_xml'");
    help();
  }
  print_debug_debug("The models database xml file is '$ldv_model_db_xml'.");

  print_debug_trace("Copy the models directory '$ldv_model_dir' to the base directory '$opt_basedir'.");
  rcopy($ldv_model_dir, "$opt_basedir/" . basename($ldv_model_dir))
    or die("Can't copy directory '$ldv_model_dir' to directory '$opt_basedir'");

  # Change the models directory name.
  $ldv_model_dir = "$opt_basedir/" . basename($ldv_model_dir);
  print_debug_debug("The models directory is '$ldv_model_dir'.");
  
  print_debug_debug("Files and directories are checked and prepared successfully.");
}

sub print_debug_normal($)
{
  my $message = shift;
  
  if ($debug_normal)
  {
    print($debug_stream "$debug_name: NORMAL: $message\n");
  }
}

sub print_debug_info($)
{
  my $message = shift;
  
  if ($debug_info)
  {
    print($debug_stream "$debug_name: INFO: $message\n");
  }
}

sub print_debug_debug($)
{
  my $message = shift;
  
  if ($debug_debug)
  {
    print($debug_stream "$debug_name: DEBUG: $message\n");
  }
}

sub print_debug_trace($)
{
  my $message = shift;
  
  if ($debug_trace)
  {
    print($debug_stream "$debug_name: TRACE: $message\n");
  }
}

sub print_debug_all($)
{
  my $message = shift;
  
  if ($debug_all)
  {
    print($debug_stream "$debug_name: ALL: $message\n");
  }
}

sub process_cmd_cc()
{
  if ($kind_isaspect)
  {
    # On each cc command we run aspectator on corresponding file with 
    # corresponding model aspect and options. Also add -I option with 
    # models directory needed to find appropriate headers for usual aspect.
    print_debug_debug("Process the cc command using usual aspect.");
    # Specify needed and specic environment variables for the aspectator.
    $ENV{$ldv_aspectator_gcc} = $ldv_gcc;
    $ENV{$ldv_no_quoted} = 1;
    $ENV{LDV_QUIET} = 1 unless ($debug_trace);
    my @args = ($ldv_aspectator, ${$cmd{'ins'}}[0], "$ldv_model_dir/$ldv_model{'aspect'}", @{$cmd{'opts'}}, "-I$common_model_dir");
    
    print_debug_trace("Go to the build directory to execute cc command.");
    chdir($cmd{'cwd'})
      or die("Can't change directory to '$cmd{'cwd'}'");

    print_debug_info("Execute the command '@args'");
    system(@args) == 0 or die("System '@args' call failed: $ERRNO");

    # Unset special environments variables.
    delete($ENV{'LDV_QUITE'});
    delete($ENV{$ldv_no_quoted});
    delete($ENV{$ldv_aspectator_gcc});
    
    print_debug_trace("Go to the initial directory.");
    chdir($tool_working_dir)
      or die("Can't change directory to '$tool_working_dir'");

    die("Something wrong with aspectator: it doesn't produce file '${$cmd{'ins'}}[0]$llvm_bitcode_suffix'") 
      unless (-f "${$cmd{'ins'}}[0]$llvm_bitcode_suffix");
    print_debug_debug("The aspectator produces the usual bitcode file '${$cmd{'ins'}}[0]$llvm_bitcode_suffix'");

    # After aspectator work we obtain files ${$cmd{'ins'}}[0]$llvm_bitcode_suffix with llvm
    # object code. Copy them to $cmd{'out'}$llvm_bitcode_usual_suffix files.
    print_debug_trace("Copy the usual bitcode file.");
    mv("${$cmd{'ins'}}[0]$llvm_bitcode_suffix", "$cmd{'out'}$llvm_bitcode_usual_suffix") 
      or die("Can't copy file '${$cmd{'ins'}}[0]$llvm_bitcode_suffix' to file '$cmd{'out'}$llvm_bitcode_usual_suffix': $ERRNO");
    print_debug_debug("The usual bitcode file is '$cmd{'out'}$llvm_bitcode_usual_suffix'.");

    # Also do this with general aspect. Don't forget to add -I option with 
    # models directory needed to find appropriate headers for common aspect.
    print_debug_debug("Process the cc command using general aspect.");
    $ENV{$ldv_aspectator_gcc} = $ldv_gcc;
    $ENV{$ldv_no_quoted} = 1;
    $ENV{LDV_QUIET} = 1 unless ($debug_trace);
    @args = ($ldv_aspectator, ${$cmd{'ins'}}[0], "$ldv_model_dir/$ldv_model{'general'}", @{$cmd{'opts'}}, "-I$common_model_dir");

    print_debug_trace("Go to the build directory to execute cc command.");    
    chdir($cmd{'cwd'})
      or die("Can't change directory to '$cmd{'cwd'}'");
      
    print_debug_info("Execute the command '@args'");
    system(@args) == 0 
      or die("System '@args' call failed: $ERRNO");

    # Unset special environments variables.
    delete($ENV{'LDV_QUITE'});
    delete($ENV{$ldv_no_quoted});
    delete($ENV{$ldv_aspectator_gcc});
    
    die("Something wrong with aspectator: it doesn't produce file '${$cmd{'ins'}}[0]$llvm_bitcode_suffix'") 
      unless (-f "${$cmd{'ins'}}[0]$llvm_bitcode_suffix");
    print_debug_debug("The aspectator produces the usual bitcode file '${$cmd{'ins'}}[0]$llvm_bitcode_suffix'");

    # After aspectator work we obtain files ${$cmd{'ins'}}[0]$llvm_bitcode_suffix with llvm
    # object code. Copy them to $cmd{'out'}$llvm_bitcode_general_suffix files.
    print_debug_trace("Copy the general bitcode file.");
    mv("${$cmd{'ins'}}[0]$llvm_bitcode_suffix", "$cmd{'out'}$llvm_bitcode_general_suffix") 
      or die("Can't copy file '${$cmd{'ins'}}[0]$llvm_bitcode_suffix' to file '$cmd{'out'}$llvm_bitcode_general_suffix': $ERRNO");
    print_debug_debug("The general bitcode file is '$cmd{'out'}$llvm_bitcode_general_suffix'.");
    
    print_debug_trace("Go to the initial directory.");
    chdir($tool_working_dir)
      or die("Can't change directory to '$tool_working_dir'");
  
    return 0;
  }
}

sub process_cmd_ld()
{
  my $ischeck = $cmd{'check'} eq 'true';

  if ($kind_isaspect)
  {
    print_debug_debug("Prepare a C file to be checked for the ld command marked with 'check = \"true\"'.");
    
    if ($ischeck)
    {  
      # On each ld command we run llvm linker for all input files together to 
      # produce one linked file. Note that excactly one file to be linked must 
      # be generally (i.e. with usual and common aspects) instrumented. We 
      # choose the first one here. Other files must be usually instrumented.
      my @ins = ("${$cmd{'ins'}}[0]$llvm_bitcode_general_suffix", map("$_$llvm_bitcode_usual_suffix", @{$cmd{'ins'}}[1..$#{$cmd{'ins'}}]));
      my @args = ($ldv_linker, @llvm_linker_opts, @ins, '-o', "$cmd{'out'}$llvm_bitcode_linked_suffix");

      print_debug_trace("Go to the build directory to execute ld command.");
      chdir($cmd{'cwd'})
        or die("Can't change directory to '$cmd{'cwd'}'");
        
      print_debug_info("Execute the command '@args'");
      system(@args) == 0 or die("System '@args' call failed: $ERRNO");
      
      print_debug_trace("Go to the initial directory.");
      chdir($tool_working_dir)
        or die("Can't change directory to '$tool_working_dir'");

      die("Something wrong with linker: it doesn't produce file '$cmd{'out'}$llvm_bitcode_linked_suffix'") 
        unless (-f "$cmd{'out'}$llvm_bitcode_linked_suffix");
      print_debug_debug("The linker produces the linked bitcode file '$cmd{'out'}$llvm_bitcode_linked_suffix'");

      # Make name for c file corresponding to the linked one.
      my $c_out = "$cmd{'out'}$llvm_bitcode_linked_suffix$llvm_c_backend_suffix";

      # Linked file is converted to c by means of llvm c backend.
      @args = ($ldv_c_backend, @llvm_c_backend_opts, "$cmd{'out'}$llvm_bitcode_linked_suffix", '-o', $c_out);
      print_debug_info("Execute the command '@args'");
      system(@args) == 0 or die("System '@args' call failed: $ERRNO");

      die("Something wrong with aspectator: it doesn't produce file '$c_out'") 
        unless (-f "$c_out");
      print_debug_debug("The C backend produces the C file '$c_out'");

      print_debug_trace("Print the corresponding commands to the output xml file."); 
      $xml_writer->startTag('cc', 'id' => "$cmd{'id'}$id_cc_llvm_suffix");
      $xml_writer->dataElement('cwd' => $cmd{'cwd'});
      $xml_writer->dataElement('in' => $c_out);
      # Use here the first input file name to relate with corresponding ld 
      # command.
      $xml_writer->dataElement('out' => ${$cmd{'ins'}}[0]);
      $xml_writer->dataElement('engine' => $ldv_model{'engine'});
      # Close the cc tag.
      $xml_writer->endTag();

      $xml_writer->startTag('ld', 'id' => "$cmd{'id'}$id_ld_llvm_suffix");
      $xml_writer->dataElement('cwd' => $cmd{'cwd'});
      $xml_writer->dataElement('in' => ${$cmd{'ins'}}[0]);
      $xml_writer->dataElement('out' => "$cmd{'out'}$llvm_bitcode_linked_suffix");
      $xml_writer->dataElement('engine' => $ldv_model{'engine'});

      foreach my $entry_point (@{$cmd{'entry point'}})
      {
        $xml_writer->dataElement('main' => $entry_point);
      }

      $xml_writer->dataElement('error' => $ldv_model{'error'});
    
      # Copy static verifier hints as them.
      my $twig_hints = $ldv_model{'twig hints'}->copy->sprint;
      $xml_writer->raw($twig_hints);
    
      # Close the ld tag.
      $xml_writer->endTag();
    }
    # Otherwise create two linked variants: with and without general bytecode 
    # file.
    else
    {
      print_debug_debug("Prepare two linked bytecode files with and without general bytecode for the ld command marked with 'check = \"true\"'.");

      # On each ld command we run llvm linker for all input files together to 
      # produce one linked file. Also produce linked file that contains excactly 
      # one file generally (i.e. with usual and common aspects) instrumented. 
      # We choose the first one here. Other files must be usually instrumented.
      my @ins_usual = map("$_$llvm_bitcode_usual_suffix", @{$cmd{'ins'}});
      my @args_usual = ($ldv_linker, @llvm_linker_opts, @ins_usual, '-o', "$cmd{'out'}$llvm_bitcode_linked_suffix");
      my @ins_general = ("${$cmd{'ins'}}[0]$llvm_bitcode_general_suffix", map("$_$llvm_bitcode_usual_suffix", @{$cmd{'ins'}}[1..$#{$cmd{'ins'}}]));
      my @args_general = ($ldv_linker, @llvm_linker_opts, @ins_general, '-o', "$cmd{'out'}$llvm_bitcode_general_suffix");

      print_debug_trace("Go to the build directory to execute ld command.");
      chdir($cmd{'cwd'})
        or die("Can't change directory to '$cmd{'cwd'}'");
        
      print_debug_info("Execute the command '@args_usual'");
      system(@args_usual) == 0 or die("System '@args_usual' call failed: $ERRNO");
      print_debug_info("Execute the command '@args_general'");      
      system(@args_general) == 0 or die("System '@args_general' call failed: $ERRNO");

      print_debug_trace("Go to the initial directory.");
      chdir($tool_working_dir)
        or die("Can't change directory to '$tool_working_dir'");

      die("Something wrong with linker: it doesn't produce file '$cmd{'out'}$llvm_bitcode_linked_suffix'") 
        unless (-f "$cmd{'out'}$llvm_bitcode_linked_suffix");
      print_debug_debug("The linker produces the linked bitcode file '$cmd{'out'}$llvm_bitcode_linked_suffix'");
      die("Something wrong with linker: it doesn't produce file '$cmd{'out'}$llvm_bitcode_general_suffix'") 
        unless (-f "$cmd{'out'}$llvm_bitcode_general_suffix");
      print_debug_debug("The linker produces the generally linked bitcode file '$cmd{'out'}$llvm_bitcode_general_suffix'");
    }
    
    return 0;
  }
}

sub process_cmds()
{
  print_debug_trace("Read commands input xml file '$opt_cmd_xml_in'.");
  $xml_twig->parsefile("$opt_cmd_xml_in");

  # To print out user friendly xml output.  
  $xml_twig->set_pretty_print('indented');

  print_debug_trace("Read xml root tag.");
  my $cmd_root = $xml_twig->root;

  print_debug_trace("Obtain all commands.");
  my @cmds = $cmd_root->children;

  print_debug_trace("Iterate over all commands to execute them and write output xml file.");
  foreach my $cmd (@cmds)
  {
    # At the beginning instrumentor basedir must be specified.
    if ($cmd->gi eq $xml_cmd_basedir)
    {
      $cmd_basedir = $cmd->text;
      print_debug_debug("The base directory '$cmd_basedir' is specified.");

      if ($kind_isplain)
      {
        print_debug_trace("Use the tool base directory '$opt_basedir' instead of the specified one in the plain mode.");
        $cmd->set_text($opt_basedir);
        $cmd->print($file_xml_out);
      }
    }
    # Interpret cc and ld commands.
    elsif ($cmd->gi eq $xml_cmd_cc or $cmd->gi eq $xml_cmd_ld)
    {
      die("A base directory isn't specified in input commands xml file")
        unless ($cmd_basedir);

      # General commands section.
      print_debug_trace("Read id for some command.");
      my $id_attr = $cmd->att($xml_cmd_attr_id)
        or die("The input commands xml file doesn't contain '$xml_cmd_attr_id' attribute for some command");
      print_debug_debug("Begin processing of the command '" . $cmd->gi . "' having id '$id_attr'.");
      
      print_debug_trace("Read current working directory.");
      my $cwd = $cmd->first_child($xml_cmd_cwd)
        or die("The input commands xml file doesn't contain '$xml_cmd_cwd' tag for '$id_attr' command"); 
      my $cwd_text = $cwd->text;
      die("The input commands xml file specifies directory '$cwd_text' that doesn't exist for '$id_attr' command")
        unless (-d $cwd_text);
      print_debug_debug("The specified current working directory is '$cwd_text'.");

      print_debug_trace("Read output file name.");
      my $out = $cmd->first_child($xml_cmd_out)
        or die("The input commands xml file doesn't contain '$xml_cmd_out' tag for '$id_attr' command");
      my $out_text = $out->text;
      print_debug_debug("The output file is '$out_text'.");
      
      # Attribute that says whether file must be checked or not. Note that there
      # may be not such attribute for the given command at all.
      print_debug_trace("Read check.");
      my $check_attr = $out->att($xml_cmd_attr_check);
      my $check_text = '';
      # If check attribute was specified and it's value is true, then use 
      # 'true' value in future.
      if ($check_attr and $check_attr eq 'true')
      {
        $check_text = 'true';     
      }
      # Otherwise use 'false' value.
      else
      {
        $check_text = 'false';
      }
      print_debug_debug("The attribute check leads to '$check_text' check (this has sence just for ld command).");
      
      print_debug_trace("Read array of input file names.");
      my @ins;
      my @ins_text;
      for (my $in = $cmd->first_child($xml_cmd_in)
        ; $in
        ; $in = $in->next_elt($xml_cmd_in))
      {
        push(@ins, $in);
        push(@ins_text, $in->text);

        last if ($in->is_last_child($xml_cmd_in));
      }
      die("The input commands xml file doesn't contain '$xml_cmd_in' tag for '$id_attr' command")
        unless (scalar(@ins));
      print_debug_debug("The '@ins_text' input files are specified.");
       
      print_debug_trace("Replace previous base directory prefix with the instrument one.");
      @ins_text = map( 
      {
        my $in_text = $_;

        $in_text =~ s/^$cmd_basedir/$opt_basedir/;

        # Input files for cc command must exist.
        if ($cmd->gi eq $xml_cmd_cc)
        {
          die("The input commands xml file specifies file '$in_text' that doesn't exist for '$id_attr' command")
            unless (-f $in_text);
        }

        $in_text;
      } @ins_text);
      print_debug_debug("The input files with replaced base directory are '@ins_text'."); 
      my @ins_text_copy = @ins_text;
      for (my $in = $cmd->first_child($xml_cmd_in)
        ; $in
        ; $in = $in->next_elt($xml_cmd_in))
      {
        $in->set_text(shift(@ins_text_copy));

        last if ($in->is_last_child($xml_cmd_in));
      }   
      $out_text =~ s/^$cmd_basedir/$opt_basedir/;
      $out->set_text($out_text);
      print_debug_debug("The output file with replaced base directory is '$out_text'.");

      print_debug_trace("Get on and off options.");
      my @on_opts;
      my @off_opts;
      if ($kind_isaspect)
      {
        @on_opts = @gcc_aspect_on_opts;
        @off_opts = @gcc_aspect_off_opts;
      }
      elsif ($kind_isplain)
      {
        @on_opts = @gcc_plain_on_opts;
        @off_opts = @gcc_plain_off_opts;
      }
      
      print_debug_trace("Read an array of options and exclude the unwanted ones ('@off_opts').");
      my @opts;
      for (my $opt = $cmd->first_child($xml_cmd_opt)
        ; $opt
        ; $opt = $opt->next_elt($xml_cmd_opt))
      {
        my $opt_text = $opt->text;

        # Exclude options for the gcc compiler.
        foreach my $off_opt (@off_opts)
        {
          if ($opt_text =~ /^$off_opt$/)
          {
            print_debug_debug("Exclude the option '$opt_text' for the '$id_attr' command.");
            $opt_text = '';
            last;
          }
        }

        next unless ($opt_text);

        push(@opts, $opt_text);

        last if ($opt->is_last_child($xml_cmd_opt));
      }
      
      print_debug_debug("Add wanted options '@on_opts'.");
      push(@opts, @on_opts);
      
      print_debug_normal("The options to be passed to the gcc compiler are '@opts'.");

      # For the plain mode just copy and modify a bit input xml.
      if ($kind_isplain)
      {
        print_debug_debug("The command '$id_attr' is specifically processed for the plain mode.");  
        # Add an additional input model file, error and hints tags for aneach ld 
        # command.
        if ($cmd->gi eq $xml_cmd_ld)
        {
          # Replace the first object file to be linked with the object file 
          # containing the common model.  
          print_debug_trace("For the ld command change the first input file.");
          my $in = $cmd->first_child($xml_cmd_in);
          $in->set_text($in->text . $common_o_suffix);
          
          print_debug_trace("For the ld command add error tag.");
          my $xml_error_tag = new XML::Twig::Elt('error', $ldv_model{'error'});
          $xml_error_tag->paste('last_child', $cmd);

          print_debug_trace("For the ld command copy hints as them.");
          my $twig_hints = $ldv_model{'twig hints'}->copy;
          $twig_hints->paste('last_child', $cmd);
        }
        
        # Add engine tag for both cc and ld commands.
        if ($cmd->gi eq $xml_cmd_ld or $cmd->gi eq $xml_cmd_cc)
        {
          print_debug_trace("For the both cc and ld commands add engine.");
          my $xml_engine_tag = new XML::Twig::Elt('engine', $ldv_model{'engine'});
          $xml_engine_tag->paste('last_child', $cmd);
        }

        # Exchange the existing options with the processed ones.
        my @opts_to_del;
        for (my $opt = $cmd->first_child($xml_cmd_opt)
          ; $opt
          ; $opt = $opt->next_elt($xml_cmd_opt))
        {
          push(@opts_to_del, $opt);
          last if ($opt->is_last_child($xml_cmd_opt));
        }
        foreach (@opts_to_del)
        {
          $_->delete();
        }
        foreach my $opt (@opts)
        {
          my $xml_opt_tag = new XML::Twig::Elt($xml_cmd_opt, $opt);
          $xml_opt_tag->paste('last_child', $cmd);          
        }

        # Add -I option with common model dir to find appropriate headers. Note
        # that it also add for a duplicated command.
        if ($cmd->gi eq $xml_cmd_cc)
        {
          print_debug_trace("For the cc command add '$common_model_dir' directory to be searched for common model headers.");  
          my $common_model_opt = new XML::Twig::Elt($xml_cmd_opt => "-I$common_model_dir");
          $common_model_opt->paste('last_child', $cmd);
        }
        
        print_debug_trace("Print the modified command.");
        $cmd->print($file_xml_out);

        if ($cmd->gi eq $xml_cmd_cc)
        {
          print_debug_debug("Duplicate an each cc command with the one containing a common model.");
          my $common_model_cc = $cmd->copy;
          
          print_debug_trace("Change an id attribute.");
          $common_model_cc->set_att($xml_cmd_attr_id => $cmd->att($xml_cmd_attr_id) . $id_common_model_suffix);

          print_debug_trace("Concatenate a common model with the first input file.");
          my $in = $common_model_cc->first_child($xml_cmd_in);
          my $in_file = $in->text;
          open(my $file_with_common_model, '>', "$in_file$common_c_suffix")
            or die("Couldn't open file '$in_file$common_c_suffix' for write: $ERRNO");
          cat($in_file, $file_with_common_model)
            or die("Can't concatenate file '$in_file' with file '$in_file$common_c_suffix'");
          cat("$ldv_model_dir/$ldv_model{'common'}", $file_with_common_model)
            or die("Can't concatenate file '$ldv_model_dir/$ldv_model{'common'}' with file '$in_file$common_c_suffix'");
          close($file_with_common_model) 
            or die("Couldn't close file '$in_file$common_c_suffix': $ERRNO\n");
          $in->set_text("$in_file$common_c_suffix");
          print_debug_debug("The file concatenated with the common model is '$in_file$common_c_suffix'.");
          
          print_debug_trace("Add suffix for output file of the duplicated cc command.");
          my $out = $common_model_cc->first_child($xml_cmd_out);
          $out->set_text($out->text . $common_o_suffix);
        
          print_debug_trace("Print the duplicated cc command.");
          $common_model_cc->print($file_xml_out);
        }

        print_debug_trace("Log information on the '$id_attr' command execution status.");
        if ($cmd->gi eq $xml_cmd_cc)
        {
          $cmds_status{$out_text} = $id_attr;
          print($file_cmds_log "$log_cmds_cc:$log_cmds_ok:$id_attr\n");
        }
        elsif ($cmd->gi eq $xml_cmd_ld)
        {
          # Check whether all input files are processed sucessfully.
          my $status = 0;

          foreach my $in_text (@ins_text)
          {
            if (defined($cmds_status{$in_text}))
            {
              $status = 1;
            }
            else
            {
              $status = 0;
              last;
            }
          }
          
          if ($status)
          {
            $cmds_status{$out_text} = $id_attr;
            print($file_cmds_log "$log_cmds_ld:$log_cmds_ok:$id_attr");
            print($file_cmds_log "*") if ($check_text eq 'true');
            print($file_cmds_log "\n");
          }
        }
        
        print_debug_debug("Finish processing of the command having id '$id_attr'.");
        next;
      }
      
      print_debug_debug("The command '$id_attr' is specifically processed for the aspect mode.");  
      $out_text = $out->text;

      print_debug_trace("Read an array of input files.");
      @ins_text = ();
      for (my $in = $cmd->first_child($xml_cmd_in)
        ; $in
        ; $in = $in->next_elt($xml_cmd_in))
      {
        push(@ins_text, $in->text);

        last if ($in->is_last_child($xml_cmd_in));
      }

      print_debug_trace("Store the current command information."); 
      %cmd = (
        'id' => $id_attr, 
        'cwd' => $cwd_text,
        'ins' => \@ins_text,
        'out' => $out_text,
        'check' => $check_text,
        'opts' => \@opts);

      undef($cmd{'entry point'});

      # cc command doesn't contain any specific settings.
      if ($cmd->gi eq $xml_cmd_cc)
      {
        print_debug_debug("The cc command '$id_attr' is especially specifically processed for the aspect mode.");  
        
        my $status = process_cmd_cc();
        
        if ($status)
        {
          print($file_cmds_log "$log_cmds_cc:$log_cmds_fail:$id_attr\n");  
        }
        else
        {
          print_debug_trace("Log information on the '$id_attr' command execution status.");
          $cmds_status{$out_text} = $id_attr;
          print($file_cmds_log "$log_cmds_cc:$log_cmds_ok:$id_attr\n");
        }
      }

      # ld command additionaly contains array of entry points.
      if ($cmd->gi eq $xml_cmd_ld)
      {
        print_debug_trace("Read an array of entry points.");
        my @entry_points;
        for (my $entry_point = $cmd->first_child($xml_cmd_entry_point)
          ; $entry_point
          ; $entry_point = $entry_point->next_elt($xml_cmd_entry_point))
        {
          push(@entry_points, $entry_point->text);

          last if ($entry_point->is_last_child($xml_cmd_entry_point));
        }
        $cmd{'entry point'} = \@entry_points;
        print_debug_debug("The ld command entry points are '@entry_points'.");
        
        print_debug_debug("The ld command '$id_attr' is especially specifically processed for the aspect mode.");  
        my $status = process_cmd_ld();
        
        if ($status)
        {
          print($file_cmds_log "$log_cmds_ld:$log_cmds_fail:$id_attr\n");  
        }
        else
        {
          print_debug_trace("Log information on the '$id_attr' command execution status.");
          # Check whether all input files are processed sucessfully.
          $status = 0;

          foreach my $in_text (@ins_text)
          {
            if (defined($cmds_status{$in_text}))
            {
              $status = 1;
            }
            else
            {
              $status = 0;
              last;
            }
          }
          
          if ($status)
          {
            $cmds_status{$out_text} = $id_attr;
            print($file_cmds_log "$log_cmds_ld:$log_cmds_ok:$id_attr");
            print($file_cmds_log $log_cmds_check) if ($check_text eq 'true');
            print($file_cmds_log "\n");
          }
          else
          {
            print($file_cmds_log "$log_cmds_ld:$log_cmds_fail:$id_attr\n");  
          }
        }
      }
      
      print_debug_debug("Finish processing of the command having id '$id_attr'.");
    }
    # Interpret other commands.
    else
    {
      warn("The input xml file contains the command '" . $cmd->gi . "' that can't be interpreted");
      exit($error_semantics);
    }
  }
}

sub process_report()
{
  print_debug_trace("Obtain mode.");
  my $mode = <$file_cmds_log>;
  chomp($mode);
  die("Can't get mode from the commands log file") 
    unless ($mode);
  
  my $mode_isaspect = 0;
  my $mode_isplain = 0;
  
  if ($mode eq $log_cmds_aspect)
  {
    $mode_isaspect = 1;
    print_debug_debug("The aspect mode is specified.");
  }
  elsif ($mode eq $log_cmds_plain)
  {
    $mode_isplain = 1;
    print_debug_debug("The plain mode is specified.");
  }
  else
  {
    warn("Can't parse mode '$mode' in the commands log file");
    exit($error_semantics);
  }
  
  my %cmds_log;
  my @cmds_id;
  
  print_debug_trace("Process commands log.");
  foreach my $cmd_log (<$file_cmds_log>)
  {
    chomp($cmd_log);
    print_debug_trace("Process the '$cmd_log' command log.");
    # Each command log has form: 'cmd_name:ok:cmd_id' when it's correctly 
    # processed by the rule instrumentor and 'cmd_name:fail:cmd_id' otherwise.
    $cmd_log =~ /([^:]+):([^:]+):/;
    my $cmd_name = $1;
    my $cmd_status = $2;
    die("The command id isn't specified") unless (my $id = $POSTMATCH);
    print_debug_debug("The commmand log id is '$id'.");
    my $check = 0;
    if ($id =~ /$log_cmds_check$/)
    {
      $check = 1;
      $id = $PREMATCH;   
    }
    die("The command id isn't unique") if (defined($cmds_log{$id}));
    die("The command name '$cmd_name' isn't correct") 
      unless ($cmd_name eq $log_cmds_cc or $cmd_name eq $log_cmds_ld);
    print_debug_debug("The commmand log command name is '$cmd_name'.");
    die("The command execution status '$cmd_status' isn't correct") 
      unless ($cmd_status eq $log_cmds_ok or $cmd_status eq $log_cmds_fail);
    print_debug_debug("The commmand log command execution status is '$cmd_status'.");
    
    $cmds_log{$id} = {
      'cmd name' => $cmd_name, 
      'cmd status' => $cmd_status, 
      'check' => $check
    };
      
    push(@cmds_id, $id);
  }

  print_debug_trace("Read the report file '$opt_report_in'.");
  my %reports;
  $xml_twig->parsefile("$opt_report_in");
  my $report_root = $xml_twig->root;

  print_debug_trace("Obtain all ld reports.");
  my @reports = $report_root->children;

  print_debug_trace("Iterate over the all ld reports");
  foreach my $report (@reports)
  {
    if ($report->gi eq $xml_report_ld)
    {
      print_debug_trace("Read ld command reference.");
      my $ref_id_attr = $report->att($xml_report_attr_ref)
        or die("The report file doesn't contain '$xml_report_attr_ref' attribute for some ld command");
      print_debug_debug("Begin processing of the command '" . $report->gi . "' having id reference '$ref_id_attr'.");

      print_debug_trace("Read ld main.");
      my $main_attr = $report->att($xml_report_attr_main)
        or die("The report file doesn't contain '$xml_report_attr_main' attribute for command having id reference '$ref_id_attr'");
      print_debug_debug("The command main is '$main_attr'.");

      print_debug_trace("Read verdict.");
      my $verdict = $report->first_child_text($xml_report_verdict)
        or die("The report file doesn't contain '$xml_report_verdict' tag for '$ref_id_attr, $main_attr' command");
      print_debug_debug("The verdict is '$verdict'.");

      print_debug_trace("Read trace.");
      my $trace = $report->first_child_text($xml_report_trace)
        or die("The report file doesn't contain '$xml_report_trace' tag for '$ref_id_attr, $main_attr' command");
      print_debug_debug("The trace is '$trace'.");

      print_debug_trace("Read rcv report section.");
      my $rcv = $report->first_child($xml_report_rcv)
        or die("The report file doesn't contain '$xml_report_rcv' tag for '$ref_id_attr, $main_attr' command");

      print_debug_trace("Read rcv status.");
      my $rcv_status = $rcv->first_child_text($xml_report_status)
        or die("The report file doesn't contain '$xml_report_status' tag for '$ref_id_attr, $main_attr' command");
      print_debug_debug("The rcv status is '$rcv_status'.");                 

      print_debug_trace("Read rcv time.");
      my $rcv_time = $rcv->first_child_text($xml_report_time)
        or die("The report file doesn't contain '$xml_report_time' tag for '$ref_id_attr, $main_attr' command");
      print_debug_debug("The rcv time is '$rcv_time'.");                 

      print_debug_trace("Read rcv description.");
      my $rcv_desc = $rcv->first_child_text($xml_report_desc)
        or die("The report file doesn't contain '$xml_report_desc' tag for '$ref_id_attr, $main_attr' command");
      print_debug_debug("The rcv description is '$rcv_desc'.");
      
      $reports{$ref_id_attr}{$main_attr} = {
        'verdict' => $verdict, 
        'trace' => $trace, 
        'rcv status' => $rcv_status,
        'rcv time' => $rcv_time,
        'rcv description' => $rcv_desc
      };               
    }
    # Interpret other commands.
    else
    {
      warn("The report file contains '" . $report->gi . "' that can't be interpreted");
      exit($error_semantics);
    }
  }
  
  print_debug_trace("Print the standard xml file header.");
  print($file_report_xml_out "$xml_header\n");
  
  print_debug_trace("Prepare a xml writer, open a root node tag and print a base directory in the report mode.");  
  $xml_writer = new XML::Writer(OUTPUT => $file_report_xml_out, NEWLINES => 1, UNSAFE => 1);
  $xml_writer->startTag($xml_report_root);

  print_debug_trace("Iterate over all commands from the log and build reports for them.");
  foreach my $cmd_id (@cmds_id)
  {
    if ($cmds_log{$cmd_id}{'cmd name'} eq $log_cmds_cc)
    {
      print_debug_debug("Build a report for the '$cmd_id' cc command.");
      $xml_writer->startTag($xml_report_cc, $xml_report_attr_ref => $cmd_id, $xml_report_attr_model => $opt_model_id);
      $xml_writer->startTag($xml_report_rule_instrumentor); 

      if ($cmds_log{$cmd_id}{'cmd status'} eq $log_cmds_ok)
      {
        $xml_writer->dataElement($xml_report_status => $xml_report_status_ok);
      }
      else
      {
        $xml_writer->dataElement($xml_report_status => $xml_report_status_fail);  
      }

      $xml_writer->dataElement($xml_report_time => 0);
      $xml_writer->dataElement($xml_report_desc => '');
            
      # Close the rule instrumentor tag.
      $xml_writer->endTag();
      # Close the cc tag.
      $xml_writer->endTag();
    }
    else
    {
      print_debug_debug("Build a report for the '$cmd_id' ld command.");
      if ($cmds_log{$cmd_id}{'check'})
      {
        print_debug_debug("The '$cmd_id' ld command has 'check=true'.");
        print_debug_trace("Try to find the corresponding rcv report.");
        
        # ld commands have additional suffix in the aspect mode.
        my $rule_instrument_cmd_id = $cmd_id;
        if ($mode_isaspect)
        {
          $rule_instrument_cmd_id .= $id_ld_llvm_suffix;
        }
        die("rcv doesn't produce a report for the '$cmd_id' ('$rule_instrument_cmd_id') ld command")
          unless ($reports{$rule_instrument_cmd_id});
        
        print_debug_trace("Iterate over all mains specific reports.");
        foreach my $main_id (keys(%{$reports{$rule_instrument_cmd_id}}))
        {
          print_debug_debug("Process the '$main_id' main report.");
          $xml_writer->startTag($xml_report_ld, $xml_report_attr_ref => $cmd_id, $xml_report_attr_main => $main_id, $xml_report_attr_model => $opt_model_id);

          $xml_writer->dataElement($xml_report_verdict => $reports{$rule_instrument_cmd_id}{$main_id}{'verdict'});
          $xml_writer->dataElement($xml_report_trace => $reports{$rule_instrument_cmd_id}{$main_id}{'trace'});
          
          print_debug_trace("Build a rcv report.");
          $xml_writer->startTag($xml_report_rcv); 
          $xml_writer->dataElement($xml_report_status => $reports{$rule_instrument_cmd_id}{$main_id}{'rcv status'});  
          $xml_writer->dataElement($xml_report_time => $reports{$rule_instrument_cmd_id}{$main_id}{'rcv time'});
          $xml_writer->dataElement($xml_report_desc => $reports{$rule_instrument_cmd_id}{$main_id}{'rcv description'});
          # Close the rcv tag.
          $xml_writer->endTag();

          print_debug_trace("Build a rule instrumentor report.");
          $xml_writer->startTag($xml_report_rule_instrumentor); 
          if ($cmds_log{$cmd_id}{'cmd status'} eq $log_cmds_ok)
          {
            $xml_writer->dataElement($xml_report_status => $xml_report_status_ok);
          }
          else
          {
            $xml_writer->dataElement($xml_report_status => $xml_report_status_fail);  
          }
          $xml_writer->dataElement($xml_report_time => 0);
          $xml_writer->dataElement($xml_report_desc => '');
          # Close the rule instrumentor tag.
          $xml_writer->endTag();

          # Close the ld tag.
          $xml_writer->endTag();   
        }
      }
      else
      {
        print_debug_debug("The '$cmd_id' ld command has 'check=false'.");
        $xml_writer->startTag($xml_report_ld, $xml_report_attr_ref => $cmd_id, $xml_report_attr_model => $opt_model_id);
        $xml_writer->startTag($xml_report_rule_instrumentor); 

        if ($cmds_log{$cmd_id}{'cmd status'} eq $log_cmds_ok)
        {
          $xml_writer->dataElement($xml_report_status => $xml_report_status_ok);
        }
        else
        {
          $xml_writer->dataElement($xml_report_status => $xml_report_status_fail);  
        }

        $xml_writer->dataElement($xml_report_time => 0);
        $xml_writer->dataElement($xml_report_desc => '');
            
        # Close the rule instrumentor tag.
        $xml_writer->endTag();
        # Close the ld tag.
        $xml_writer->endTag();      
      }
    }
  }

  print_debug_trace("Close the root node tag and peform final checks in the report mode.");
  $xml_writer->endTag();
  $xml_writer->end();
}
