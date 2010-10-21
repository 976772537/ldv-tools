#! /usr/bin/perl -w


use Cwd qw(cwd);
use English;
use Env qw(LDV_DEBUG LDV_REGR_TEST_DEBUG LDVDBHOSTTEST LDVDBTEST LDVUSERTEST LDVDBPASSWDTEST);
use File::Path qw(mkpath);
use FindBin;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../shared/perl");

# Add some nonstandard local Perl packages.
use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info
  print_debug_debug print_debug_trace print_debug_all get_debug_level
  check_system_call);


################################################################################
# Subroutine prototypes.
################################################################################

# Process command-line options. To see detailed description of these options
# run script with --help option.
# args: no.
# retn: nothing.
sub get_opt();

# Print help message on the screen and exit.
# args: no.
# retn: nothing.
sub help();

# Make regression test itself.
# args: no.
# retn: nothing.
sub perform_regr_test();

# Obtain needed files and dirs and check their presence.
# args: no.
# retn: nothing.
sub prepare_files_and_dirs();


################################################################################
# Global variables.
################################################################################

# An absolute path to the current working directory.
my $current_working_dir;

# Prefix for all debug messages.
my $debug_name = 'regr-test';

# The default placement of difference. It's relative to the current working
# directory.
my $diff_file = 'regr-test.diff';
# The diff/merge tool to be used.
my $diff_merge_tool;
# The standard diff tool.
my $diff_tool = 'diff -u';

# The working and results directories of the launcher. They are relative to the
# current working directory.
my $launcher_results_dir = 'launcher-results-dir';
my $launcher_working_dir = 'launcher-working-dir';

# Path to the binary of the ldv-load. It must be found in the PATH.
my $ldv_loader_bin = "ldv-load.pl";

# Command-line options. Use --help option to see detailed description of them.
my $opt_diff_file;
my $opt_diff_merge_tool;
my $opt_help;
my $opt_test_set;

# The prefix to the regression test task.
my $regr_task_prefix = 'regr-task-';

# Scripts required for regression tests performing. They are in the tool
# auxiliary directory.
my $script_launch = 'launch.pl';
my $script_upload = 'upload.pl';
my $script_check = 'check.pl';

# The file where the new results will be put. It's relative to the current
# working directory.
my $task_file = 'regr-task-new';

# The auxiliary directory where regression tests auxiliary scripts are placed.
my $tool_aux_dir = "$FindBin::RealBin/../ldv-tests/regr-tests";


################################################################################
# Main section.
################################################################################

# Obtain the debug level.
get_debug_level($debug_name, $LDV_DEBUG, $LDV_REGR_TEST_DEBUG);

print_debug_normal("Process the command-line options");
get_opt();

print_debug_normal("Check presence of needed files, executables and directories. Copy needed files and directories");
prepare_files_and_dirs();

print_debug_normal("Launch ldv-manager, obtain results, upload them to the database, load results to the new task file and compare it with the existing one");
perform_regr_test();

print_debug_normal("Make all successfully");


################################################################################
# Subroutines.
################################################################################

sub get_opt()
{
  unless (GetOptions(
    'diff-file|o=s' => \$opt_diff_file,
    'diff-tool|t=s' => \$opt_diff_merge_tool,
    'help|h' => \$opt_help,
    'test-set=s' => \$opt_test_set))
  {
    warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
    help();
  }

  help() if ($opt_help);

  print_debug_debug("The command-line options are processed successfully");
}

sub help()
{
    print(STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to perform the regression test.

SYNOPSIS
  $PROGRAM_NAME [option...]

OPTIONS

  -t, --diff-tool, --merge-tool <tool>
    <tool> is a some diff/merge tool (e.g. 'diff', 'meld' and so on) with
    some options (e.g. 'diff -u'). It's optional. The standard diff tool 'diff -u' is
    used when it isn't specified.

  -h, --help
    Print this help and exit with a error.

  -o, diff-file <file>
    <file> is a file where the compare results will be put. It's optional.
    For some diff/merge tool (e.g. 'meld') it useless. If it isn't specified
    then the output is placed to the file '$diff_file' in the current directory.

  --test-set <name>
    <name> may be one of the predefined test set names or may be absolute
    path to the regression test task file. It's optional. If this option isn't
    specified, then current folder is scanned for the first regression test
    task. Note then regression test task is a file beginning with the
    '$regr_task_prefix' prefix.

ENVIRONMENT VARIABLES

  LDV_DEBUG
    It's an optional environment variable that specifies a debug
    level. It uses the standard designatures to distinguish different
    debug information printings. Each next level includes all previous
    levels and its own messages.

  LDV_REGR_TEST_DEBUG
    Like LDV_DEBUG but it has more priority. It specifies a debug
    level just for this instrument.

  LDVDBHOSTTEST, LDVDBTEST, LDVUSERTEST, LDVDBPASSWDTEST
    Keeps settings (host, database, user and password) for connection
    to the database. Note that LDVDBTEST and LDVUSERTEST must always be
    presented!

EOM

  exit(1);
}

sub perform_regr_test()
{
  print_debug_normal("Start to launch ldv-manager and obtain the results");
  my @args = ("$tool_aux_dir/$script_launch", "--results", "$current_working_dir/$launcher_results_dir");
  push(@args, "--test-set", "$opt_test_set") if ($opt_test_set);
  print_debug_info("Execute the command '@args'");

  print_debug_trace("Go to the launcher working directory '$current_working_dir/$launcher_working_dir' to launch it");
  chdir("$current_working_dir/$launcher_working_dir")
    or die("Can't change directory to '$current_working_dir/$launcher_working_dir'");

  system(@args);
  die("The launcher fails") if (check_system_call());

  print_debug_trace("Go to the initial working directory '$current_working_dir'");
  chdir($current_working_dir)
    or die("Can't change directory to '$current_working_dir'");

  print_debug_normal("Upload the obtain results to the database");
  @args = ("$tool_aux_dir/$script_upload", "--results", "$current_working_dir/$launcher_results_dir");
  print_debug_info("Execute the command '@args'");
  system(@args);
  die("The uploader fails") if (check_system_call());

  print_debug_normal("Load results to the new task file");
  @args = ($ldv_loader_bin, "--task", "$current_working_dir/$task_file");
  print_debug_info("Execute the command '@args'");
  system(@args);
  die("The loader fails") if (check_system_call());

  print_debug_normal("Compare the old and the new results");
  @args = ("$tool_aux_dir/$script_check", "--task", "$current_working_dir/$task_file", "--diff-file", "$diff_file", "--t", "$diff_merge_tool");
  push(@args, "--test-set", "$opt_test_set") if ($opt_test_set);
  print_debug_info("Execute the command '@args'");
  system(@args);
  die("The checker fails") if (check_system_call());

  print_debug_normal("The result of the regression test is placed to the file '$diff_file'");
}

sub prepare_files_and_dirs()
{
  $current_working_dir = Cwd::cwd()
    or die("Can't obtain the current working directory");
  print_debug_debug("The current working directory is '$current_working_dir'");

  print_debug_trace("Check that database connection is setup");
  die("You don't setup connection to your testing database. See --help for details")
    unless ($LDVDBTEST and $LDVUSERTEST);

  print_debug_debug("The database necessary settings are following: '$LDVDBTEST' and '$LDVUSERTEST' (database and user)");
  print_debug_debug("The database optional settings are following:");
  print_debug_debug("  * '$LDVDBHOSTTEST' (host)") if ($LDVDBHOSTTEST);
  print_debug_debug("  * '$LDVDBPASSWDTEST' (password)") if ($LDVDBPASSWDTEST);

  print_debug_trace("Check presence of scripts");
  die ("There is no the launcher script '$tool_aux_dir/$script_launch'")
    unless (-x "$tool_aux_dir/$script_launch");
  die ("There is no the uploader script '$tool_aux_dir/$script_upload'")
    unless (-x "$tool_aux_dir/$script_upload");
  die ("There is no the checker script '$tool_aux_dir/$script_check'")
    unless (-x "$tool_aux_dir/$script_check");

  die("You run regression tests in the already used directory. Please remove file '$current_working_dir/$task_file'")
    if (-f "$current_working_dir/$task_file");

  die("You run regression tests in the already used directory. Please remove directories '$current_working_dir/$launcher_working_dir' and '$current_working_dir/$launcher_results_dir'")
    if (-d "$current_working_dir/$launcher_working_dir" or -d "$current_working_dir/$launcher_results_dir");
  print_debug_trace("Create auxiliary directories for the launcher");
  mkpath("$current_working_dir/$launcher_working_dir")
    or die("Couldn't recursively create directory '$current_working_dir/$launcher_working_dir': $ERRNO");
  mkpath("$current_working_dir/$launcher_results_dir")
    or die("Couldn't recursively create directory '$current_working_dir/$launcher_results_dir': $ERRNO");

  print_debug_trace("Obtain the diff/merge tool");
  if ($opt_diff_merge_tool)
  {
    $diff_merge_tool = $opt_diff_merge_tool;
  }
  else
  {
    $diff_merge_tool = $diff_tool;
  }
  print_debug_debug("The diff/merge tool is '$diff_merge_tool'");

  print_debug_trace("Try to obtain the diff file");
  $diff_file = $opt_diff_file if ($opt_diff_file);
  die("You run checker in the already used directory. Please remove task file '$diff_file'")
    if (-f $diff_file);
  print_debug_debug("The diff file is '$diff_file'");
}
