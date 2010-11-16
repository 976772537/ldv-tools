#! /usr/bin/perl -w


use English;
use Env qw(LDV_DEBUG LDV_REGR_TEST_CHECKER_DEBUG);
use FindBin;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../../shared/perl");

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
my $debug_name = 'regr-test-checker';

# The default placement of difference. It's relative to the current working
# directory.
my $diff_file = 'regr-test.diff';
# The diff/merge tool to be used.
my $diff_merge_tool;
# The standard diff tool.
my $diff_tool = 'diff -u';

# Command-line options. Use --help option to see detailed description of them.
my $opt_diff_file;
my $opt_diff_merge_tool;
my $opt_help;
my $opt_task;
my $opt_test_set;

# The available predefined test sets.
my %predefined_test_sets = ('small' => 1, 'medium' => 1, 'big' => 1);
# An absolute path to the directory containing predefined test sets.
my $predefined_test_sets_dir = "$FindBin::RealBin/../../ldv-tests/regr-tests/test-sets";

# The prefix to the regression test task.
my $regr_task_prefix = 'regr-task-';

# The file where the results from the database will be loaded. It's relative to
# the current working directory.
my $task_file = 'regr-task-new';
# A locally sorted task file, for precise diffs.
my $task_file_sorted = "current.sorted";

# The test set to be used. It's an absolute path to the test set task file.
my $test_set;
# A locally sorted test sets file, for precise diffs.
my $test_set_sorted = "original.sorted";

# The directory of the test set.
my $test_set_dir;


################################################################################
# Main section.
################################################################################

# Obtain the debug level.
get_debug_level($debug_name, $LDV_DEBUG, $LDV_REGR_TEST_CHECKER_DEBUG);

print_debug_normal("Process the command-line options");
get_opt();

print_debug_normal("Check presence of needed files, executables and directories. Copy needed files and directories");
prepare_files_and_dirs();

# We sort task files before making diff because we don't know how data will be dumped to the results file.  Perhaps, the order will be different from the one pushed t orepository, due to database collation problems (see bug #523).
print_debug_normal("Sort task files");
my $sort1cmd = "sort '$test_set' -o '$test_set_sorted'";
print_debug_info("Execute the command '$sort1cmd'");
system($sort1cmd);
die "Sort of $test_set failed" if (check_system_call() != 0);

my $sort2cmd = "sort '$task_file' -o '$task_file_sorted'";
print_debug_info("Execute the command '$sort2cmd'");
system($sort2cmd);
die "Sort of $task_file failed" if (check_system_call() != 0);

print_debug_trace("Perform diff/merge");
my $cmd = "$diff_merge_tool $test_set_sorted $task_file_sorted > $diff_file";
print_debug_info("Execute the command '$cmd'");
`$cmd`;
die("There is no the diff/merge tool '$diff_merge_tool' executable in your PATH!")
  if (check_system_call() == -1);
print_debug_normal("Don't pay your attention on the 'error' message about child exiting if you use the standard diff/merge tool ('$diff_merge_tool' is used). In correspondence with its help 'Exit status is 0 if inputs are the same, 1 if different, 2 if trouble.' Also note that regression test infrastructure itself doesn't make a decision on regression. It just provide you with diff file or/and graphic diff/merge interface.");

print_debug_normal("Make all successfully");


################################################################################
# Subroutines.
################################################################################

sub get_opt()
{
  unless (GetOptions(
    'diff-file|o=s' => \$opt_diff_file,
    'diff-tool|t=s' => \$opt_diff_merge_tool,
    'merge-tool=s' => \$opt_diff_merge_tool,
    'help|h' => \$opt_help,
    'task=s' => \$opt_task,
    'test-set=s' => \$opt_test_set))
  {
    warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
    help();
  }

  help() if ($opt_help);

  # TODO make a module!!!
  if ($opt_test_set)
  {
    # I.e. the absolute path to the regression test task.
    if ($opt_test_set =~ /\//)
    {
      die("The file '$opt_test_set' specified through the option --test-set doesn't exist: $ERRNO")
        unless (-f $opt_test_set);
    }
    # One of the predefined test sets.
    else
    {
      unless (defined($predefined_test_sets{$opt_test_set}))
      {
        warn("The test set '$opt_test_set' specified through the option --test-set can't be processed. Please use one of the following ones:\n");

        foreach my $test_set (keys(%predefined_test_sets))
        {
          warn("  - '$test_set'\n");
        }

        die();
      }
    }

    print_debug_debug("The choosen test set is '$opt_test_set'");
  }

  print_debug_debug("The command-line options are processed successfully");
}

sub help()
{
    print(STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to perform check the regression.

SYNOPSIS
  $PROGRAM_NAME [option...]

OPTIONS

  -o, diff-file <file>
    <file> is a file where the compare results will be put. It's optional.
    For some diff/merge tool (e.g. 'meld') it useless. If it isn't specified
    then the output is placed to the file '$diff_file' in the current directory.

  -t, --diff-tool, --merge-tool <tool>
    <tool> is a some diff/merge tool (e.g. 'diff', 'meld' and so on) with
    some options (e.g. 'diff -u'). It's optional. The standard diff tool 'diff -u' is
    used when it isn't specified.

  -h, --help
    Print this help and exit with a error.

  --task <file>
    <file> is a path to a file where all launches results from the database
    are placed. It's optional. If it isn't specified then results are
    searched for in the file '$task_file' in the current directory.

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

  LDV_REGR_TEST_CHECKER_DEBUG
    Like LDV_DEBUG but it has more priority. It specifies a debug
    level just for this instrument.

EOM

  exit(1);
}

sub prepare_files_and_dirs()
{
  $current_working_dir = Cwd::cwd()
    or die("Can't obtain the current working directory");
  print_debug_debug("The current working directory is '$current_working_dir'");

  # TODO make it as a module.
  # Try to obtain regression test task in case when it isn't specified through
  # the absolute path.
  if ($opt_test_set)
  {
    # It's already choosen.
    if ($opt_test_set =~ /\//)
    {
      $test_set = $opt_test_set;
    }
    # Obtain it from the predefined test sets pathes.
    else
    {
      die("Can't find test set '$opt_test_set' in the predefined test sets directory '$predefined_test_sets_dir/$opt_test_set'")
        unless (-d "$predefined_test_sets_dir/$opt_test_set");

      # TODO At this step we need to find appropriate file.
      exit 0;
    }
  }
  # Obtain it from the current directory.
  unless ($opt_test_set)
  {
    exit 0;
  }

  print_debug_trace("Obtain file where the new task was put");
  $task_file = $opt_task if ($opt_task);
  die("The new task file '$task_file' doesn't exist")
    unless (-f $task_file);
  print_debug_debug("The new task is '$task_file'");

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
