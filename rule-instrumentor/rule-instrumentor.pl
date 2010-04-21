#! /usr/bin/perl -w


use Cwd qw(abs_path cwd);
use English;
use Env qw(LDV_DEBUG LDV_KERNEL_RULES);
use File::Basename qw(basename fileparse);
use File::Copy qw(mv);
use FindBin;

use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;
use XML::Twig qw();
use XML::Writer qw();

# Add some local Perl packages.
use lib("$FindBin::RealBin/../rule-instrumentor/lib");

use File::Cat qw(cat);
use File::Copy::Recursive qw(rcopy);

################################################################################
# Subroutine prototypes.
################################################################################

# Merge usual and common aspects in aspect mode.
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


################################################################################
# Global variables.
################################################################################

# Suffix for file that will contain general aspect consisting of usual and 
# common aspects.
my $aspect_general_suffix = '.general';

# Information on current command.
my %cmd;

# Instrumentor basedir.
my $cmd_basedir;

# Directory where common model is placed. It's needed to find appropriate 
# header files.
my $common_model_dir;
# Suffixes for common models in plain mode.
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
my $file_xml_out;

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

# Options that are obtained for the version of gcc compiler (version 4.4 or may
# be higher). Note that this is array of options patterns to be excluded.
my @llvm_gcc_4_4_opts = ('-Wframe-larger-than=\d+', '-fno-dwarf2-cfi-asm', '-fconserve-stack');

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

# Command-line options. Use --help option to see detailed description of them.
my $opt_basedir;
my $opt_cmd_xml_in;
my $opt_cmd_xml_out;
my $opt_help;
my $opt_model_id;

# Absolute path to working directory of this tool.
my $tool_working_dir;

# Xml nodes names.
my $xml_cmd_basedir = 'basedir';
my $xml_cmd_attr_id = 'id';
my $xml_cmd_attr_check = 'check';
my $xml_cmd_entry_point = 'main';
my $xml_cmd_cc = 'cc';
my $xml_cmd_cwd = 'cwd';
my $xml_cmd_in = 'in';
my $xml_cmd_ld = 'ld';
my $xml_cmd_opt = 'opt';
my $xml_cmd_out = 'out';
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

print_debug_trace("Prepare a twig xml parser for the models database and the input commands.");
my $xml_twig = new XML::Twig;

print_debug_normal("Get and store information on the required model.");
get_model_info();

print_debug_normal("Create a general aspect if it's needed.");
create_general_aspect();

print_debug_trace("Print the standard xml file header.");
print($file_xml_out "<?xml version=\"1.0\"?>\n");

my $xml_writer;

# In aspect mode prepare special xml writer.
if ($kind_isaspect)
{
  print_debug_trace("Prepare a xml writer, open a root node tag and print a base directory in aspect mode.");  
  $xml_writer = new XML::Writer(OUTPUT => $file_xml_out, NEWLINES => 1, UNSAFE => 1);
  $xml_writer->startTag('cmdstream');
  $xml_writer->dataElement('basedir' => $opt_basedir);
}
else
{
  print_debug_trace("Print a root node open tag in plain mode.");
  print($file_xml_out "<cmdstream>");
}

print_debug_normal("Process the commands input file.");
process_cmds();

if ($kind_isaspect)
{
  print_debug_trace("Close the root node tag and peform final checs in aspect mode.");
  $xml_writer->endTag();
  $xml_writer->end();
}
else
{
  print_debug_trace("Print root node close tag in plain mode.");
  print($file_xml_out "\n</cmdstream>\n");
}

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
    # Not just models now are there.   
    next unless ($model->gi eq 'model');
      
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

      # Aspect file is optional but it's needed in aspect mode.
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
        }
        elsif ($kind eq 'plain')
        {
          $kind_isplain = 1;
          print_debug_debug("The plain mode is used for '$id_attr' model");
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
    'rule-model|m=s' => \$opt_model_id))
  {
    warn("Incorrect options may completely change the meaning! Please run " .
      "script with --help option to see how you may use this tool.");
    help();
  }

  help() if ($opt_help);

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
  print_debug_trace("The instrument basedir is '$opt_basedir'."); 

  unless(-f $opt_cmd_xml_in)
  {
    warn("File specified through option --cmdfile|-c doesn't exist");
    help();
  }
  print_debug_trace("The instrument commands input file is '$opt_cmd_xml_in'.");

  open($file_xml_out, '>', "$opt_cmd_xml_out")
    or die("Couldn't open file '$opt_cmd_xml_out' specified through option --cmdfile-out|-o for write: $ERRNO");
  print_debug_trace("The instrument commands output file is '$opt_cmd_xml_out'.");
  
  print_debug_debug("The command-line options are processed successfully.");
}

sub help()
{
    print(STDERR << "EOM");

NAME
  $PROGRAM_NAME: tool is intended to perform instrumentation of source
  code with model.

SYNOPSIS
  $PROGRAM_NAME [option...]

OPTIONS

  -b, --basedir <dir>
    <dir> is absolute path to tool working directory.

  -h, --help
    Print this help and exit with syntax error.

  -c, --cmdfile <file>
    <file> is absolute path to xml file containing commands for tool.

  -m, --rule-model <id>
    <id> is model id that specify model to be instrumented with 
    source code.

  -o, --cmdfile-out <file>
    <file> is absolute path to xml file that will contain commands
      generated by tool.

ENVIRONMENT VARIABLES

  LDV_KERNEL_RULES
    It's optional option that points to user models directory that 
    will be used instead of the standard one.

EOM

  exit($error_syntax);
}

sub prepare_files_and_dirs()
{
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
  
  print_debug_trace("Obtain the directory where all rule instrumentor auxiliary instruments (such as aspectator) are placed.");
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
    $ENV{$ldv_aspectator_gcc} = $ldv_gcc;
    $ENV{$ldv_no_quoted} = 1;

    my @args = ($ldv_aspectator, ${$cmd{'ins'}}[0], "$ldv_model_dir/$ldv_model{'aspect'}", @{$cmd{'opts'}}, "-I$common_model_dir");

    # Go to build directory to execute cc command.
    chdir($cmd{'cwd'})
      or die("Can't change directory to '$cmd{'cwd'}'");

    system(@args) == 0 or die("System '@args' call failed: $ERRNO");

    # Come back.
    chdir($tool_working_dir)
      or die("Can't change directory to '$tool_working_dir'");

    die("Something wrong with aspectator: it doesn't produce file '${$cmd{'ins'}}[0]$llvm_bitcode_suffix'") 
      unless (-f "${$cmd{'ins'}}[0]$llvm_bitcode_suffix");

    # After aspectator work we obtain files ${$cmd{'ins'}}[0]$llvm_bitcode_suffix with llvm
    # object code. Copy them to $cmd{'out'}$llvm_bitcode_usual_suffix files.
    mv("${$cmd{'ins'}}[0]$llvm_bitcode_suffix", "$cmd{'out'}$llvm_bitcode_usual_suffix") 
      or die("Can't copy file '${$cmd{'ins'}}[0]$llvm_bitcode_suffix' to file '$cmd{'out'}$llvm_bitcode_usual_suffix': $ERRNO");

    # Also do this with general aspect. Don't forget to add -I option with 
    # models directory needed to find appropriate headers for common aspect.
    $ENV{$ldv_aspectator_gcc} = $ldv_gcc;
    $ENV{$ldv_no_quoted} = 1;
    @args = ($ldv_aspectator, ${$cmd{'ins'}}[0], "$ldv_model_dir/$ldv_model{'general'}", @{$cmd{'opts'}}, "-I$common_model_dir");

    # Go to build directory to execute cc command.
    chdir($cmd{'cwd'})
      or die("Can't change directory to '$cmd{'cwd'}'");

    system(@args) == 0 
      or die("System '@args' call failed: $ERRNO");

    die("Something wrong with aspectator: it doesn't produce file '${$cmd{'ins'}}[0]$llvm_bitcode_suffix'") 
      unless (-f "${$cmd{'ins'}}[0]$llvm_bitcode_suffix");

    # After aspectator work we obtain files ${$cmd{'ins'}}[0]$llvm_bitcode_suffix with llvm
    # object code. Copy them to $cmd{'out'}$llvm_bitcode_general_suffix files.
    mv("${$cmd{'ins'}}[0]$llvm_bitcode_suffix", "$cmd{'out'}$llvm_bitcode_general_suffix") 
      or die("Can't copy file '${$cmd{'ins'}}[0]$llvm_bitcode_suffix' to file '$cmd{'out'}$llvm_bitcode_general_suffix': $ERRNO");

    # Come back.
    chdir($tool_working_dir)
      or die("Can't change directory to '$tool_working_dir'");
  }
}

sub process_cmd_ld()
{
  my $ischeck = $cmd{'check'} eq 'true';

  if ($kind_isaspect)
  {
    # Prepare C file to be checked for ld command marked with 'check = "true"'.   
    if ($ischeck)
    {  
      # On each ld command we run llvm linker for all input files together to 
      # produce one linked file. Note that excactly one file to be linked must 
      # be generally (i.e. with usual and common aspects) instrumented. We 
      # choose the first one here. Other files must be usually instrumented.
      my @ins = ("${$cmd{'ins'}}[0]$llvm_bitcode_general_suffix", map("$_$llvm_bitcode_usual_suffix", @{$cmd{'ins'}}[1..$#{$cmd{'ins'}}]));
      my @args = ($ldv_linker, @llvm_linker_opts, @ins, '-o', "$cmd{'out'}$llvm_bitcode_linked_suffix");

      # Go to build directory to execute ld command.
      chdir($cmd{'cwd'})
        or die("Can't change directory to '$cmd{'cwd'}'");

      system(@args) == 0 or die("System '@args' call failed: $ERRNO");

      # Come back.
      chdir($tool_working_dir)
        or die("Can't change directory to '$tool_working_dir'");

      die("Something wrong with linker: it doesn't produce file '$cmd{'out'}$llvm_bitcode_linked_suffix'") 
        unless (-f "$cmd{'out'}$llvm_bitcode_linked_suffix");

      # Make name for c file corresponding to the linked one.
      my $c_out = "$cmd{'out'}$llvm_bitcode_linked_suffix$llvm_c_backend_suffix";

      # Linked file is converted to c by means of llvm c backend.
      @args = ($ldv_c_backend, @llvm_c_backend_opts, "$cmd{'out'}$llvm_bitcode_linked_suffix", '-o', $c_out);
      system(@args) == 0 or die("System '@args' call failed: $ERRNO");

      die("Something wrong with aspectator: it doesn't produce file '$c_out'") 
        unless (-f "$c_out");

      # Print corresponding commands to output xml file. 
      $xml_writer->startTag('cc', 'id' => "$cmd{'id'}-llvm-cc");
      $xml_writer->dataElement('cwd' => $cmd{'cwd'});
      $xml_writer->dataElement('in' => $c_out);
      # Use here the first input file name to relate with corresponding ld 
      # command.
      $xml_writer->dataElement('out' => ${$cmd{'ins'}}[0]);
      $xml_writer->dataElement('engine' => $ldv_model{'engine'});
      # Close cc tag.
      $xml_writer->endTag();

      $xml_writer->startTag('ld', 'id' => "$cmd{'id'}-llvm-ld");
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
    
      # Close ld tag.
      $xml_writer->endTag();
    }
    # Otherwise create two linked variants: with and without general bytecode 
    # file.
    else
    {
      # On each ld command we run llvm linker for all input files together to 
      # produce one linked file. Also produce linked file that contains excactly 
      # one file generally (i.e. with usual and common aspects) instrumented. 
      # We choose the first one here. Other files must be usually instrumented.
      my @ins_usual = map("$_$llvm_bitcode_usual_suffix", @{$cmd{'ins'}});
      my @args_usual = ($ldv_linker, @llvm_linker_opts, @ins_usual, '-o', "$cmd{'out'}$llvm_bitcode_linked_suffix");
      my @ins_general = ("${$cmd{'ins'}}[0]$llvm_bitcode_general_suffix", map("$_$llvm_bitcode_usual_suffix", @{$cmd{'ins'}}[1..$#{$cmd{'ins'}}]));
      my @args_general = ($ldv_linker, @llvm_linker_opts, @ins_general, '-o', "$cmd{'out'}$llvm_bitcode_general_suffix");

      # Go to build directory to execute ld command.
      chdir($cmd{'cwd'})
        or die("Can't change directory to '$cmd{'cwd'}'");

      system(@args_usual) == 0 or die("System '@args_usual' call failed: $ERRNO");
      system(@args_general) == 0 or die("System '@args_general' call failed: $ERRNO");

      # Come back.
      chdir($tool_working_dir)
        or die("Can't change directory to '$tool_working_dir'");

      die("Something wrong with linker: it doesn't produce file '$cmd{'out'}$llvm_bitcode_linked_suffix'") 
        unless (-f "$cmd{'out'}$llvm_bitcode_linked_suffix");
      die("Something wrong with linker: it doesn't produce file '$cmd{'out'}$llvm_bitcode_general_suffix'") 
        unless (-f "$cmd{'out'}$llvm_bitcode_general_suffix");
    }
  }
}

sub process_cmds()
{
  print_debug_trace("Read commands input xml file.");
  $xml_twig->parsefile("$opt_cmd_xml_in");

  # To print out user friendly xml output.  
  $xml_twig->set_pretty_print('indented');

  print_debug_trace("Read xml root.");
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
        print_debug_trace("Use the tool base directory '$opt_basedir' instead of the specified one in plain mode.");
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
      for (my $in = $cmd->first_child($xml_cmd_in)
        ; $in
        ; $in = $in->next_elt($xml_cmd_in))
      {
        $in->set_text(shift(@ins_text));

        last if ($in->is_last_child($xml_cmd_in));
      }   
      $out_text =~ s/^$cmd_basedir/$opt_basedir/;
      $out->set_text($out_text);
      print_debug_debug("The output file with replaced base directory is '$out_text'.");
#===============================
      # For nonaspect mode (plain mode) just copy and modify a bit input xml.
      if ($kind_isplain)
      {
        # Add additional input model file, error and hints tags for each ld 
        # command.
        if ($cmd->gi eq $xml_cmd_ld)
        {
          # Replace the first object file to be linked with object file 
          # containing common model.
          my $in = $cmd->first_child($xml_cmd_in);
          $in->set_text($in->text . $common_o_suffix);
          
          my $xml_error_tag = new XML::Twig::Elt('error', $ldv_model{'error'});
          $xml_error_tag->paste('last_child', $cmd);

          my $twig_hints = $ldv_model{'twig hints'}->copy;
          $twig_hints->paste('last_child', $cmd);
        }
        # Add -I option with common model dir to find appropriate headers. Note
        # that it also add for a duplicated command.
        elsif ($cmd->gi eq $xml_cmd_cc)
        {
          my $common_model_opt = new XML::Twig::Elt($xml_cmd_opt => "-I$common_model_dir");
          $common_model_opt->paste('last_child', $cmd);
        }
        
        # Add engine tag for both cc and ld commands.
        if ($cmd->gi eq $xml_cmd_ld or $cmd->gi eq $xml_cmd_cc)
        {
          my $xml_engine_tag = new XML::Twig::Elt('engine', $ldv_model{'engine'});
          $xml_engine_tag->paste('last_child', $cmd);
        }

        $cmd->print($file_xml_out);

        # Duplicate each cc command with containing of common model.
        if ($cmd->gi eq $xml_cmd_cc)
        {
          my $common_model_cc = $cmd->copy;
          
          $common_model_cc->set_att($xml_cmd_attr_id => $cmd->att($xml_cmd_attr_id) . '-with-common-model');

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
          
          my $out = $common_model_cc->first_child($xml_cmd_out);
          $out->set_text($out->text . $common_o_suffix);

          $common_model_cc->print($file_xml_out);
        }

        print_debug_debug("Finish processing of the command having id '$id_attr'.");
        next;
      }

      # For aspect mode more detailed parsing is done.
      $out_text = $out->text;

      # Read array of input files.
      for (my $in = $cmd->first_child($xml_cmd_in)
        ; $in
        ; $in = $in->next_elt($xml_cmd_in))
      {
        push(@ins_text, $in->text);

        last if ($in->is_last_child($xml_cmd_in));
      }

      # Read array of options.
      my @opts;

      for (my $opt = $cmd->first_child($xml_cmd_opt)
        ; $opt
        ; $opt = $opt->next_elt($xml_cmd_opt))
      {
        my $opt_text = $opt->text;

        # Exclude options for the new gcc compiler.
        foreach my $llvm_gcc_4_4_opt (@llvm_gcc_4_4_opts)
        {
          if ($opt_text =~ /^$llvm_gcc_4_4_opt$/)
          {
            $opt_text = '';
            last;
          }
        }

        next unless ($opt_text);

        push(@opts, $opt_text);

        last if ($opt->is_last_child($xml_cmd_opt));
      }

      # Store current command information. 
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
        process_cmd_cc();
      }

      # ld command additionaly contains array of entry points.
      if ($cmd->gi eq $xml_cmd_ld)
      {
        my @entry_points;

        # Read array of entry points.
        for (my $entry_point = $cmd->first_child($xml_cmd_entry_point)
          ; $entry_point
          ; $entry_point = $entry_point->next_elt($xml_cmd_entry_point))
        {
          push(@entry_points, $entry_point->text);

          last if ($entry_point->is_last_child($xml_cmd_entry_point));
        }

        $cmd{'entry point'} = \@entry_points;

        process_cmd_ld();
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
