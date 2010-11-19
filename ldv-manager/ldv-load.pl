#! /usr/bin/perl -w


use DBI;
use English;
use Env qw(LDV_DEBUG LDV_LOAD_DEBUG LDVDBHOSTTEST LDVDBTEST LDVUSERTEST LDVDBPASSWDTEST);
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

# Load data from the database to the new task file.
# args: no.
# retn: nothing.
sub load_data();

# Obtain needed files and dirs and check their presence.
# args: no.
# retn: nothing.
sub prepare_files_and_dirs();


################################################################################
# Global variables.
################################################################################

# An absolute path to the current working directory.
my $current_working_dir;

# The default database host and password. They're used when no host is specified
# through the environment variables.
my $db_host = 'localhost';
my $db_password = '';

# Prefix for all debug messages.
my $debug_name = 'ldv-loader';

# File handlers.
my $file_task_new;

# Command-line options. Use --help option to see detailed description of them.
my $opt_help;
my $opt_out;

# The file where the results from the database will be loaded. It's relative to
# the current working directory.
my $task_file = 'regr-task-new';

################################################################################
# Main section.
################################################################################

# Obtain the debug level.
get_debug_level($debug_name, $LDV_DEBUG, $LDV_LOAD_DEBUG);

print_debug_normal("Process the command-line options");
get_opt();

print_debug_normal("Check presence of needed files, executables and directories. Copy needed files and directories");
prepare_files_and_dirs();

print_debug_normal("Load data from the database to the new task file");
load_data();

close($file_task_new)
  or die("Can't close the file '$task_file': $ERRNO\n");

print_debug_normal("Make all successfully");


################################################################################
# Subroutines.
################################################################################

sub get_opt()
{
  unless (GetOptions(
    'help|h' => \$opt_help,
    'task|o=s' => \$opt_out))
  {
    warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
    help();
  }

  help() if ($opt_help);

  print_debug_debug("The results will be put to the '$opt_out' file")
    if ($opt_out);

  print_debug_debug("The command-line options are processed successfully");
}

sub help()
{
    print(STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to load results from the database for
    the regression test.

SYNOPSIS
  $PROGRAM_NAME [option...]

OPTIONS

  -h, --help
    Print this help and exit with a error.

  -o, --task <file>
    <file> is a path to a file where all launches results from the database
    will be placed. It's optional. If it isn't specified then results are
    placed to the file '$task_file' in the current directory.

ENVIRONMENT VARIABLES

  LDV_DEBUG
    It's an optional environment variable that specifies a debug
    level. It uses the standard designatures to distinguish different
    debug information printings. Each next level includes all previous
    levels and its own messages.

  LDV_LOAD_DEBUG
    Like LDV_DEBUG but it has more priority. It specifies a debug
    level just for this instrument.

  LDVDBHOSTTEST, LDVDBTEST, LDVUSERTEST, LDVDBPASSWDTEST
    Keeps settings (host, database, user and password) for connection
    to the database. Note that LDVDBTEST and LDVUSERTEST must always be
    presented!

NOTES
  This scipts relates two rather separate parts of the LDV (the LDV toolset and
  the regression tests). It's very important that this script must provide
  regression test infrastructure with the data having the acceptable format.
  So, it must follow the changes in the toolset.

EOM

  exit(1);
}

sub load_data()
{
  print_debug_trace("Connect to the specified database");
  my $db_handler = DBI->connect("DBI:mysql:$LDVDBTEST:$db_host", $LDVUSERTEST, $db_password)
    or die("Can't connect to the database: $DBI::errstr");

  # Prepare queries.
  my $db_launches = $db_handler->prepare("
    SELECT tasks.driver_spec as 'driver', tasks.driver_spec_origin as 'origin'
      , environments.version as 'kernel', rule_models.name as 'model'
      , scenarios.executable as 'module', scenarios.main as 'main'
      , traces.result as 'verdict'
      , stats_1.success as 'BCE success', stats_1.id as 'BCE id'
      , stats_2.success as 'DEG success', stats_2.id as 'DEG id'
      , stats_3.success as 'DSCV success', stats_3.id as 'DSCV id'
      , stats_4.success as 'RI success', stats_4.id as 'RI id'
      , stats_5.success as 'RCV success', stats_5.id as 'RCV id'
    FROM launches
    LEFT JOIN tasks ON launches.task_id=tasks.id
    LEFT JOIN environments ON launches.environment_id=environments.id
    LEFT JOIN rule_models ON launches.rule_model_id=rule_models.id
    LEFT JOIN scenarios ON launches.scenario_id=scenarios.id
    LEFT JOIN traces ON launches.trace_id=traces.id
    LEFT JOIN stats as stats_1 ON traces.build_id = stats_1.id
    LEFT JOIN stats as stats_2 ON traces.maingen_id = stats_2.id
    LEFT JOIN stats as stats_3 ON traces.dscv_id = stats_3.id
    LEFT JOIN stats as stats_4 ON traces.ri_id = stats_4.id
    LEFT JOIN stats as stats_5 ON traces.rcv_id = stats_5.id
    ORDER BY tasks.driver_spec, tasks.driver_spec_origin, environments.version
      , rule_models.name, scenarios.executable, scenarios.main
    ") or die("Can't prepare a query: " . $db_handler->errstr);
  my $db_problems = $db_handler->prepare("
    SELECT problems.name as 'problem'
    FROM stats
    LEFT JOIN problems_stats ON stats.id=problems_stats.stats_id
    LEFT JOIN problems ON problems_stats.problem_id=problems.id
    WHERE stats.id=? AND problems.id IS NOT NULL
    ORDER BY problems.name
    ") or die("Can't prepare a query: " . $db_handler->errstr);

  $db_launches->execute or die("Can't execute a query: " . $db_handler->errstr);
  while (my $launch_info = $db_launches->fetchrow_hashref)
  {
    my $model = ${$launch_info}{'model'} || 'NULL';
    my $module = ${$launch_info}{'module'} || 'NULL';
    my $main = ${$launch_info}{'main'} || 'NULL';
    print($file_task_new "driver=${$launch_info}{'driver'};origin=${$launch_info}{'origin'};kernel=${$launch_info}{'kernel'};model=$model;module=$module;main=$main;verdict=${$launch_info}{'verdict'}");
    # Process tool fails especially.
    if (${$launch_info}{'verdict'} eq 'unknown')
    {
      # Understand what tool fails.
      my $tool_fail_id;
      if (${$launch_info}{'BCE success'})
      {
        if (${$launch_info}{'DEG success'})
        {
          if (${$launch_info}{'DSCV success'})
          {
            if (${$launch_info}{'RI success'})
            {
              if (${$launch_info}{'RCV success'})
              {
                print_debug_warning("The verdict is 'unknown' while all tools report 'success'");
              }
              else
              {
                print($file_task_new ";RCV_status=fail");
                $tool_fail_id = ${$launch_info}{'RCV id'};
              }
            }
            else
            {
              print($file_task_new ";RI_status=fail");
              $tool_fail_id = ${$launch_info}{'RI id'};
            }
          }
          else
          {
            print($file_task_new ";DSCV_status=fail");
            $tool_fail_id = ${$launch_info}{'DSCV id'};
          }
        }
        else
        {
          print($file_task_new ";DEG_status=fail");
          $tool_fail_id = ${$launch_info}{'DEG id'};
        }
      }
      else
      {
        print($file_task_new ";BCE_status=fail");
        $tool_fail_id = ${$launch_info}{'BCE id'};
      }

      $db_problems->execute($tool_fail_id)
        or die("Can't execute a query: " . $db_handler->errstr);

      print($file_task_new ";problems=");
      my $isfirst = 1;
      while (my $problem = $db_problems->fetchrow_hashref)
      {
        if ($isfirst)
        {
          $isfirst = 0;
        }
        else
        {
          print($file_task_new ",");
        }
        print($file_task_new "${$problem}{'problem'}");
      }
    }
    print($file_task_new "\n");
  }
}

sub prepare_files_and_dirs()
{
  $current_working_dir = Cwd::cwd()
    or die("Can't obtain the current working directory");
  print_debug_debug("The current working directory is '$current_working_dir'");

  print_debug_trace("Check that database connection is setup");
  die("You don't setup connection to your testing database. See --help for details")
    unless ($LDVDBTEST and $LDVUSERTEST);

  $db_host = $LDVDBHOSTTEST if ($LDVDBHOSTTEST);
  $db_password = $LDVDBPASSWDTEST if ($LDVDBPASSWDTEST);

  print_debug_trace("Obtain file where the new task will be put");
  $task_file = $opt_out if ($opt_out);
  print_debug_debug("The new task will be printed to the '$task_file' file");

  die("You run loader in the already used directory. Please remove task file '$task_file'")
    if (-f $task_file);

  open($file_task_new, '>', "$task_file")
    or die("Can't open the file '$task_file' for write: $ERRNO");
}
