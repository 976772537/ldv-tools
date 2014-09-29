#! /usr/bin/perl -w

################################################################################
# Copyright (C) 2010-2012
# Institute for System Programming, Russian Academy of Sciences (ISPRAS).
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

use Cwd qw(abs_path cwd);
use English;
use Env qw(LDV_DEBUG LDV_KERNEL_RULES LDV_LLVM_GCC LDV_RULE_INSTRUMENTOR_DEBUG WORK_DIR);
use File::Basename qw(basename fileparse dirname);
use File::Copy qw(copy mv);
use File::Path qw(mkpath);
use FindBin;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;
use Time::HiRes qw(gettimeofday tv_interval);
use XML::Twig qw();
use XML::Writer qw();

# Add some local Perl packages.
use lib("$FindBin::RealBin/../shared/perl");

use File::Cat qw(cat);
use File::Copy::Recursive qw(rcopy);

# Add some nonstandard local Perl packages.
use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info
  print_debug_debug print_debug_trace print_debug_all get_debug_level
  check_system_call);


################################################################################
# Subroutine prototypes.
################################################################################

# Add engine to the XML command
# args: XML command (will be modified!)
# retn: XML command with the engine
sub add_engine_tag($);

# Create configuration files and return pathes to them.
# args: the name of directory relatively to which configurations are
#   created; the part of path to configuration file.
# retn: the pathes to configuration files.
sub create_configs($$);

# Delete auxiliary files produced during work in the nondebug modes. (Useful for LLVM only).
# args: no.
# retn: nothing.
sub delete_aux_files();

# The auxiliary function that captures error description.
# args: an array to be passed to the system function.
# retn: a function execution status and description.
sub exec_status_and_desc(@);

# Auxilliary function that fixes options in the command given by adding model
# options and removing some of them
# args: XML cmd, options to add, options to remove
# retn: autoconf path, filtered options list
sub filter_opts($$$);

# The auxiliary function that count execution time for its function argument.
# args: a function name.
# retn: a function execution status, description and time.
sub func_status_desc_and_time;

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

# Join together error descriptions placing separators between them.
# args: an array of references to error descriptions.
# retn: a reference to a joined description.
sub join_error_desc(@);

# Obtain needed files and dirs and check their presence.
# args: no.
# retn: nothing.
sub prepare_files_and_dirs();

# Print a log message about an one command.
# args: a reference to a hash containing a command log.
# retn: nothing.
sub print_cmd_log($);

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

# Create file name from a cache directory and keys.
# args: file "keys" list.
# retn: cache file name.
sub cache_fname(@);

# Copy file from cache to destination if it exists there. Checks if cache is
# on, and does nothing if it's not.
# args: destination, file "keys" list.
# retn: if a file was found in cache.
sub copy_from_cache($@);

# Save file to cache; replace existing file if it already exists. Checks if
# cache is on, and does nothing if it's not.
# args: source, file "keys" list.
# retn: nothing.
sub save_to_cache($@);

# Obtain string from cache corresponding to keys.
# args: file "keys" list.
# retn: string.
sub string_from_cache(@);

# Put string to cache in correspondence with keys.
# args: string, file "keys" list.
# retn: nothing.
sub string_to_cache($@);


################################################################################
# Global variables.
################################################################################

# Commands execution statuses;
my %cmds_status_fail;
my %cmds_status_ok;

# Instrumentor basedir.
my $cmd_basedir;

# Suffixes for common models in the plain mode.
my $common_c_suffix = '.common.c';
my $common_o_suffix = '.common.o';

# Prefix for all debug messages.
my $debug_name = 'rule-instrumentor';
# Debug level to be used.
my $debug_level = 'QUIET';

# Errors return codes.
my $error_syntax = 1;
my $error_semantics = 2;

# File handlers.
my $file_cmds_log;
my $file_report_xml_out;
my $file_temp = \*STDERR;
my $file_xml_out;

# Auxiliary files produced during work that must be deleted in the nondebug
# modes.
my %files_to_be_deleted;

# Options to the gcc compiler to be turned on/off.
my @gcc_aspect_off_opts;
my @gcc_aspect_on_opts;
my @gcc_plain_off_opts;
my @gcc_plain_on_opts;
# Options to the llvm compiler to be turned on/off.
my @llvm_aspect_off_opts;
my @llvm_aspect_on_opts;

# Additional suffixies for id attributes.
my $id_common_model_suffix = '-with-common-model';
my $id_cc_llvm_suffix = '-llvm-cc';
my $id_ld_llvm_suffix = '-llvm-ld';

# Flag that specifies whether argument signatures should be gathered or not.
my $isgather_arg_signs = 0;
# Files containing argument signs.
my @gathered_arg_sign_files;
# Files containing statically initialized variables.
my @gathered_static_inits_files;

# Flag that specifies whether configuration was done.
my $isconfig = 0;
# The set of configuration directories.
my @config_dir = ();

# Kind of instrumentation.
my $kind_isplain = 0;
my $kind_isaspect = 0;
my $aspectator_type = undef;

# Supported aspectator backends
my %supported_backends = ('gcc'=>1, 'llvm'=>0);

my $ldv_rule_instrumentor_abs;
my @ldv_rule_instrumentor_path;
my $ldv_rule_instrumentor_dir;
my $LDV_HOME;
my $ldv_rule_instrumentor;
my @ldv_rule_instrumentor_patterns = ('.*,ALL', '.*cc1.*,CC1', '.*c-backend.*,C-BACKEND', '.*linker.*,LINKER');
my $ldv_aspectator_bin_dir;
my $ldv_aspectator;
# Env var that keeps path to GCC executable.
my $ldv_aspectator_gcc;
my $ldv_gcc;
my $ldv_timeout_script;
my $ldv_timeout_script_output;
my @ldv_timeout_script_opts;

# LLVM backend-specific configuration

# Environment variable that keeps path to GCC executable for LLVM
my $ldv_llvm_aspectator_gcc = 'LDV_LLVM_GCC';
my $ldv_llvm_c_backend;
my $ldv_llvm_gcc;
my $ldv_llvm_aspectator_bin_dir;
my $ldv_llvm_aspectator;
# Linker.
my $ldv_llvm_linker;

# Aspectator configuration
my $ldv_gcc_aspectator;
# Environment variable that keeps path to GCC executable for LLVM
my $ldv_gcc_aspectator_gcc_env = 'LDV_ASPECTATOR_CORE';

my $ldv_gcc_aspectator_bin_dir;
my $ldv_gcc_gcc;
# GCC ASpectator suffixes
# Suffix of generated aspect files emitted near the source files
my $gcc_suffix_aspect = '.c';
# Suffix for stage 1 files for GCC aspectator
my $gcc_preprocessed_suffix = '.p';

# Common aspect file to be included implicitly by RI into all aspect models.
# It's relative to a tool directory.
my $ri_aspect = 'ri.aspect';

# Directory where common model is placed. It's needed to find appropriate
# header files.
my $ldv_model_include_dir;
# Name of file where a common model source and object will be put. It's relative
# to a common model directory.
my $ldv_model_common = 'ldv_common_model.c';
my $ldv_model_common_o = 'ldv_common_model.o';
# Compilation options and a current working directory to be used for a common
# model preprocessing.
my $ldv_model_common_opts;
my $ldv_model_common_cwd;
# Directory contains rules models database and their source code.
my $ldv_model_dir;
# Name of xml file containing models database. Name is relative to models
# directory.
my $ldv_model_db_xml = 'model-db.xml';
# Information on needed model.
my %ldv_model;

# Suffix of llvm bitcody files.
my $llvm_bitcode_suffix = '.bc';

# Suffix of linked llvm bitcode files.
my $llvm_bitcode_linked_suffix = '.linked';

# Options to be passed to llvm C backend.
my @llvm_c_backend_opts = ('-f', '-march=c');

# Suffix for llvm C backend production.
my $llvm_c_backend_suffix = '.cbe.c';

# Options to be passed to llvm linker.
my @llvm_linker_opts = ('-f');

# Suffix of llvm preprocessed files.
my $llvm_preprocessed_suffix = '.p';

# The commands log file designatures.
my $log_cmds_aspect = {'gcc' => 'mode=aspect', 'llvm'=>'mode=aspect-llvm'};
my $log_cmds_cc = 'cc';
my $log_cmds_desc_begin = '^^^^^&&&&&';
my $log_cmds_desc_end = '&&&&&^^^^^';
my $log_cmds_desc_ld_cc_separator = '&&&&&&&&&&';
my $log_cmds_fail = 'fail';
my $log_cmds_ld = 'ld';
my $log_cmds_ok = 'ok';
my $log_cmds_plain = 'mode=plain';
my $log_cmds_verifier = 'verifier';

# Command-line options. Use --help option to see detailed description of them.
my $opt_basedir;
my $opt_cache_dir;
my $opt_cmd_xml_in;
my $opt_cmd_xml_out;
my $opt_help;
my $opt_model_id;
my $opt_report_in;
my $opt_report_out;
my $opt_skip_restrict_main;
my $opt_suppress_config_check;

# This flag says whether usual or report mode is set up.
my $report_mode = 0;

# A path to auxiliary working directory of this tool. The tool places its needed
# temporaries there. It's relative to WORK_DIR.
my $tool_aux_dir = 'rule-instrumentor';
# The name of file where commands execution status will be logged. It's relative
# to the tool auxiliary working directory.
my $tool_cmds_log = 'cmds-log';
# The name of file for time statistics information on rule-instrumentor.
my $tool_stats_xml = 'stats.xml';
# The name of directory where configuration files will be placed. It's
# relative to the tool auxiliary working directory.
my $tool_config_dir = 'config';
# The name of directory where common model files will be placed. It's
# relative to the tool auxiliary working directory.
my $tool_model_common_dir = 'common-model';
# The file that is used to store different auxiliary information. It's relative
# to the tool base directory.
my $tool_temp = '__rule_instrumentor_temp';
# An absolute path to working directory of this tool.
my $tool_working_dir;

# Xml nodes names.
my $xml_cmd_attr_id = 'id';
my $xml_cmd_attr_check = 'check';
my $xml_cmd_attr_restrict = 'restrict';
my $xml_cmd_basedir = 'basedir';
my $xml_cmd_entry_point = 'main';
my $xml_cmd_cc = 'cc';
my $xml_cmd_cwd = 'cwd';
my $xml_cmd_in = 'in';
my $xml_cmd_ld = 'ld';
my $xml_cmd_opt = 'opt';
my $xml_cmd_opt_config = 'config';
my $xml_cmd_opt_config_autoconf = 'autoconf';
my $xml_cmd_out = 'out';
my $xml_cmd_root = 'cmdstream';
my $xml_header = '<?xml version="1.0"?>';
my $xml_model_db_attr_id = 'id';
my $xml_model_db_engine = 'engine';
my $xml_model_db_error = 'error';
my $xml_model_db_files = 'files';
my $xml_model_db_files_aspect = 'aspect';
my $xml_model_db_files_common = 'common';
my $xml_model_db_files_config = 'config';
my $xml_model_db_hints = 'hints';
my $xml_model_db_kind = 'kind';
my $xml_model_db_model = 'model';
my $xml_model_db_opt_aspect = 'aspect_options';
my $xml_model_db_opt_aspect_llvm = 'aspect_llvm_options';
my $xml_model_db_opt_on = 'on';
my $xml_model_db_opt_off = 'off';
my $xml_model_db_opt_plain = 'plain_options';
my $xml_report_attr_main = 'main';
my $xml_report_attr_model = 'model';
my $xml_report_attr_ref = 'ref';
my $xml_report_cc = 'cc';
my $xml_report_desc = 'desc';
my $xml_report_ld = 'ld';
my $xml_report_model_kind = 'model-kind';
my $xml_report_model_kind_aspect = 'aspect';
my $xml_report_model_kind_plain = 'plain';
my $xml_report_rcv = 'rcv';
my $xml_report_rule_instrumentor = 'rule-instrumentor';
my $xml_report_root = 'reports';
my $xml_report_status = 'status';
my $xml_report_status_fail = 'FAILED';
my $xml_report_status_ok = 'OK';
my $xml_report_time = 'time';
my $xml_report_trace = 'trace';
my $xml_report_verdict = 'verdict';
my $xml_report_verdict_stub = 'UNKNOWN';
my $xml_report_verifier = 'verifier';

# Cache funcitonality.
my $do_cache = '';  #false
my $ri_cache_dir = undef;
my $skip_cache_without_restrict = '';


################################################################################
# Main section.
################################################################################

# Specify debug level.
$debug_level = get_debug_level($debug_name, $LDV_DEBUG, $LDV_RULE_INSTRUMENTOR_DEBUG);

print_debug_debug("Obtain the absolute path of the current working directory");
$tool_working_dir = Cwd::cwd()
  or die("Couldn't get current working directory");
print_debug_debug("The current working directory is '$tool_working_dir'");

print_debug_debug("Process the command-line options");
get_opt();

print_debug_debug("Check presence of needed files, executables and directories. Copy needed files and directories");
prepare_files_and_dirs();

print_debug_trace("Prepare a twig xml parser for the models database, the input commands and report");
my $xml_twig = new XML::Twig;
# To print out user friendly xml output.
$xml_twig->set_pretty_print('indented');

my $xml_writer;

if ($report_mode)
{
  process_report();

  close($file_report_xml_out)
    or die("Couldn't close file '$opt_report_out': $ERRNO\n");

  print_debug_debug("Make the report successfully");
  exit 0;
}

print_debug_debug("Get and store information on the required model");
get_model_info();

print_debug_trace("Print the standard xml file header");
print($file_xml_out "$xml_header\n");

# In the aspect mode prepare special xml writer.
if ($kind_isaspect)
{
  print_debug_trace("Prepare a xml writer, open a root node tag and print a base directory in the aspect mode");
  $xml_writer = new XML::Writer(OUTPUT => $file_xml_out, NEWLINES => 1, UNSAFE => 1);
  $xml_writer->startTag($xml_cmd_root);
  $xml_writer->dataElement($xml_cmd_basedir => $opt_basedir);
}
else
{
  print_debug_trace("Print a root node open tag in the plain mode");
  print($file_xml_out "<$xml_cmd_root>");
}

print_debug_debug("Process the commands input file");
process_cmds();

if ($kind_isaspect)
{
  print_debug_trace("Close the root node tag and peform final checks in the aspect mode");
  $xml_writer->endTag();
  $xml_writer->end();
}
else
{
  print_debug_trace("Print root node close tag in the plain mode");
  print($file_xml_out "\n</$xml_cmd_root>\n");
}

print_debug_trace("Close file handlers");
close($file_cmds_log)
  or die("Couldn't close file '$tool_cmds_log': $ERRNO\n");
close($file_xml_out)
  or die("Couldn't close file '$opt_cmd_xml_out': $ERRNO\n");

print_debug_info("Delete auxiliary files in the nondebug modes");
delete_aux_files();

print_debug_normal("Make all successfully");

# TODO: Remove LLVM-based stuff (most likely).

################################################################################
# Subroutines.
################################################################################

sub add_engine_tag($)
{
  my ($cmd) = shift;
  # Add engine tag for both cc and ld commands.
  print_debug_trace("For the both cc and ld commands add engine");
  my $xml_engine_tag = new XML::Twig::Elt('engine', $ldv_model{'engine'});
  $xml_engine_tag->paste('last_child', $cmd);

  return $cmd;
}

sub create_configs($$)
{
  my $rel_dir = shift;
  my $conf_path = shift;

  # If configuration was already done.
  return @config_dir if ($isconfig);

  $conf_path =~ s/^$rel_dir//;
  print_debug_trace("Relative path to config file is $conf_path");

  print_debug_trace("Check presence of configuration file");
  die("Can't find configuration file '$rel_dir/$conf_path'.")
    unless (-f "$rel_dir/$conf_path");

  # That is configuration file itself and the set of subdirectories
  # where it must be placed and that must be returned then. Note that
  # all must be relative to the tool configuration directory.
  my @conf = split(/\//, $conf_path);

  my $to;
  my $patched_conf;
  while (my $conf = pop(@conf))
  {
    my $isfirst = 0;

    # When parse the directory.
    if ($to)
    {
      # When parse the next directories.
      if ($to =~ /\//)
      {
        $to = "$conf/$to";
      }
      # When parse the first directory.
      else
      {
        $to = "/$conf";
      }
    }
    # When parse the file.
    else
    {
      $to = $conf;
      $isfirst = 1;
    }
    print_debug_debug("Create configuration '$to'");

    if ($isfirst)
    {
      print_debug_trace("Copy the main configuration file to the configuration directory and patch it");

      open(my $file_conf, '>', "$tool_config_dir/$to")
        or die("Couldn't open file '$tool_config_dir/$to' for write: $ERRNO");
      cat("$rel_dir/$conf_path", $file_conf)
        or die("Can't concatenate file '$rel_dir/$conf_path' with file '$tool_config_dir/$to'");
      cat("$ldv_model_dir/$ldv_model{'config'}", $file_conf)
        or die("Can't concatenate file '$ldv_model_dir/$ldv_model{'config'}' with file '$tool_config_dir/$to'");
      close($file_conf)
        or die("Couldn't close file '$tool_config_dir/$to': $ERRNO\n");

      $patched_conf = $to;

      push(@config_dir, $tool_config_dir);
    }
    else
    {
      print_debug_trace("Just copy the patched configuration file to the corresponding configuration directory");

      unless (-d "$tool_config_dir/$to")
      {
        mkpath("$tool_config_dir/$to")
          or die("Couldn't recursively create directory '$tool_config_dir/$to': $ERRNO");
      }

      copy("$tool_config_dir/$patched_conf", "$tool_config_dir/$to/$patched_conf")
        or die("Can't copy the file '$tool_config_dir/$patched_conf' to the file '$tool_config_dir/$to/$patched_conf'");

      push(@config_dir, "$tool_config_dir/$to");
    }
  }

  # To fix bug 4402 http://forge.ispras.ru/issues/4402.
  $isconfig = 1;

  return @config_dir;
}

sub delete_aux_files()
{
  # Note that this is only effective for LLVM aspectator.  GCC aspectator removes the files on its own.
  return 0 if (LDV::Utils::check_verbosity('DEBUG'));

  foreach my $file (keys(%files_to_be_deleted))
  {
    print_debug_trace("Delete the file '$file'");
    unlink($file)
      or die("Can't delete the file '$file'");
  }
}

sub func_status_desc_and_time
{
  my $func = shift;
  my @args = @_;

  print_debug_trace("Keep the start time");
  my $start_time = [gettimeofday()];

  print_debug_trace("Call the function by the function reference");
  my ($status, $desc) = $func->(@args);

  print_debug_trace("Find and save script execution time");
  my $end_time = [gettimeofday()];
  my $elapsed = tv_interval($start_time, $end_time);
  print_debug_debug("The elapsed time is '$elapsed'");
  print_debug_trace("Convert time to milliseconds");
  $elapsed *= 100;
  $elapsed =~ /\./;
  print_debug_debug("The elapsed time in milliseconds is '$PREMATCH'");

  return ($status, $desc, $PREMATCH);
}

sub exec_status_and_desc(@)
{
  print_debug_trace("Redirect STDERR to the file '$opt_basedir/$tool_temp'");
  open(STDERR_SAVE, '>&', $file_temp)
    or die("Couldn't dup STDERR: $ERRNO");
  die("I needed to prevent warning message generation") unless (*STDERR_SAVE);
  open(STDERR, '>', "$opt_basedir/$tool_temp")
    or die("Couldn't redirect STDERR to '$opt_basedir/$tool_temp': $ERRNO");
  # Make STDERR unbuffered.
  select(STDERR);
  $OUTPUT_AUTOFLUSH = 1;

  print_debug_trace("Execute the command");
  my $status = system(@ARG);
  print_debug_debug("The command execution status is '$status'");

  print_debug_trace("Redirect STDERR to its default place'");
  close(STDERR)
    or die("Couldn't close file '$opt_basedir/$tool_temp': $ERRNO");;
  open(STDERR, '>&', STDERR_SAVE)
    or die("Couldn't dup the old STDERR: $ERRNO");

  print_debug_trace("Read failure description");
  my $file_temp_read;
  open($file_temp_read, '<', "$opt_basedir/$tool_temp")
    or die("Couldn't open file '$opt_basedir/$tool_temp' for read: $ERRNO");

  my @desc = <$file_temp_read>;
  print_debug_trace("The command execution full description is '@desc'");

  close($file_temp_read)
    or die("Couldn't close file '$opt_basedir/$tool_temp': $ERRNO\n");

  unless (LDV::Utils::check_verbosity('DEBUG'))
  {
    unlink("$opt_basedir/$tool_temp")
      or die("Couldn't delete file '$opt_basedir/$tool_temp': $ERRNO\n");
  }

  return ($status, \@desc);
}

sub get_model_info()
{
  print_debug_trace("Read the models database xml file '$ldv_model_dir/$ldv_model_db_xml'");
  $xml_twig->parsefile("$ldv_model_dir/$ldv_model_db_xml");
  my $model_db = $xml_twig->root;

  print_debug_trace("Obtain all models");
  my @models = $model_db->children;

  print_debug_trace("Iterate over the all models and try to find the appropriate one");
  foreach my $model (@models)
  {
    # Process options to be passed to the gcc compiler.
    if ($model->gi eq $xml_model_db_opt_plain || $model->gi eq $xml_model_db_opt_aspect || $model->gi eq $xml_model_db_opt_aspect_llvm)
    {
      print_debug_trace("Process '" . $model->gi . "' options");

      # Such options consist of two classes: on and off options. Process them
      # separately.
      print_debug_trace("Read an array of on options");
      my @on_opts = ();
      for (my $on_opt = $model->first_child($xml_model_db_opt_on)
        ; $on_opt
        ; $on_opt = $on_opt->next_elt($xml_model_db_opt_on))
      {
        push(@on_opts, $on_opt->text);

        last if ($on_opt->is_last_child($xml_model_db_opt_on));
      }
      print_debug_debug("The on options '@on_opts' are specified");

      print_debug_trace("Read an array of off options");
      my @off_opts = ();
      for (my $off_opt = $model->first_child($xml_model_db_opt_off)
        ; $off_opt
        ; $off_opt = $off_opt->next_elt($xml_model_db_opt_off))
      {
        push(@off_opts, $off_opt->text);

        last if ($off_opt->is_last_child($xml_model_db_opt_off));
      }
      print_debug_debug("The off options '@off_opts' are specified");

      # Separate options in depend on the mode.
      if ($model->gi eq $xml_model_db_opt_plain)
      {
        @gcc_plain_off_opts = @off_opts;
        @gcc_plain_on_opts = @on_opts;
      }
      elsif ($model->gi eq $xml_model_db_opt_aspect)
      # I see no point in distinguising aspectator's options even further
      {
        @gcc_aspect_off_opts = @off_opts;
        @gcc_aspect_on_opts = @on_opts;
      }
      elsif ($model->gi eq $xml_model_db_opt_aspect_llvm)
      {
        @llvm_aspect_off_opts = @off_opts;
        @llvm_aspect_on_opts = @on_opts;
      }

      # Go to the next 'model'.
      next;
    }

    unless ($model->gi eq $xml_model_db_model)
    {
      warn("The models database contains '" . $model->gi . "' tag that can't be parsed");
      exit($error_semantics);
    }

    print_debug_trace("Read id attribute for a model to find the corresponding one");
    my $id_attr = $model->att($xml_model_db_attr_id)
      // die("Models database doesn't contain '$xml_model_db_attr_id' attribute for some model");
    print_debug_trace("Read the '$id_attr' id attribute for a model");

    # Model is found!
    if ($id_attr eq $opt_model_id)
    {
      print_debug_debug("The required model having id '$id_attr' is found");

      # Read model information.
      print_debug_trace("Read engine tag");
      my $engine = $model->first_child_text($xml_model_db_engine)
        // die("Models database doesn't contain '$xml_model_db_engine' tag for '$id_attr' model");
      print_debug_debug("The engine '$engine' is specified for the '$id_attr' model");

      print_debug_trace("Read error tag");
      my $error = $model->first_child_text($xml_model_db_error)
        // die("Models database doesn't contain '$xml_model_db_error' tag for '$id_attr' model");
      print_debug_debug("The error label '$error' is specified for the '$id_attr' model");

      # Store hints for static verifier to be passed without any processing.
      print_debug_trace("Read hints tag");
      my $hints = $model->first_child($xml_model_db_hints);

      print_debug_trace("Read array of kinds");
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
      print_debug_debug("The kinds '@kinds' are specified for the '$id_attr' model");

      print_debug_trace("Read file names");
      my $files = $model->first_child($xml_model_db_files)
        or die("Models database doesn't contain '$xml_model_db_files' tag for '$id_attr' model");

      # Obtain aspect file or template and script for the aspect mode.
      my $aspect = '';
      my $template = '';
      my $arg_sign_algo = '';
      my $script = '';

      # Obtain common file for the common mode.
      my $common = '';

      # Config file is optional.
      print_debug_trace("Read config file name");
      my $config = $files->first_child_text($xml_model_db_files_config);
      print_debug_debug("The config file '$config' is specified for the '$id_attr' model")
        if ($config);

      print_debug_trace("Check whether the '$id_attr' model kinds are specified correctly");
      foreach my $kind (@kinds)
      {
        if ($kind eq 'aspect' || $kind eq 'aspect-llvm')
        {
          $kind_isaspect = 1;

          # Determine aspectating backend for this rule and set global variables to those specific to this backend
          $aspectator_type = ($kind eq 'aspect') ? 'gcc' : 'llvm';

          # Check if the backend specified is supported
          local $_;
          die(sprintf("The '$aspectator_type' aspectator backend is not supported in this installation!  Only %s are supported",join(", ",grep{$supported_backends{$_}} keys %supported_backends)))
            unless ($supported_backends{$aspectator_type});

          if ($aspectator_type eq 'gcc')
          {
            $ldv_aspectator = $ldv_gcc_aspectator;
          }
          else
          {
            $ldv_aspectator = $ldv_llvm_aspectator;
            $ldv_aspectator_gcc = $ldv_llvm_aspectator_gcc;
            $ldv_gcc = $ldv_llvm_gcc;
          }

          print_debug_trace("Get '$xml_model_db_files_aspect' tag for the '$id_attr' model");
          my $aspect_tag = $files->first_child($xml_model_db_files_aspect)
            or die("'$xml_model_db_files_aspect' tag isn't specified for the '$id_attr' model");

          print_debug_trace("Understand whether model should be generated by script");
          $script = $aspect_tag->att('generated-by');

          if ($script)
          {
            print_debug_debug("Model will be generated by script '$script'");

            if ($script eq 'rerouter')
            {
              # Rerouter needs aspect template to generate info request and aspect
              # itself on the basis of it.
              print_debug_trace("Obtain template");
              $template = $aspect_tag->first_child_text('template')
                or die("Template isn't specified for '$id_attr' model");
              print_debug_debug("Template '$template' is specified for the '$id_attr' model");
              $template = "$ldv_model_dir/$template";

              $ldv_model_include_dir = "$ldv_model_dir/" . dirname($template);
              print_debug_debug("Header files will be additionaly searched for in '$ldv_model_include_dir'");

              print_debug_trace("Obtain argument signature algorithm if so");
              $arg_sign_algo = $aspect_tag->first_child_text('arg_sign');
              print_debug_debug("Argument signature algorithm '$arg_sign_algo' is specified for the '$id_attr' model")
                if ($arg_sign_algo);

              $aspect = "$tool_aux_dir/" . basename($template) . '.aspect';
              print_debug_debug("Aspect will be generated to file '$aspect'");
            }
          }
          else
          {
            print_debug_trace("Read aspect file name");
            $aspect = $aspect_tag->text();
            print_debug_debug("Aspect file '$aspect' is specified for the '$id_attr' model");

            $ldv_model_include_dir = "$ldv_model_dir/" . dirname($aspect);
            print_debug_debug("Header files will be additionaly searched for in '$ldv_model_include_dir'");

            $aspect = "$ldv_model_dir/$aspect";
            die("Aspect file '$aspect' doesn't exist (for '$id_attr' model)")
              unless (-f $aspect);
          }

          print_debug_debug("The aspect mode with type '$aspectator_type' is used for '$id_attr' model");

          print($file_cmds_log "$log_cmds_aspect->{$aspectator_type}\n");
        }
        elsif ($kind eq 'plain')
        {
          $kind_isplain = 1;
          print_debug_debug("The plain mode is used for '$id_attr' model");

          # Common file should be specified in the plain mode.
          print_debug_trace("Read common file name");
          $common = $files->first_child_text($xml_model_db_files_common)
            or die("Common file isn't specified for the '$id_attr' model");
          print_debug_debug("The common file '$common' is specified for the '$id_attr' model");

          $ldv_model_include_dir = "$ldv_model_dir/" . dirname($common);
          print_debug_debug("Header files will be additionaly searched for in '$ldv_model_include_dir'");

          die("Common file '$ldv_model_dir/$common' doesn't exist (for '$id_attr' model)")
            unless (-f "$ldv_model_dir/$common");

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

      print_debug_trace("Store model information into hash");
      %ldv_model = (
        'id' => $id_attr,
        'kind' => \@kinds,
        'aspect' => $aspect,
        'template' => $template,
        'arg sign' => $arg_sign_algo,
        'script' => $script,
        'common' => $common,
        'config' => $config,
        'engine' => $engine,
        'error' => $error,
        'twig hints' => $hints);

      print($file_cmds_log "$log_cmds_verifier=$ldv_model{'engine'}\n");

      print_debug_debug("The model '$id_attr' information is processed successfully");

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
  print_debug_trace("Options '@ARGV' were passed to the instrument through the command-line");

  unless (GetOptions(
    'basedir|b=s' => \$opt_basedir,
    'cmdfile|c=s' => \$opt_cmd_xml_in,
    'cmdfile-out|o=s' => \$opt_cmd_xml_out,
    'help|h' => \$opt_help,
    'report=s' => \$opt_report_in,
    'report-out=s' => \$opt_report_out,
    'rule-model|m=s' => \$opt_model_id,
    'cache=s' => \$opt_cache_dir,
    'skip-norestrict' => \$opt_skip_restrict_main,
    'suppress-config' => \$opt_suppress_config_check))
  {
    warn("Incorrect options may completely change the meaning! Please run " .
      "script with --help option to see how you may use this tool");
    help();
  }

  help() if ($opt_help);

  print_debug_trace("Check whether report mode is activated");
  if ($opt_report_in && $opt_report_out)
  {
    $report_mode = 1;
    print_debug_debug("Debug mode is active");

    unless(-f $opt_report_in)
    {
      warn("File specified through option --report doesn't exist");
      help();
    }
    print_debug_debug("The input report file is '$opt_report_in'");

    open($file_report_xml_out, '>', "$opt_report_out")
      or die("Couldn't open file '$opt_report_out' specified through option --report-out for write: $ERRNO");
    print_debug_debug("The output report file is '$opt_report_out'");

    unless ($opt_model_id)
    {
      warn("You must specify option --model-id in command-line");
      help();
    }

    print_debug_debug("The model identifier is '$opt_model_id'");

    print_debug_debug("The command-line options are processed successfully");
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
  print_debug_debug("The tool base directory is '$opt_basedir'");

  unless(-f $opt_cmd_xml_in)
  {
    warn("File specified through option --cmdfile|-c doesn't exist");
    help();
  }
  print_debug_debug("The commands input file is '$opt_cmd_xml_in'");

  open($file_xml_out, '>', "$opt_cmd_xml_out")
    or die("Couldn't open file '$opt_cmd_xml_out' specified through option --cmdfile-out|-o for write: $ERRNO");
  print_debug_debug("The commands output file is '$opt_cmd_xml_out'");

  print_debug_debug("The model identifier is '$opt_model_id'");

  print_debug_debug("The command-line options are processed successfully");
}

sub help()
{
    print(STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to perform an instrumentation of
    a source code with a model and report processing.

SYNOPSIS
  $PROGRAM_NAME [option...]

OPTIONS

  -b, --basedir <dir>
    <dir> is an absolute path to a tool working directory.

  --cache <dir>
    <dir> is a directory where cache will be put.

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
    commands generated by the tool.

  --report <file>
    <file> is an absolute path to a xml file containing a rcv report.
    This option is necessary to activate the report mode.

  --report-out <file>
    <file> is an absolute path to a xml file that will contain a
    report generated by the tool. This option is necessary to activate
    the report mode.

  --skip-norestrict
    If this option is given then turn off caching for compilation
    commands that haven't restrict-main

  --suppress-config
    Do not try to look for and alter Kernel config header file.

ENVIRONMENT VARIABLES

  LDV_DEBUG
    It's an optional environment variable that specifies a debug
    level. It uses the standard designatures to distinguish different
    debug information printings. Each next level includes all previous
    levels and its own messages.

  LDV_KERNEL_RULES
    It's an optional environment variable that points to an user
    models directory that will be used instead of the standard one.

  LDV_LLVM_GCC
    It's an optional environment variable that points to an user
    compiler core that will be used instead of the standard one.

  LDV_RULE_INSTRUMENTOR_DEBUG
    Like LDV_DEBUG but it has more priority. It specifies a debug
    level just for this instrument.

  WORK_DIR
    This environment variable is always required. Here the instrument
    places needed auxiliary files and directories that may be used
    during different tool invocations in one major run.

EOM

  exit($error_syntax);
}

sub join_error_desc(@)
{
  my @error_descs = @ARG;
  my @joined_desc = ();
  my $is_first = 1;

  foreach my $error_desc (@error_descs)
  {
    if (ref($error_desc) ne 'ARRAY')
    {
      print_debug_warning("Description '$error_desc' isn't stored as an array reference");
      next;
    }

    if ($is_first)
    {
      push(@joined_desc, @{$error_desc});
      $is_first = 0;
    }
    else
    {
      my $is_empty = 1;

      foreach my $error_desc_str (@{$error_desc})
      {
        unless ($error_desc_str =~ /^\s+$/)
        {
          $is_empty = 0;
          last;
        }
      }

      push(@joined_desc, "\n$log_cmds_desc_ld_cc_separator\n", @{$error_desc})
        if (!$is_empty);
    }
  }

  return \@joined_desc;
}

sub prepare_files_and_dirs()
{
  print_debug_trace("Try to find global working directory");
  unless ($WORK_DIR)
  {
    warn("The work directory isn't specified by means of WORK_DIR environment variable");
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
  print_debug_debug("The tool auxiliary working directory: '$tool_aux_dir'");

  print_debug_trace("Try to open a commands log file '$tool_aux_dir/$tool_cmds_log'");
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
  print_debug_debug("The commands log file: '$tool_aux_dir/$tool_cmds_log'");

  $ldv_timeout_script_output = "$tool_aux_dir/$tool_stats_xml";
  print_debug_debug("The timeout script will put data to the file '$ldv_timeout_script_output'");

  # The rest isn't needed for the report mode.
  return 0 if ($report_mode);

  unless (-d "$tool_aux_dir/$tool_config_dir")
  {
    mkpath("$tool_aux_dir/$tool_config_dir")
      or die("Couldn't recursively create directory '$tool_aux_dir/$tool_config_dir': $ERRNO");
  }
  $tool_config_dir = "$tool_aux_dir/$tool_config_dir";
  print_debug_debug("The tool configurations directory: '$tool_config_dir'");

  $tool_model_common_dir = "$tool_aux_dir/$tool_model_common_dir";
  unless (-d $tool_model_common_dir)
  {
    mkpath($tool_model_common_dir)
      or die("Couldn't recursively create directory '$tool_model_common_dir': $ERRNO");
  }
  print_debug_debug("The tool common model directory: '$tool_model_common_dir'");

  # LDV_HOME is obtained through directory of rule-instrumentor.
  # It is assumed that there is such organization of LDV_HOME directory:
  # /LDV_HOME/
  #   bin/
  #     rule_instrumentor.pl (this script)
  #   rule_instrumentor/
  #     aspectator/
  #       bin/
  #         symlinks to aspectator script, gcc, linker, c-backend and so on.
  print_debug_trace("Try to find the instrument absolute path");
  $ldv_rule_instrumentor_abs = abs_path($0)
    or die("Can't obtain absolute path of '$0'");
  print_debug_debug("The instrument absolute path is '$ldv_rule_instrumentor_abs'");

  print_debug_trace("Try to find the instrument directory");
  @ldv_rule_instrumentor_path = fileparse($ldv_rule_instrumentor_abs)
    or die("Can't find directory of file '$ldv_rule_instrumentor_abs'");
  $ldv_rule_instrumentor_dir = $ldv_rule_instrumentor_path[1];
  print_debug_debug("The instrument directory is '$ldv_rule_instrumentor_dir'");

  print_debug_trace("Obtain the LDV_HOME as earlier as possible");
  $ldv_rule_instrumentor_dir =~ /\/bin\/*$/;
  $LDV_HOME = $PREMATCH;
  unless(-d $LDV_HOME)
  {
    warn("The directory '$LDV_HOME' (LDV home directory) doesn't exist");
    help();
  }
  print_debug_debug("The LDV_HOME is '$LDV_HOME'");

  print_debug_trace("Obtain the directory where all instrumentor auxiliary tools (such as aspectator) are placed");
  $ldv_rule_instrumentor = "$LDV_HOME/ri";
  unless(-d $ldv_rule_instrumentor)
  {
    warn("Directory '$ldv_rule_instrumentor' (rule instrumentor directory) doesn't exist");
    help();
  }

  print_debug_trace("Obtain absolute path for RI common aspect file");
  $ri_aspect = "$ldv_rule_instrumentor/$ri_aspect";
  unless(-f $ri_aspect)
  {
    warn("File '$ri_aspect' doesn't exist");
    help();
  }
  print_debug_debug("RI common aspect file is '$ri_aspect'");

  $ldv_timeout_script = "$LDV_HOME/shared/sh/timeout";
  unless(-f $ldv_timeout_script)
  {
    warn("File '$ldv_timeout_script' doesn't exist");
    help();
  }
  print_debug_debug("The timeout script is '$ldv_timeout_script'");

  my $ldv_rule_instrumentor_patterns_str = join(';', @ldv_rule_instrumentor_patterns);
  print_debug_debug("The rule instrumentor processes patterns are: '$ldv_rule_instrumentor_patterns_str'");

  @ldv_timeout_script_opts = ("--pattern=$ldv_rule_instrumentor_patterns_str", "--output=$ldv_timeout_script_output");
  print_debug_debug("The ldv timeout script options are '@ldv_timeout_script_opts'");

  print_debug_debug("The instrument auxiliary tools directory is '$ldv_rule_instrumentor'");

  # LLVM backend is optional, and may be not included into the shippment
  if ($supported_backends{'llvm'}){
    # Directory contains all binaries needed by aspectator.
    $ldv_llvm_aspectator_bin_dir = "$ldv_rule_instrumentor/aspectator/llvm-2.6/bin";
    unless(-d $ldv_llvm_aspectator_bin_dir)
    {
      warn("Directory '$ldv_llvm_aspectator_bin_dir' (LLVM aspectator binaries directory) doesn't exist");
      help();
    }
    print_debug_debug("The llvm aspectator binaries directory is '$ldv_llvm_aspectator_bin_dir'");

    # Aspectator script.
    $ldv_llvm_aspectator = "$ldv_llvm_aspectator_bin_dir/compiler";
    unless(-f $ldv_llvm_aspectator)
    {
      warn("File '$ldv_llvm_aspectator' (aspectator) doesn't exist");
      help();
    }
    print_debug_debug("The LLVM aspectator script (compiler) is '$ldv_llvm_aspectator'");

    # C backend.
    $ldv_llvm_c_backend = "$ldv_llvm_aspectator_bin_dir/c-backend";
    unless(-f $ldv_llvm_c_backend)
    {
      warn("File '$ldv_llvm_c_backend' (LLVM C backend) doesn't exist");
      help();
    }
    print_debug_debug("The LLVM C backend is '$ldv_llvm_c_backend'");

    # GCC compiler with aspectator extensions that is used by aspectator
    # script.
    $ldv_llvm_gcc = "$ldv_llvm_aspectator_bin_dir/compiler-core";
    unless(-f $ldv_llvm_gcc)
    {
      warn("File '$ldv_llvm_gcc' (LLVM GCC compiler) doesn't exist");
      help();
    }
    print_debug_debug("The LLVM GCC compiler (compiler core) is '$ldv_llvm_gcc'");

    # Linker.
    $ldv_llvm_linker = "$ldv_llvm_aspectator_bin_dir/linker";
    unless(-f $ldv_llvm_linker)
    {
      warn("File '$ldv_llvm_linker' (LLVM linker) doesn't exist");
      help();
    }
    print_debug_debug("The LLVM linker is '$ldv_llvm_linker'");
  }

  # GCC aspectator backend is included into the default shippment, but just in case...
  if ($supported_backends{'gcc'}){
    # Directory contains all binaries needed by aspectator.
    $ldv_gcc_aspectator_bin_dir = "$ldv_rule_instrumentor/bin";
    unless(-d $ldv_gcc_aspectator_bin_dir)
    {
      warn("Directory '$ldv_gcc_aspectator_bin_dir' (aspectator binaries directory) doesn't exist");
      help();
    }
    print_debug_debug("The aspectator binaries directory is '$ldv_gcc_aspectator_bin_dir'");

    # Aspectator script.
    $ldv_gcc_aspectator = "$ldv_gcc_aspectator_bin_dir/compiler";
    unless(-f $ldv_gcc_aspectator)
    {
      warn("File '$ldv_gcc_aspectator' (aspectator) doesn't exist");
      help();
    }
    print_debug_debug("The aspectator script (compiler) is '$ldv_gcc_aspectator'");
  }

  # Use environment variable for the models directory instead of the standard
  # one from the LDV_HOME.
  if ($LDV_KERNEL_RULES)
  {
    $ldv_model_dir = abs_path($LDV_KERNEL_RULES)
      or die("Can't obtain absolute path of '$LDV_KERNEL_RULES'");;
    print_debug_debug("The models directory specified through 'LDV_KERNEL_RULES' environment variable is '$ldv_model_dir'");
  }
  else
  {
    $ldv_model_dir = "$LDV_HOME/kernel-rules";
    print_debug_debug("The models directory is '$ldv_model_dir'");
  }

  # Use environment variable for the compiler core instead of the the standard
  # one from the LDV_HOME.
  if ($LDV_LLVM_GCC)
  {
    # Just make auxiliary name for the standard exported path to the compiler
    # core. So the environment variable will be used.
    $ldv_aspectator_gcc .= '_AUX';
  }

  print_debug_trace("Check whether the models are installed properly");
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
  print_debug_debug("The models database xml file is '$ldv_model_db_xml'");

  # Initialize cache directory
  $do_cache = defined($opt_cache_dir);
  if ($do_cache)
  {
    $skip_cache_without_restrict = defined($opt_skip_restrict_main);
    $ri_cache_dir = $opt_cache_dir;
    if (!-d $ri_cache_dir)
    {
      mkpath($ri_cache_dir)
        or die("Couldn't recursively create directory '$ri_cache_dir': $ERRNO");
    }
    print_debug_debug("The cache directory is '$ri_cache_dir'");
  }

  print_debug_debug("Files and directories are checked and prepared successfully");
}

sub print_cmd_log($)
{
  my $log_ref = shift;
  my %log = %{$log_ref};

  die("The command isn't specified in the command log")
    unless (defined($log{'cmd'}));
  die("The command status isn't specified in the command log")
    unless (defined($log{'status'}));
  die("The command execution time isn't specified in the command log")
    unless (defined($log{'time'}));
  die("The command id isn't specified in the command log")
    unless (defined($log{'id'}));
  die("The command check attribute isn't specified in the command log")
    unless (defined($log{'check'}));
  die("The command entries reference isn't specified in the command log")
    unless (defined($log{'entries'}));
  die("The command execution description isn't specified in the command log")
    unless (defined($log{'desc'}));

  # We put description in the special quotes since it may contain undefined
  # number of lines and undefined symbols.
  print($file_cmds_log "$log{'cmd'}:$log{'status'}:$log{'time'}:$log{'id'}:$log{'check'}:@{$log{'entries'}}:\n${log_cmds_desc_begin}\n");
  foreach my $str (@{$log{'desc'}})
  {
    print($file_cmds_log $str);
  }
  print($file_cmds_log "\n${log_cmds_desc_end}\n");
}

sub process_cmd_cc()
{
  my ($cmd,%cmd) = @_;
      #%cmd = (
        #'id' => $id_attr,
        #'cwd' => $cwd_text,
        #'ins' => \@ins_text,
        #'out' => $out_text,
        #'check' => $check_text,
        #'restrict-main' => $restrict_main,
        #'opts' => \@opts);

  my $kind_gcc = ($kind_isaspect && $aspectator_type eq 'gcc');

  # Remember compilation options for the first CC comand to use them further
  # for a common model preprocessing.
  unless ($ldv_model_common_opts)
  {
    $ldv_model_common_opts = $cmd{'opts'};
    $ldv_model_common_cwd = $cmd{'cwd'};
  }

  if ($kind_isaspect)
  {
    print_debug_debug("The command '$cmd{'id'}' is specifically processed for the aspect mode");

    my $aspect = $ldv_model{'aspect'};

    # On each cc command we run aspectator on corresponding file with
    # corresponding model aspect and options.
    print_debug_debug("Process the cc '$cmd{'id'}' command using usual aspect");
    # Specify needed and specic environment variables for the aspectator.
    # Specify a path where a common model will be placed.
    $ENV{'LDV_COMMON_MODEL'} = "$tool_model_common_dir/$ldv_model_common";
    # Some aspect models can omit a common model, so create an empty common
    # in any case.
    my $touch_cmd = "touch '$ENV{LDV_COMMON_MODEL}'";
    print_debug_info("Execute the command '$touch_cmd'");
    system($touch_cmd);
    die("Can't touch file '$ENV{LDV_COMMON_MODEL}'") if (check_system_call());

    # Input file to be instrumented.
    my $in = ${$cmd{'ins'}}[0];

    # Options to be used for instrumentation.
    my @opts = @{$cmd{'opts'}};

    # Output file.
    my $out = $cmd{'out'};
    # Source code output.
    my $out_src = "$out.c";

    # Specify argument signature extraction algorithm if it's specified in model
    # database and isn't specified via environment variable.
    my $arg_sign_algo = $ldv_model{'arg sign'};
    $ENV{'LDV_ARG_SIGN'} = $arg_sign_algo
      if ($arg_sign_algo and !$ENV{'LDV_ARG_SIGN'});

    # Generate aspect file by means of script if this is required.
    if ($ldv_model{'script'})
    {
      my $id = $cmd{'id'};
      my $script = $ldv_model{'script'};
      my $template = $ldv_model{'template'};

      my $script_dir = "$ldv_model_dir/scripts";
      my $rerouter_script = "$script_dir/$script";
      open(REROUTER, '<', $rerouter_script)
        or die("Can't open file '$rerouter_script' for read: $ERRNO");
      my $rerouter = join("", <REROUTER>);
      close(REROUTER)
        or die("Can't close file handler for '$rerouter_script': $ERRNO");

      print_debug_info("Evaluate rerouter");
      eval("$rerouter\n0;");

      die("Can't produce aspect file by means of rerouter '$rerouter_script': $EVAL_ERROR")
        if ($EVAL_ERROR);

      # Finish futher processing until all argument signatures will be gathered.
      return (0, []) if ($isgather_arg_signs);

      # Generate aspect to be used in instrumenation just one time.
      undef($ldv_model{'script'});
    }

    # Create a special file for aspectator to hold unique number through
    # different CC commands (#927).
    my $unique_numb_file = "$tool_aux_dir/unique_numb";
    $ENV{'LDV_UNIQUE_NUMB'} = $unique_numb_file;
    unless (-f $unique_numb_file)
    {
      open(UNIQUE_NUMB, '>', $unique_numb_file)
        or die("Can't open file '$unique_numb_file' for write: $ERRNO");
      # To start unique numbers from 1 make "previous" value to be 0.
      print(UNIQUE_NUMB "0");
      close(UNIQUE_NUMB)
        or die("Can't close file handler for '$unique_numb_file': $ERRNO");
    }

    my @keep = ();

    # Keep CIF intermediate files for debug levels higher then DEBUG.
    push(@keep, '--keep') if (LDV::Utils::check_verbosity('DEBUG'));
    
    # To fix issue #1285 (http://forge.ispras.ru/issues/1285).
    foreach (@opts)
    {
      s/\"/\\\"/g;
    }

    my @args = (
      $ldv_timeout_script,
      @ldv_timeout_script_opts,
      "--reference=$cmd{'id'}",
      $ldv_aspectator
        , '--debug', $debug_level
        # Always keep prepared file since error traces can reference it.
        , '--keep-prepared-file'
        , @keep
        , '--in', $in
        , '--aspect', $ldv_model{'aspect'}
        , '--back-end', 'src'
        , '--out', $out_src
        # Add kernel-rules as a directory to be searched for (aspect) header
        # files to be included.
        , '--general-opts', "-I$ldv_model_dir"
        , '--aspect-preprocessing-opts', "--include $ri_aspect"
        # Escape explicitly all options because of DEG missed this.
        , '--', map("\"$ARG\"", @opts)
    );

    print_debug_trace("Go to the build directory to execute cc command");

    # Aspectators generate two files here.  The first is aspectated code
    # (llvm-based aspectator generates aspectated bitcode, and gcc-based
    # aspectator generates aspectated preprocessed code), and the second is .p
    # file generated after 1st stage (referred to by error traces). .p is common
    # for both supported aspectators, and the first file suffix differs

    my $aspectated_suffix_generated = undef;
    my $preprocessed_suffix = undef;

    if ($aspectator_type eq 'gcc')
    {
      $aspectated_suffix_generated = $gcc_suffix_aspect;
      $preprocessed_suffix = $gcc_preprocessed_suffix;
    }
    elsif ($aspectator_type eq 'llvm')
    {
      $aspectated_suffix_generated = $llvm_bitcode_suffix;
      $preprocessed_suffix = $llvm_preprocessed_suffix;
    }
    else {die};

    my ($status, $desc);

    # Get target file cache key.
    my $cache_target = "$cmd{'out'}$aspectated_suffix_generated";
    my $cache_file_key = $cache_target;
    $cache_file_key =~ s/^$opt_basedir//;
    print_debug_debug("The target file cache key is '$cache_file_key'");

    # Get target preprocessed file cache key.
    my $preprocessed_cache_target = "${$cmd{'ins'}}[0]$preprocessed_suffix";
    my $preprocessed_cache_file_key = $preprocessed_cache_target;
    $preprocessed_cache_file_key =~ s/^$opt_basedir//;
    print_debug_debug("The preprocessed target file cache key is '$preprocessed_cache_file_key'");

    # Understand whether cache must be skipped.
    my $skip_caching = $skip_cache_without_restrict && !$cmd{'restrict-main'};

    if (!$skip_caching && copy_from_cache($cache_target, $opt_model_id, $cache_file_key))
    {
      # Cache hit.
      print_debug_info("Got file from cache instead of executing '@args'");
      $status = string_from_cache($opt_model_id, "$cache_file_key-status");
      chomp($status);
      print_debug_trace("The cached status is '$status'");
      $desc = [split('\n', string_from_cache($opt_model_id, "$cache_file_key-desc"))];
      print_debug_trace("The cached description is '@$desc'");

      # Copy the preprocessed file from cache.
      copy_from_cache($preprocessed_cache_target, $opt_model_id, $preprocessed_cache_file_key);

      # Return on failure.
      return ($status, $desc) if ($status);
    }
    else
    {
      # Cache miss.
      chdir($cmd{'cwd'})
        or die("Can't change directory to '$cmd{'cwd'}'");

      print_debug_info("Execute the command '@args'");
      ($status, $desc) = exec_status_and_desc(@args);

      if (!$skip_caching)
      {
        print_debug_trace("Save the information obtained to cache (even if it's a failure)");
        string_to_cache($status, $opt_model_id, "$cache_file_key-status");
        string_to_cache(join("\n", @$desc), $opt_model_id, "$cache_file_key-desc");
      }
      else
      {
        print_debug_info("Didn't cache file with main due to --skip-norestrict");
      }

      # Return on failure.
      return ($status, $desc) if ($status);

      # Unset special environments variables.
      delete($ENV{'LDV_COMMON_MODEL'});

      print_debug_trace("Go to the initial directory");
      chdir($tool_working_dir)
        or die("Can't change directory to '$tool_working_dir'");

      die("Something wrong with aspectator: it doesn't produce file '$out_src'")
        unless (-f $out_src);
      print_debug_debug("The aspectator produces the usual bitcode/source file '$out_src'");

      # Save the result to cache.
      save_to_cache($cache_target, $opt_model_id, $cache_file_key)
        unless ($skip_caching);

      # Save the preprocessed file needed for further visualization.
      save_to_cache($preprocessed_cache_target, $opt_model_id, $preprocessed_cache_file_key)
        unless ($skip_caching);
    }

    # GCC aspectator deletes the files on its own
    $files_to_be_deleted{"$cmd{'out'}$aspectated_suffix_generated"} = 1 unless $kind_gcc;

    print_debug_trace("Go to the initial directory");
    chdir($tool_working_dir)
      or die("Can't change directory to '$tool_working_dir'");

    # If we're in GCC aspectator mode, we should print a modified CC command just like in plain mode
    if ($kind_gcc){
      my $cmd_updated = new XML::Twig::Elt('cc',{'id' => $cmd{'id'}});
      new XML::Twig::Elt('cwd',$tool_working_dir)->paste('last_child',$cmd_updated);
      new XML::Twig::Elt('in',$out_src)->paste('last_child',$cmd_updated);
      new XML::Twig::Elt('out',$out)->paste('last_child',$cmd_updated);
      add_engine_tag($cmd_updated);
      $cmd_updated->print($file_xml_out);
    }

    return (0, $desc);
  }
  elsif ($kind_isplain)
  {
    print_debug_debug("The command '$cmd{'id'}' is specifically processed for the plain mode");

    add_engine_tag($cmd);

    # Exchange the existing options with the processed ones.
    $cmd->cut_children($xml_cmd_opt);
    foreach my $opt (@{$cmd{'opts'}})
    {
      new XML::Twig::Elt($xml_cmd_opt, $opt)->paste('last_child',$cmd);
    }

    # Add -I option with a path to a directory to find appropriate headers for
    # driver files since they may include some model headers.
    print_debug_trace("For CC command add '$ldv_model_dir' and '$ldv_model_include_dir' directories to be searched for headers");
    my $opt = new XML::Twig::Elt('opt' => "-I$ldv_model_dir");;
    $opt->paste('last_child', $cmd);
    $opt = new XML::Twig::Elt('opt' => "-I$ldv_model_include_dir");;
    $opt->paste('last_child', $cmd);

    # FIXME
    print_debug_trace("Print the modified command");
    $cmd->print($file_xml_out);

    # Add "common" source code to one of the input files in this CC command.
    print_debug_debug("Duplicate an each cc command with the one containing a common model");
    my $common_model_cc = $cmd->copy;

    print_debug_trace("Change an id attribute");
    $common_model_cc->set_att($xml_cmd_attr_id => $cmd->att($xml_cmd_attr_id) . $id_common_model_suffix);

    # Note that this generated file is always keeped since it's needed for
    # report visualization.
    print_debug_trace("Concatenate a common model with the first input file");

    # Dirty hack for 39_7 and 116 models; should be resolved with properly written aspect!
    if ( $opt_model_id eq "39_7" || $opt_model_id eq "116_7" )
    {
      my $in = $cmd->first_child($xml_cmd_in);
      my $in_file = $in->text;

      die("The specified input file '$in_file' doesn't exist.")
        unless ($in_file and -f $in_file);

      my @decls = ("void ldv_spin_lock_irqsave(spinlock_t *lock, unsigned long flags);",
                "void ldv_spin_lock_nested(spinlock_t *lock, int subclass);",
                "void ldv_spin_lock_nest_lock(spinlock_t *lock, void *map);",
                "void ldv_spin_lock_irqsave_nested(spinlock_t *lock, unsigned long flags, int subclass);",
                "int ldv_spin_trylock_irqsave(spinlock_t *lock, unsigned long flags);",
                "void ldv_spin_lock(spinlock_t *lock);",
                "void ldv_spin_lock_bh(spinlock_t *lock);",
                "void ldv_spin_lock_irq(spinlock_t *lock);",
                "int ldv_spin_trylock(spinlock_t *lock);",
                "int ldv_spin_trylock_bh(spinlock_t *lock);",
                "int ldv_spin_trylock_irq(spinlock_t *lock);",
                "void ldv_spin_unlock(spinlock_t *lock);",
                "void ldv_spin_unlock_bh(spinlock_t *lock);",
                "void ldv_spin_unlock_irq(spinlock_t *lock);",
                "void ldv_spin_unlock_irqrestore(spinlock_t *lock, unsigned long flags);",
                "void ldv_spin_unlock_wait(spinlock_t *lock);",
                "int ldv_spin_is_locked(spinlock_t *lock);",
                "int ldv_spin_is_contended(spinlock_t *lock);",
                "int ldv_spin_can_lock(spinlock_t *lock);",
                "int ldv_atomic_dec_and_lock(spinlock_t *lock, atomic_t *atomic);".
    "\n#define ldv_atomic_dec_and_lock_macro(atomic,lock) ldv_atomic_dec_and_lock(lock,atomic)",
                "void ldv_local_irq_disable(void);",
                "void ldv_local_irq_enable(void);",
                "void ldv_local_irq_save(unsigned long flags);",
                "void ldv_local_irq_restore(unsigned long flags);"
               );
      my @keys = ("spin_lock_irqsave",
               "spin_lock_nested",
               "spin_lock_nest_lock",
               "spin_lock_irqsave_nested",
               "spin_trylock_irqsave",
               "spin_lock",
               "spin_lock_bh",
               "spin_lock_irq",
               "spin_trylock",
               "spin_trylock_bh",
               "spin_trylock_irq",
               "spin_unlock",
               "spin_unlock_bh",
               "spin_unlock_irq",
               "spin_unlock_irqrestore",
               "spin_unlock_wait",
               "spin_is_locked",
               "spin_is_contended",
               "spin_can_lock",
               "atomic_dec_and_lock",
               "local_irq_disable",
               "local_irq_enable",
               "local_irq_save",
               "local_irq_restore"
              );
      my @replacements = ("ldv_spin_lock_irqsave",
                       "ldv_spin_lock_nested",
                       "ldv_spin_lock_nest_lock",
                       "ldv_spin_lock_irqsave_nested",
                       "ldv_spin_trylock_irqsave",
                       "ldv_spin_lock",
                       "ldv_spin_lock_bh",
                       "ldv_spin_lock_irq",
                       "ldv_spin_trylock",
                       "ldv_spin_trylock_bh",
                       "ldv_spin_trylock_irq",
                       "ldv_spin_unlock",
                       "ldv_spin_unlock_bh",
                       "ldv_spin_unlock_irq",
                       "ldv_spin_unlock_irqrestore",
                       "ldv_spin_unlock_wait",
                       "ldv_spin_is_locked",
                       "ldv_spin_is_contended",
                       "ldv_spin_can_lock",
                     "ldv_atomic_dec_and_lock_macro",
                       "ldv_local_irq_disable",
                       "ldv_local_irq_enable",
                       "ldv_local_irq_save",
                       "ldv_local_irq_restore"
                      );

      print_debug_trace("Replace defines by model functions for model ".$opt_model_id);
      my $tmpfile = $in_file.".bak";
      rename($in_file, $tmpfile)
       or die("Can't rename inputfile '$in_file' to '$tmpfile'");
      open(OUT, '>',$in_file)
        or die("Can't open file '$in_file' for write: $ERRNO");
      open(IN, '<', "$tmpfile")
        or die("Can't open file '$in_file' for read: $ERRNO");

      print OUT "#include <linux/spinlock.h>\n";
      for (my $count = 0; $count < scalar(@keys); $count++) {
        # This was intended for debugging only
        #print "Add decls for keys['$count']=".$keys[$count];
        my $decl = $decls[$count];
        print OUT $decl."\n";
      }
      while(<IN>) {
        for (my $count = 0; $count < scalar(@keys); $count++) {
          my $key = $keys[$count];
          my $replacement = $replacements[$count];
          $_ =~ s/\b$key\b/$replacement/g;
        }
        print OUT $_;
      }
      close(IN)
        or die("Couldn't close file '$tmpfile': $ERRNO\n");
      close(OUT)
        or die("Couldn't close file '$in_file': $ERRNO\n");
      #system('perl', '-p', '-i.bak', '-e', "s/".$key."/".$replacement."/g")
      #  or die("Can't replace content of the file '$in_file'");
    }

    print_debug_debug("Finish processing of the command having id '$cmd{'id'}' in the plain mode");

    return (0, []);
  }
}

sub process_cmd_ld()
{
  my ($cmd,%cmd) = @_;
      #%cmd = (
        #'id' => $id_attr,
        #'cwd' => $cwd_text,
        #'ins' => \@ins_text,
        #'out' => $out_text,
        #'check' => $check_text,
        #'restrict-main' => $restrict_main,
        #'opts' => \@opts);
  # Backporting code: add $idattr for convenience
  my $id_attr = $cmd{'id'};

  my $ischeck = $cmd{'check'} eq 'true';

  my $kind_gcc = ($kind_isaspect && $aspectator_type eq 'gcc');

  if ($kind_isaspect && $aspectator_type eq 'llvm')
  {
    print_debug_debug("The command '$cmd{'id'}' is specifically processed for the aspect mode");

    print_debug_debug("Prepare a C file to be checked for the ld command marked with 'check = \"true\"'");

    if ($ischeck)
    {
      # On each ld command we run llvm linker for all input files together to
      # produce one linked file. Note that excactly one file to be linked must
      # be generally (i.e. with usual and common aspects) instrumented. We
      # choose the first one here. Other files must be usually instrumented.
      my @ins = @{$cmd{'ins'}};
      my @args = (
        $ldv_timeout_script,
        @ldv_timeout_script_opts,
        "--reference=$cmd{'id'}",
        $ldv_llvm_linker, @llvm_linker_opts, @ins, '-o', "$cmd{'out'}");

      print_debug_trace("Go to the build directory to execute ld command");
      chdir($cmd{'cwd'})
        or die("Can't change directory to '$cmd{'cwd'}'");

      # NOTE that caching linker's output is not worth it. Linking is usually
      # done once per driver, and its result is not reused.

      print_debug_info("Execute the command '@args'");
      my ($status, $desc) = exec_status_and_desc(@args);
      return ($status, $desc) if ($status);

      print_debug_trace("Go to the initial directory");
      chdir($tool_working_dir)
        or die("Can't change directory to '$tool_working_dir'");

      die("Something wrong with linker: it doesn't produce file '$cmd{'out'}'")
        unless (-f "$cmd{'out'}");
      $files_to_be_deleted{"$cmd{'out'}"} = 1;
      print_debug_debug("The linker produces the linked bitcode file '$cmd{'out'}'");

      # Make name for c file corresponding to the linked one.
      my $c_out = "$cmd{'out'}$llvm_c_backend_suffix";

      # Linked file is converted to c by means of llvm c backend.
      @args = (
        $ldv_timeout_script,
        @ldv_timeout_script_opts,
        "--reference=$cmd{'id'}",
        $ldv_llvm_c_backend, @llvm_c_backend_opts, "$cmd{'out'}", '-o', $c_out);

      print_debug_info("Execute the command '@args'");
      ($status, $desc) = exec_status_and_desc(@args);
      return ($status, $desc) if ($status);

      die("Something wrong with aspectator: it doesn't produce file '$c_out'")
        unless (-f "$c_out");
      print_debug_debug("The C backend produces the C file '$c_out'");

      print_debug_trace("Print the corresponding commands to the output xml file");
      $xml_writer->startTag('cc', 'id' => "$cmd{'id'}$id_cc_llvm_suffix");
      $xml_writer->dataElement('cwd' => $cmd{'cwd'});
      $xml_writer->dataElement('in' => $c_out);
      # Use here the first input file name to relate with corresponding ld
      # command.
      $xml_writer->dataElement('out' => ${$cmd{'ins'}}[0]);
      # FIXME: replace with add_engine_tag
      $xml_writer->dataElement('engine' => $ldv_model{'engine'});
      # Close the cc tag.
      $xml_writer->endTag();

      $xml_writer->startTag('ld', 'id' => "$cmd{'id'}$id_ld_llvm_suffix");
      $xml_writer->dataElement('cwd' => $cmd{'cwd'});
      $xml_writer->dataElement('in' => ${$cmd{'ins'}}[0]);
      $xml_writer->dataElement('out' => "$cmd{'out'}");
      # FIXME: replace with add_engine_tag
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
    else
    {
      # On each ld command we run llvm linker for all input files together to
      # produce one linked file.
      my @ins = @{$cmd{'ins'}};
      my @args = ($ldv_llvm_linker, @llvm_linker_opts, @ins, '-o', "$cmd{'out'}");

      print_debug_trace("Go to the build directory to execute ld command");
      chdir($cmd{'cwd'})
        or die("Can't change directory to '$cmd{'cwd'}'");

      print_debug_info("Execute the command '@args'");
      my ($status, $desc) = exec_status_and_desc(@args);
      return ($status, $desc) if ($status);

      print_debug_trace("Go to the initial directory");
      chdir($tool_working_dir)
        or die("Can't change directory to '$tool_working_dir'");

      die("Something wrong with linker: it doesn't produce file '$cmd{'out'}'")
        unless (-f "$cmd{'out'}");
      $files_to_be_deleted{"$cmd{'out'}"} = 1;
      print_debug_debug("The linker produces the linked bitcode file '$cmd{'out'}'");
    }

    # Status is ok, description is empty.
    return (0, []);
  }
  elsif($kind_isplain || $kind_gcc)
  {
    # Create an auxiliary CC comand to link a common model with all other
    # source files that form a driver (module).
    if ($ischeck)
    {
      my $cmd_cc_aux = new XML::Twig::Elt('cc');
      $cmd_cc_aux->set_att('id' => "$id_attr-common-model");

      my $cmd_cc_aux_cwd = new XML::Twig::Elt('cwd', $ldv_model_common_cwd);
      $cmd_cc_aux_cwd->paste('last_child', $cmd_cc_aux);

      if ($kind_isplain)
        {
          print_debug_trace("Copy a common model to a common model directory");
          copy("$ldv_model_dir/$ldv_model{common}", "$tool_model_common_dir/$ldv_model_common") or
            die("Can't copy from '$ldv_model_dir/$ldv_model{common}' to '$tool_model_common_dir/$ldv_model_common'");
        }

      my $cmd_cc_aux_in = new XML::Twig::Elt('in', "$tool_model_common_dir/$ldv_model_common");
      $cmd_cc_aux_in->paste('last_child', $cmd_cc_aux);

      foreach my $ldv_model_common_opt (@{$ldv_model_common_opts})
      {
        my $cmd_cc_aux_opt = new XML::Twig::Elt('opt', $ldv_model_common_opt);
        $cmd_cc_aux_opt->paste('last_child', $cmd_cc_aux);
      }

      # Add -I option with a path to a directory to find appropriate headers for
      # models..
      print_debug_trace("For auxiliary CC command add '$ldv_model_dir' and '$ldv_model_include_dir' directories to be searched for headers");
      my $cmd_cc_aux_opt = new XML::Twig::Elt('opt' => "-I$ldv_model_dir");
      $cmd_cc_aux_opt->paste('last_child', $cmd_cc_aux);
      $cmd_cc_aux_opt = new XML::Twig::Elt('opt' => "-I$ldv_model_include_dir");
      $cmd_cc_aux_opt->paste('last_child', $cmd_cc_aux);

      my $cmd_cc_aux_out = new XML::Twig::Elt('out', "$tool_model_common_dir/$ldv_model_common_o");
      $cmd_cc_aux_out->paste('last_child', $cmd_cc_aux);

      print_debug_trace("Print auxiliary common model CC command");
      $cmd_cc_aux->print($file_xml_out);

      print_debug_trace("Specify a common model file for ld command");
      my $cmd_ld_aux_in = new XML::Twig::Elt('in', "$tool_model_common_dir/$ldv_model_common_o");
      $cmd_ld_aux_in->paste('last_child', $cmd);
    }

    print_debug_trace("For the ld command add error tag");
    my $xml_error_tag = new XML::Twig::Elt('error', $ldv_model{'error'});
    $xml_error_tag->paste('last_child', $cmd);

    print_debug_trace("For the ld command copy hints as them");
    my $twig_hints = $ldv_model{'twig hints'}->copy;
    $twig_hints->paste('last_child', $cmd);

    add_engine_tag($cmd);

    # FIXME
    print_debug_trace("Print the modified command");
    $cmd->print($file_xml_out);

    print_debug_debug("Finish processing of the command having id '$cmd{'id'}' in the plain mode");
    # Status is ok, description is empty.
    return (0, []);
  }
}

sub process_cmds()
{
  print_debug_trace("Read commands input xml file '$opt_cmd_xml_in'");
  $xml_twig->parsefile("$opt_cmd_xml_in");

  print_debug_trace("Read xml root tag");
  my $cmd_root = $xml_twig->root;

  print_debug_trace("Obtain all commands");
  my @cmds = $cmd_root->children;

  print_debug_trace("Iterate over all commands to execute them and write output xml file");
  print_debug_trace("Gather argument signatures for all cc comands specified first of all");
  $isgather_arg_signs = 1
    if ($ldv_model{'script'});
  for (my $i = 0; $i < ($ldv_model{'script'} ? 2 : 1); $i++)
  {
  $isgather_arg_signs = 0 if ($i > 0);
  foreach my $cmd (@cmds)
  {
    # At the beginning instrumentor basedir must be specified.
    if ($cmd->gi eq $xml_cmd_basedir)
    {
      $cmd_basedir = $cmd->text;
      print_debug_debug("The base directory '$cmd_basedir' is specified");

      print_debug_trace("Use the tool base directory '$opt_basedir' instead of the specified one in the plain mode");
      $cmd->set_text($opt_basedir);
      $cmd->print($file_xml_out);
    }
    # Interpret cc and ld commands.
    elsif ($cmd->gi eq $xml_cmd_cc or $cmd->gi eq $xml_cmd_ld)
    {
      die("A base directory isn't specified in input commands xml file")
        unless ($cmd_basedir);

      # General commands section.
      print_debug_trace("Read id for some command");
      my $id_attr = $cmd->att($xml_cmd_attr_id)
        // die("The input commands xml file doesn't contain '$xml_cmd_attr_id' attribute for some command");
      print_debug_debug("Begin processing of the command '" . $cmd->gi . "' having id '$id_attr'");

      print_debug_trace("Read current working directory");
      my $cwd = $cmd->first_child($xml_cmd_cwd)
        or die("The input commands xml file doesn't contain '$xml_cmd_cwd' tag for '$id_attr' command");
      my $cwd_text = $cwd->text;
      die("The input commands xml file specifies directory '$cwd_text' that doesn't exist for '$id_attr' command")
        unless ($cwd_text and -d $cwd_text);
      print_debug_debug("The specified current working directory is '$cwd_text'");

      print_debug_trace("Read output file name");
      my $out = $cmd->first_child($xml_cmd_out)
        // die("The input commands xml file doesn't contain '$xml_cmd_out' tag for '$id_attr' command");
      my $out_text = $out->text;
      print_debug_debug("The output file is '$out_text'");

      # Attribute that says whether file must be checked or not. Note that there
      # may be not such attribute for the given command at all.
      print_debug_trace("Read check");
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
      print_debug_debug("The attribute check leads to '$check_text' check (this has sence just for ld command)");

      # Calculate if this command has main, and should not be cached.
      my $restrict_main = 1;

      print_debug_trace("Read array of input file names");
      my @ins;
      my @ins_text;
      for (my $in = $cmd->first_child($xml_cmd_in)
        ; $in
        ; $in = $in->next_elt($xml_cmd_in))
      {
        push(@ins, $in);
        push(@ins_text, $in->text);

        # Attribute that says whether there should not be main for this file.
        # We don't cache files with mains (if --no-cache-restricts is specified).
        print_debug_trace("Restrict-main check");
        my $restrict_attr = $in->att($xml_cmd_attr_restrict);
        $restrict_main &&= ($restrict_attr and $restrict_attr eq 'main');
        $restrict_main ||= '';  # Convert to printable string.
        print_debug_debug("The attribute restrict leads to '$restrict_main' (makes sense for caching)");

        last if ($in->is_last_child($xml_cmd_in));
      }
      die("The input commands xml file doesn't contain '$xml_cmd_in' tag for '$id_attr' command")
        unless (scalar(@ins));
      print_debug_debug("The '@ins_text' input files are specified");

      print_debug_trace("Replace previous base directory prefix with the instrument one");
      @ins_text = map(
      {
        my $in_text = $_;

        $in_text =~ s/^$cmd_basedir/$opt_basedir/;

        # Input files for cc command must exist.
        if ($cmd->gi eq $xml_cmd_cc)
        {
          die("The input commands xml file specifies file '$in_text' that doesn't exist for '$id_attr' command")
            unless ($in_text and -f $in_text);
        }

        $in_text;
      } @ins_text);
      print_debug_debug("The input files with replaced base directory are '@ins_text'");
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
      print_debug_debug("The output file with replaced base directory is '$out_text'");

      print_debug_trace("Get on and off options");
      my @on_opts;
      my @off_opts;
      if ($kind_isaspect && $aspectator_type eq 'gcc')
      {
        @on_opts = @gcc_aspect_on_opts;
        @off_opts = @gcc_aspect_off_opts;
      }
      elsif ($kind_isaspect && $aspectator_type eq 'llvm')
      {
        @on_opts = @llvm_aspect_on_opts;
        @off_opts = @llvm_aspect_off_opts;
      }
      elsif ($kind_isplain)
      {
        @on_opts = @gcc_plain_on_opts;
        @off_opts = @gcc_plain_off_opts;
      }

      my ($autoconf,@opts) = filter_opts($cmd,\@on_opts,\@off_opts);

      if (!$opt_suppress_config_check and $ldv_model{'config'} and $cmd->gi eq $xml_cmd_cc)
      {
        print_debug_trace("Add config include options for cc command");
        die("The configuration file is specified for the model but there is no configuration marked correspondingly.")
          unless ($autoconf);

        my @config_inc_dirs = create_configs($cwd_text, $autoconf);
        print_debug_debug("The config includes directories are '@config_inc_dirs'");
        @opts = (map("-I$_", @config_inc_dirs), @opts);

        # Note that two options are passed since otherwise it leads to
        # failure. This options are passed after all options to
        # overwrite the standard configuration files options.
        push(@opts, ("-include", "$ldv_model_dir/$ldv_model{'config'}"));
      }

      print_debug_debug("The options to be passed to the gcc compiler are '@opts'");

      my @entry_points = $cmd->children_text($xml_cmd_entry_point);
      print_debug_debug("The entry points are '@entry_points'");

      @ins_text = $cmd->children_text($xml_cmd_in);
      print_debug_trace("The input files are '@ins_text'");

      print_debug_trace("Store the current command information");
      my %cmd = (
        'id' => $id_attr,
        'cwd' => $cwd_text,
        'ins' => \@ins_text,
        'out' => $out_text,
        'check' => $check_text,
        'restrict-main' => $restrict_main,
        'opts' => \@opts);

      # cc command doesn't contain any specific settings.
      if ($cmd->gi eq $xml_cmd_cc)
      {
        print_debug_debug("The cc command '$id_attr' is especially specifically processed for the aspect mode");
        my ($status, $desc, $time) = func_status_desc_and_time(\&process_cmd_cc,$cmd,%cmd);

        # Go to the next CC comand and finish gathering argument signatures when
        # reach LD command.
        next if ($isgather_arg_signs);

        print_debug_trace("Log information on the '$id_attr' command execution status");
        my $status_log;
        # 0 status is good. Store description related with the output
        # to use it in ld command processing.
        if ($status)
        {
          $status_log = $log_cmds_fail;
          $cmds_status_fail{$out_text} = $desc;
        }
        else
        {
          $status_log = $log_cmds_ok;
          $cmds_status_ok{$out_text} = $desc;
        }

        my %log = (
            'cmd' => $log_cmds_cc # The cc command was executed.
          , 'status' => $status_log # The cc command is executed successfully.
          , 'time' => $time # The execution time.
          , 'id' => $id_attr # The cc command id.
          , 'check' => 0 # The cc command always has 0 check attribute.
          , 'entries' => \@entry_points # The cc command doesn't contain any entry point indeed.
          , 'desc' => $desc # There is an execution specific description.
        );
        print_cmd_log(\%log);
      }

      # ld command additionaly contains array of entry points.
      # While gathering argument signatures LD command processing isn't required.
      if ($cmd->gi eq $xml_cmd_ld and !$isgather_arg_signs)
      {
        $cmd{'entry point'} = \@entry_points;
        print_debug_debug("The ld command entry points are '@entry_points'");

        print_debug_debug("The ld command '$id_attr' is especially specifically processed for the aspect mode");
        my ($status, $desc, $time);

        # Check whether all input files are processed sucessfully.
        my $status_in = 1;
        my @cc_error_desc = ();
        foreach my $in_text (@ins_text)
        {
          # I.e. when ld input file was processed with errors.
          if (defined($cmds_status_fail{$in_text}))
          {
            print_debug_trace("The required by ld file '$in_text' wasn't processed successfully");
            $status_in = 0;
            push(@cc_error_desc, $cmds_status_fail{$in_text});
          }
          # I.e. when ld input file wasn't processed at all. I assume
          # that this situation is impossible indeed.
          elsif (!defined($cmds_status_ok{$in_text}))
          {
            print_debug_trace("The required by ld file '$in_text' wasn't processed at all");
            $status_in = 0;
            my @desc = ("The input file '$in_text' required by the ld command wasn't processed");
            push(@cc_error_desc, \@desc);
          }
          # I.e. when ld input file was processed without errors but may be with
          # some useful warnings.
          else
          {
            print_debug_trace("The required by ld file '$in_text' was processed successfully");
            push(@cc_error_desc, $cmds_status_ok{$in_text});
          }
        }

        # Process command just when inputs are ok.
        if ($status_in)
        {
          ($status, $desc, $time) = func_status_desc_and_time(\&process_cmd_ld,$cmd,%cmd);
        }

        print_debug_trace("Log information on the '$id_attr' command execution status");
        if ($status_in)
        {
          print_debug_debug("All ld command input files are processed successfully");
          my $status_log;
          my $desc_log;

          $desc_log = join_error_desc(@cc_error_desc, $desc);

          # 0 status is good.
          if ($status)
          {
            $status_log = $log_cmds_fail;
            # Mark that the output file isn't generated successfully.
            $cmds_status_fail{$out_text} = $desc_log;
          }
          else
          {
            $status_log = $log_cmds_ok;
            # Just mark that the output file is generated successfully.
            $cmds_status_ok{$out_text} = $desc_log;
          }

          my %log = (
              'cmd' => $log_cmds_ld # The ld command was executed.
            , 'status' => $status_log # The ld command execution status.
            , 'time' => $time # The execution time.
            , 'id' => $id_attr # The ld command id.
            , 'check' => ($check_text eq 'true') # The ld command has some check attribute.
            , 'entries' => \@entry_points # The ld command entry points.
            , 'desc' => $desc_log # There is an execution specific description.
          );
          print_cmd_log(\%log);
        }
        else
        {
          print_debug_debug("Some ld command input files aren't processed successfully");
          # Mark that the output file isn't generated successfully.
          $cmds_status_fail{$out_text} = join_error_desc(@cc_error_desc);

          my %log = (
              'cmd' => $log_cmds_ld # The ld command was executed.
            , 'status' => $log_cmds_fail # The ld command failed.
            , 'time' => 0 # The execution time is 0 since input files aren't processed successfully and nothing is done.
            , 'id' => $id_attr # The ld command id.
            , 'check' => ($check_text eq 'true') # The ld command has some check attribute.
            , 'entries' => \@entry_points # The ld command entry points.
            , 'desc' => $cmds_status_fail{$out_text} # The ld command fails due to some input cc commands aren't finished successfully.
          );

          print_cmd_log(\%log);
        }
      }

      print_debug_debug("Finish processing of the command having id '$id_attr' in the aspect mode");
    }
    # Interpret other commands.
    else
    {
      warn("The input xml file contains the command '" . $cmd->gi . "' that can't be interpreted");
      exit($error_semantics);
    }
  }
  }
}

sub process_report()
{
  print_debug_trace("Obtain the mode");
  die("Can't get the mode from the commands log file")
    unless (defined(my $mode = <$file_cmds_log>));
  chomp($mode);

  my $mode_isaspect = 0;
  my $mode_isplain = 0;

  if ($mode eq $log_cmds_aspect->{'gcc'})
  {
    $mode_isaspect = 1;
    $aspectator_type = 'gcc';
    print_debug_debug("The GCC aspect mode is specified");
  }
  elsif ($mode eq $log_cmds_aspect->{'llvm'})
  {
    $mode_isaspect = 1;
    $aspectator_type = 'llvm';
    print_debug_debug("The aspect mode is specified");
  }
  elsif ($mode eq $log_cmds_plain)
  {
    $mode_isplain = 1;
    print_debug_debug("The plain mode is specified");
  }
  else
  {
    warn("Can't parse mode '$mode' in the commands log file");
    exit($error_semantics);
  }

  # Indeed verifier isn't used now...
  print_debug_trace("Obtain the verifier");
  die("Can't get the verifier from the commands log file")
    unless(defined(my $verifier = <$file_cmds_log>));
  chomp($verifier);
  print_debug_debug("The verifier '$verifier' is specified");

  my %cmds_log;
  my @cmds_id;

  print_debug_trace("Process the commands log line by line");
  while (my $cmd_log = <$file_cmds_log>)
  {
    chomp($cmd_log);
    print_debug_trace("Process the '$cmd_log' command log");
    # Each command log has form: 'cmd_name:cmd_status:cmd_exec_time:cmd_id:cmd_check:cmd_entry_points:cmd_desc'.
    $cmd_log =~ /([^:]+):([^:]+):([^:]*):([^:]*):([^:]*):([^:]*):/;
    my $cmd_name = $1 // die("The command name isn't specified");
    my $cmd_status = $2 // die("The command status isn't specified");
    my $cmd_time = $3 // die("The command execution time isn't specified");
    my $cmd_id = $4 // die("The command id isn't specified");
    my $cmd_check = $5 // die("The command check isn't specified");
    my @cmd_entry_points = split(/\s+/, $6);
    print_debug_trace("Read the command execution description");
    my $cmd_desc = '';
    # Description is placed on the many lines, begining and ending with
    # special set of characters.
    print_debug_trace("Obtain the description open tag");
    die("Reach the end of the command log file but don't find the description open tag")
      unless (defined(my $desc_begin = <$file_cmds_log>));
    chomp($desc_begin);
    die("Can't get the description open tag from the commands log file")
      unless ($desc_begin eq $log_cmds_desc_begin);
    # Read lines untill the description end tag.
    while (1)
    {
      die("Reach the end of the command log file but don't find the description end tag")
        unless (defined(my $desc_cur = <$file_cmds_log>));
      last if ($desc_cur =~ /^\Q$log_cmds_desc_end\E/);

      # Skip useless lines.
      next if ($desc_cur =~ /^\s+$/);

      # Concatenate with the previous partial description.
      $cmd_desc = "$cmd_desc$desc_cur";
    }

    print_debug_debug("The commmand log id is '$cmd_id'");
    print_debug_debug("The command check is '$cmd_check'");
    die("The command id isn't unique") if (defined($cmds_log{$cmd_id}));
    die("The command name '$cmd_name' isn't correct")
      unless ($cmd_name eq $log_cmds_cc or $cmd_name eq $log_cmds_ld);
    print_debug_debug("The commmand log command name is '$cmd_name'");
    die("The command execution status '$cmd_status' isn't correct")
      unless ($cmd_status eq $log_cmds_ok or $cmd_status eq $log_cmds_fail);
    print_debug_debug("The commmand log command execution status is '$cmd_status'");
    print_debug_debug("The commmand log command entry points are '@cmd_entry_points'");
    print_debug_trace("The commmand log command description is '$cmd_desc'");

    print_debug_trace("Remove the non-ASCII symbols from description since they aren't parsed correctly");
    $cmd_desc =~ s/[^[:ascii:]]//g;

    $cmds_log{$cmd_id} = {
      'cmd name' => $cmd_name,
      'cmd status' => $cmd_status,
      'cmd entry points' => \@cmd_entry_points,
      'cmd description' => $cmd_desc,
      'cmd check' => $cmd_check
    };

    # Read the file with time statistics.
    if (-f $ldv_timeout_script_output)
    {
      open(my $stats_file, '<', $ldv_timeout_script_output)
        or die("Can't open the file with time statistics: '$ldv_timeout_script_output', $ERRNO");
      while (<$stats_file>)
      {
        $ARG =~ /^\s*<time\s+ref="$cmd_id"\s+name="(.*)"\s*>\s*([0-9]*)\s*<\/time>/
          or next;
        $cmds_log{$cmd_id}->{'cmd time'}->{$1} += $2;
      }
      close($stats_file)
        or die("Couldn't close file '$ldv_timeout_script_output': $ERRNO\n");
    }
    else
    {
      $cmds_log{$cmd_id}->{'cmd time'}->{'ALL'} = 0;
    }

    push(@cmds_id, $cmd_id);
  }
  print_debug_debug("The command log is processed successfully");

  print_debug_trace("Read the report file '$opt_report_in'");
  my %reports;
  $xml_twig->parsefile("$opt_report_in");
  my $report_root = $xml_twig->root;

  print_debug_trace("Obtain all ld reports");
  my @reports = $report_root->children;

  print_debug_trace("Iterate over the all ld reports");
  foreach my $report (@reports)
  {
    if ($report->gi eq $xml_report_ld)
    {
      print_debug_trace("Read ld command reference");
      my $ref_id_attr = $report->att($xml_report_attr_ref)
        // die("The report file doesn't contain '$xml_report_attr_ref' attribute for some ld command");
      print_debug_debug("Begin processing of the command '" . $report->gi . "' having id reference '$ref_id_attr'");

      print_debug_trace("Read ld main");
      my $main_attr = $report->att($xml_report_attr_main)
        // die("The report file doesn't contain '$xml_report_attr_main' attribute for command having id reference '$ref_id_attr'");
      print_debug_debug("The command main is '$main_attr'");

      print_debug_trace("Read verdict");
      my $verdict = $report->first_child_text($xml_report_verdict)
        // die("The report file doesn't contain '$xml_report_verdict' tag for '$ref_id_attr, $main_attr' command");
      print_debug_debug("The verdict is '$verdict'");

      print_debug_trace("Read verifier");
      my $verifier = $report->first_child_text($xml_report_verifier)
        // die("The report file doesn't contain '$xml_report_verifier' tag for '$ref_id_attr, $main_attr' command");
      print_debug_debug("The verifier is '$verifier'");

      print_debug_trace("Read trace");
      my $trace = $report->first_child_text($xml_report_trace)
        // die("The report file doesn't contain '$xml_report_trace' tag for '$ref_id_attr, $main_attr' command");
      print_debug_debug("The trace is '$trace'");

      print_debug_trace("Read rcv report section");
      my $rcv = $report->first_child($xml_report_rcv)
        or die("The report file doesn't contain '$xml_report_rcv' tag for '$ref_id_attr, $main_attr' command");

      print_debug_trace("Read rcv status");
      my $rcv_status = $rcv->first_child_text($xml_report_status)
        // die("The report file doesn't contain '$xml_report_status' tag for '$ref_id_attr, $main_attr' command");
      print_debug_debug("The rcv status is '$rcv_status'");

      print_debug_trace("Read rcv time");
      my $rcv_time = $rcv->first_child_text($xml_report_time)
        // die("The report file doesn't contain '$xml_report_time' tag for '$ref_id_attr, $main_attr' command");
      print_debug_debug("The rcv time is '$rcv_time'");

      print_debug_trace("Read rcv description");
      my $rcv_desc = $rcv->first_child_text($xml_report_desc)
        // die("The report file doesn't contain '$xml_report_desc' tag for '$ref_id_attr, $main_attr' command");
      print_debug_debug("The rcv description is '$rcv_desc'");

      # Note that this information isn't needed indeed. Just presence of report
      # and link to itself.
      $reports{$ref_id_attr}{$main_attr} = {
        'report' => $report,
        'verdict' => $verdict,
        'verifier' => $verifier,
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
  print_debug_debug("All ld reports are processed successfully");

  print_debug_trace("Print the standard xml file header");
  print($file_report_xml_out "$xml_header\n");

  print_debug_trace("Prepare a xml writer, open a root node tag and print a base directory in the report mode");
  $xml_writer = new XML::Writer(OUTPUT => $file_report_xml_out, NEWLINES => 1, UNSAFE => 1);
  $xml_writer->startTag($xml_report_root);

  print_debug_trace("Iterate over all commands from the log and build reports for them");
  foreach my $cmd_id (@cmds_id)
  {
    if ($cmds_log{$cmd_id}{'cmd name'} eq $log_cmds_cc)
    {
      print_debug_debug("Build a report for the '$cmd_id' cc command");
      $xml_writer->startTag($xml_report_cc, $xml_report_attr_ref => $cmd_id, $xml_report_attr_model => $opt_model_id);

      print_debug_trace("Build the rule instrumentor report");
      $xml_writer->startTag($xml_report_rule_instrumentor);

      if ($cmds_log{$cmd_id}{'cmd status'} eq $log_cmds_ok)
      {
        $xml_writer->dataElement($xml_report_status => $xml_report_status_ok);
      }
      else
      {
        $xml_writer->dataElement($xml_report_status => $xml_report_status_fail);
      }

      foreach (keys(%{$cmds_log{$cmd_id}->{'cmd time'}}))
      {
        $xml_writer->dataElement($xml_report_time => $cmds_log{$cmd_id}->{'cmd time'}->{$ARG}, 'name' => $ARG);
      }

      $xml_writer->dataElement($xml_report_desc => $cmds_log{$cmd_id}{'cmd description'});

      # Close the rule instrumentor tag.
      $xml_writer->endTag();
      # Close the cc tag.
      $xml_writer->endTag();
    }
    else
    {
      print_debug_debug("Build a report for the '$cmd_id' ld command");

      # ld commands have additional suffix in the aspect mode.
      my $rule_instrument_cmd_id = $cmd_id;

      if ($mode_isaspect && ($aspectator_type eq 'llvm'))
      {
        $rule_instrument_cmd_id .= $id_ld_llvm_suffix;
      }
      print_debug_debug("The rule inctrumentor '$cmd_id' ld command has corresponding the rcv '$rule_instrument_cmd_id' ld command");

      # Iterate over all ld entry points.
      foreach my $main_id (@{$cmds_log{$cmd_id}{'cmd entry points'}})
      {
        print_debug_debug("Build a report for the '$main_id' entry point");

        if ($cmds_log{$cmd_id}{'cmd check'})
        {
          print_debug_debug("The '$cmd_id' ld command has 'check=true'");

          print_debug_trace("Try to find the corresponding rcv report");
          # This flag says whether rcv produces report at all.
          my $isrcv_ok = 0;
          $isrcv_ok = 1 if ($reports{$rule_instrument_cmd_id} && $reports{$rule_instrument_cmd_id}{$main_id});
          print_debug_debug("rcv production of a report for the '$cmd_id' ('$rule_instrument_cmd_id') ld command '$main_id' entry point is '$isrcv_ok'");

          # Extend the existing report when rcv produces it.
          if ($isrcv_ok)
          {
            my $report = $reports{$rule_instrument_cmd_id}{$main_id}{'report'}->copy;

            print_debug_trace("Fix the ld command identifier");
            $report->set_att($xml_report_attr_ref => $cmd_id);
            print_debug_trace("Add model identifier attribute");
            $report->set_att($xml_report_attr_model => $opt_model_id);

            print_debug_trace("Add model kind tag");
            my $model_kind_tag;
            if ($mode_isaspect)
            {
              $model_kind_tag = new XML::Twig::Elt($xml_report_model_kind, $xml_report_model_kind_aspect);
            }
            else
            {
              $model_kind_tag = new XML::Twig::Elt($xml_report_model_kind, $xml_report_model_kind_plain);
            }
            $model_kind_tag->paste('last_child', $report);

            print_debug_trace("Build the rule instrumentor report");
            my $rule_instrumentor_tag = new XML::Twig::Elt($xml_report_rule_instrumentor);
            print_debug_trace("Print the command execution status");
            my $cmd_status_tag;
            if ($cmds_log{$cmd_id}{'cmd status'} eq $log_cmds_ok)
            {
              $cmd_status_tag = new XML::Twig::Elt($xml_report_status, $xml_report_status_ok);
            }
            else
            {
              $cmd_status_tag = new XML::Twig::Elt($xml_report_status, $xml_report_status_fail);
            }
            $cmd_status_tag->paste('last_child', $rule_instrumentor_tag);
            print_debug_trace("Print the command execution time");

            foreach(keys(%{$cmds_log{$cmd_id}->{'cmd time'}}))
            {
              my $time_tag = new XML::Twig::Elt($xml_report_time, $cmds_log{$cmd_id}->{'cmd time'}->{$ARG});
              $time_tag->set_att('name' => $ARG);
              $time_tag->paste('last_child', $rule_instrumentor_tag);
            }

            print_debug_trace("Print the command description");
            my $desc_tag = new XML::Twig::Elt($xml_report_desc, $cmds_log{$cmd_id}{'cmd description'});
            $desc_tag->paste('last_child', $rule_instrumentor_tag);

            $rule_instrumentor_tag->paste('last_child', $report);

            $xml_writer->raw($report->sprint);
          }
          # Otherwise generate stub for the rcv report.
          else
          {
            $xml_writer->startTag($xml_report_ld, $xml_report_attr_ref => $cmd_id, $xml_report_attr_main => $main_id, $xml_report_attr_model => $opt_model_id);
            print_debug_debug("Print stubs instead of a rcv verdict and a trace since it fails");
            $xml_writer->dataElement($xml_report_verdict => $xml_report_verdict_stub);
            $xml_writer->dataElement($xml_report_trace => '');

            if ($mode_isaspect)
            {
              $xml_writer->dataElement($xml_report_model_kind => $xml_report_model_kind_aspect);
            }
            else
            {
              $xml_writer->dataElement($xml_report_model_kind => $xml_report_model_kind_plain);
            }

            print_debug_trace("Build a rule instrumentor report");
            $xml_writer->startTag($xml_report_rule_instrumentor);
            if ($cmds_log{$cmd_id}{'cmd status'} eq $log_cmds_ok)
            {
              $xml_writer->dataElement($xml_report_status => $xml_report_status_ok);
            }
            else
            {
              $xml_writer->dataElement($xml_report_status => $xml_report_status_fail);
            }

            foreach(keys(%{$cmds_log{$cmd_id}->{'cmd time'}}))
            {
              $xml_writer->dataElement($xml_report_time => $cmds_log{$cmd_id}->{'cmd time'}->{$ARG}, 'name' => $ARG);
            }

            $xml_writer->dataElement($xml_report_desc => $cmds_log{$cmd_id}{'cmd description'});
            # Close the rule instrumentor tag.
            $xml_writer->endTag();

            # Close the ld tag.
            $xml_writer->endTag();
          }
        }
        else
        {
          print_debug_debug("The '$cmd_id' ld command has 'check=false'");
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

          $xml_writer->dataElement($xml_report_time => $cmds_log{$cmd_id}{'cmd time'});
          $xml_writer->dataElement($xml_report_desc => $cmds_log{$cmd_id}{'cmd description'});

          # Close the rule instrumentor tag.
          $xml_writer->endTag();
          # Close the ld tag.
          $xml_writer->endTag();
        }
      }
    }
  }

  print_debug_trace("Close the root node tag and peform final checks in the report mode");
  $xml_writer->endTag();
  $xml_writer->end();

  print_debug_debug("The instrument prints report for all commands successfully");
}

# Cache infrastructure.
sub cache_fname(@)
{
  my @key = @ARG;
  my $key = join('/', @key);
  return "$ri_cache_dir/$key";
}

sub copy_from_cache($@)
{
  return '' unless ($do_cache);

  my ($target, @key) = @ARG;

  print_debug_trace("Find in cache '$target' with keys '@key'");

  my $cache_fname = cache_fname(@key);

  # If file exists, but isn't a file (a directory, for example), return true
  # (such an error shouldn't prevent all from working).
  if (-e $cache_fname && (!-f $cache_fname || !-r $cache_fname))
  {
    print_debug_warning("Requested cached '$cache_fname', but it's not a file (or is not readable)! Assuming cache miss");
    return 1;
  }

  # If the file exists, copy it (or symlink).
  if (-e $cache_fname)
  {
    print_debug_trace("Cache hit");

    my $target_dir = dirname($target);
    if (!-d $target_dir)
    {
      print_debug_trace("Creating directory for '$target'");
      mkpath($target_dir)
        or die("Couldn't recursively create directory '$target_dir': $ERRNO");
    }

    # Removing target file if it exists
    if (-e $target)
    {
      print_debug_warning("Removing cache target '$target' to replace it with cached value");
      unlink($target)
        or die("Couldn't remove file '$target': $ERRNO");
    }

    symlink($cache_fname, $target)
      or die("Can't create symlink from '$cache_fname' to '$target'");

    return 1;
  }

  print_debug_trace("Cache miss");
  return '';
}

sub save_to_cache($@)
{
  return unless ($do_cache);

  my ($source, @key) = @ARG;

  print_debug_trace("Save to cache '$source' with keys '@key'");

  my $cache_fname = cache_fname(@key);

  # If file exists, but isn't a file (a directory, for example), return false
  # (such an error shouldn't prevent all from working).
  if (-e $cache_fname && (!-f $cache_fname || !-r $cache_fname))
  {
    print_debug_warning("Requested cached $cache_fname, but it's not a file (or is not readable)! Not saving it");
    return;
  }

  # If the file doen't exist in cache, copy it.
  unless (-e $cache_fname)
  {
    print_debug_trace("Writing to cache '$cache_fname'");

    my $target_dir = dirname("$cache_fname");
    if (!-d $target_dir)
    {
      mkpath($target_dir)
        or die("Couldn't recursively create directory '$target_dir': $ERRNO");
    }

    copy($source, $cache_fname) or
      die("Can't copy from '$source' to '$cache_fname'");
  }
}

sub string_from_cache(@)
{
  die("Caching is off but string is extracted")
    unless ($do_cache);

  my (@key) = @ARG;

  print_debug_trace("Find in cache string by keys '@key'");

  my $cache_fname = cache_fname(@key);

  # If file exists, but isn't a file (a directory, for example), return undef
  # (such an error shouldn't prevent all from working).
  if (-e $cache_fname && (!-f $cache_fname || !-r $cache_fname)){
    print_debug_warning("Requested cached $cache_fname, but it's not a file (or is not readable)! Assuming cache miss");
    return undef;
  }

  # If the file exists, read its contents and return.
  if (-e $cache_fname)
  {
    print_debug_trace("Cache hit");

    open(my $cache_fh, '<', $cache_fname)
      or die("Couldn't open file '$cache_fname' for read: $ERRNO");
    my @cache_content = <$cache_fh>;
    close($cache_fh)
      or die("Couldn't close file '$cache_fname': $ERRNO\n");

    return join('\n', @cache_content);
  }

  print_debug_trace("Cache miss");
  return undef;
}

sub string_to_cache($@)
{
  return unless ($do_cache);

  my ($str, @key) = @ARG;

  print_debug_trace("Save to cache '$str' with keys '@key'");

  my $cache_fname = cache_fname(@key);

  # If file exists, but isn't a file (a directory, for example), return false
  # (such an error shouldn't prevent all from working).
  if (-e $cache_fname && (!-f $cache_fname || !-r $cache_fname))
  {
    print_debug_warning("Requested cached $cache_fname, but it's not a file (or is not readable)! Not saving it");
    return;
  }

  # If the file doen't exist in cache, copy it
  unless (-e $cache_fname)
  {
    print_debug_trace("Writing to cache '$cache_fname'");

    my $target_dir = dirname("$cache_fname");
    unless (-d $target_dir)
    {
      mkpath($target_dir)
        or die("Couldn't recursively create directory '$target_dir': $ERRNO");
    }

    open(my $cache_fh, '>', $cache_fname)
      or die("Couldn't open file '$cache_fname' for write: $ERRNO");
    print($cache_fh $str);
    close($cache_fh)
      or die("Couldn't close file '$cache_fname': $ERRNO\n");
  }
}

sub filter_opts($$$)
{
  my ($cmd,$on_opts,$off_opts) = @_;
  my @on_opts = @$on_opts;
  my @off_opts = @$off_opts;

  print_debug_trace("Read an array of options and exclude the unwanted ones ('@off_opts')");
  my @opts = ();
  my $autoconf = undef;
  for (my $opt = $cmd->first_child($xml_cmd_opt)
    ; $opt
    ; $opt = $opt->next_elt($xml_cmd_opt))
  {
    my $opt_text = $opt->text;

    my $opt_config_attr = $opt->att($xml_cmd_opt_config);
    if ($opt_config_attr)
    {
      print_debug_debug("The option '$opt_text' is marked as configuration header file");

      if ($opt_config_attr eq $xml_cmd_opt_config_autoconf)
      {
        print_debug_debug("The option '$opt_text' is marked as automatic configuration header file");
        # Story automatic configuration header file just once.
        if ($autoconf)
        {
          die("Don't mark more then one option as automatic configuration header file");
        }
        else
        {
          $autoconf = $opt_text;
        }
      }
    }

    # Exclude options for the gcc compiler.
    foreach my $off_opt (@off_opts)
    {
      if ($opt_text =~ /^$off_opt$/)
      {
        print_debug_debug(sprintf("Exclude the option '$opt_text' for the '%d' command",$cmd->att($xml_cmd_attr_id)));
        $opt_text = '';
        last;
      }
    }

    next unless ($opt_text);

    push(@opts, $opt_text);

    last if ($opt->is_last_child($xml_cmd_opt));
  }

  print_debug_debug("Add wanted options '@on_opts'");
  push(@opts, @on_opts);

  return ($autoconf,@opts);
}
