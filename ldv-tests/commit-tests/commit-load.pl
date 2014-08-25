#! /usr/bin/perl -w

use warnings;
use DBI;
use Readonly;
use Carp;
use English qw( -no_match_vars );
use strict;
use Cwd qw(cwd);
use Getopt::Long qw(GetOptions);
use Env
  qw(LDV_DEBUG LDV_COMMIT_TEST_LOADER_DEBUG LDVDBCTEST LDVDBHOSTCTEST LDVUSERCTEST LDVDBPASSWDCTEST);
use FindBin;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../../shared/perl");

# Add some nonstandard local Perl packages.
use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info
  print_debug_debug print_debug_trace print_debug_all get_debug_level
  check_system_call);

#######################################################################
# Subroutine prototypes.
#######################################################################

# Process command-line options. To see detailed description of these options
# run script with --help option.
# args: no.
# retn: nothing.
sub get_test_opt;

# Print help message on the screen and exit.
# args: no.
# retn: nothing.
sub help;

# Load data from database and print it to file.
# args: no.
# retn: nothing.
sub load_data;
#######################################################################
# Global variables
#######################################################################

# Name of this tool
my $debug_name = 'commit-loader';

# Default name of file where results will be put
my $result_file = 'results.txt';

# Default database host
my $db_host = 'localhost';
#######################################################################
# Main section
#######################################################################

# Obtain the debug level.
get_debug_level( $debug_name, $LDV_DEBUG, $LDV_COMMIT_TEST_LOADER_DEBUG );
print_debug_normal('Process the command-line options');
get_test_opt();
print_debug_normal('Starting loading data');
load_data();
#######################################################################
# Subroutines
#######################################################################
sub get_test_opt {
    my $opt_help;
    my $opt_result_file;
    if (
        !GetOptions(
            'help|h'     => \$opt_help,
            'result|o=s' => \$opt_result_file
        )
      )
    {
        carp 'Incorrect options! Run script with --help option.';
        help();
    }
    if ($opt_help) {
        help();
    }
    if ($opt_result_file) {
        $result_file = $opt_result_file;
    }
    else {
        my $current_dir = Cwd::cwd()
          or croak 'Can\'t obtain the current working directory';
        $result_file = $current_dir . q{/} . $result_file;
    }
    if ( -f $result_file ) {
        unlink $result_file;
    }
    print_debug_normal "Results will be put in $result_file";
    print_debug_debug 'The command-line options are processed successfully';
    return;
}

sub help {
    print << "EOM" or croak "Couldn't print to 'STDOUT': $ERRNO";
NAME
	$PROGRAM_NAME: The programm connects to specified database
	and write information from it to '$result_file'.
SYNOPSIS
	[DATABASE SET] $PROGRAM_NAME [option...]
OPTIONS
	--result, -o <file>
		<file> is file where results will be loaded to.
		Results would be written to 'results.txt' in 
		the current directory if you don't use this option.
	-h, --help
	   Print this help and exit with a error.
DATABASE SET
	LDVDBCTEST=<dbname>
		<dbname> is name of database where results will be loaded from.
	LDVUSERCTEST=<user>
		<user> is username for <dbname>
	[LDVDBHOSTCTEST=<dbhost>]
		<dbhost> is host of your database. If you didn't set this parameter
		it would be set to 'localhost'.
	[LDVDBPASSWDCTEST=<passwd>]
		<passwd> is password for <user> if you set it.
EOM
    exit 1;
}

sub load_data {
    my $db_password;
    print_debug_debug 'Check that database connection is setup';
    if ( not $LDVDBCTEST or not $LDVUSERCTEST ) {
        croak
'You don\'t setup connection to your database. See --help for details';
    }
    if ($LDVDBHOSTCTEST) {
        $db_host = $LDVDBHOSTCTEST;
    }
    if ($LDVDBPASSWDCTEST) {
        $db_password = $LDVDBPASSWDCTEST;
    }

    print_debug_debug 'Connect to the specified database';
    my $db_handler = DBI->connect( "DBI:mysql:$LDVDBCTEST:$db_host",
        $LDVUSERCTEST, $db_password )
      or croak "Can't connect to the database: $DBI::errstr";

    my $db_launches = $db_handler->prepare(
        << 'END_LAUNCH'
        SELECT tasks.id, tasks.driver_spec as 'driver', tasks.driver_spec_origin as 'origin'
          , environments.version as 'kernel', rule_models.name as 'model'
          , scenarios.executable as 'module', scenarios.main as 'main'
          , traces.result as 'verdict'
          , stats_1.success as 'BCE success', stats_1.id as 'BCE id'
          , stats_2.success as 'DEG success', stats_2.id as 'DEG id'
          , stats_3.success as 'DSCV success', stats_3.id as 'DSCV id'
          , stats_4.success as 'RI success', stats_4.id as 'RI id'
          , stats_5.success as 'RCV success', stats_5.id as 'RCV id'
          , launches.trace_id as 'trace_id'
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
END_LAUNCH
    ) or croak 'Can\'t prepare a query: ' . $db_handler->errstr;
    my $db_problems = $db_handler->prepare(
        <<'END_PROBLEMS'
        SELECT problems.name as 'problem'
        FROM stats
        LEFT JOIN problems_stats ON stats.id=problems_stats.stats_id
        LEFT JOIN problems ON problems_stats.problem_id=problems.id
        WHERE stats.id=? AND problems.id IS NOT NULL
        ORDER BY problems.name
END_PROBLEMS
    ) or croak 'Can\'t prepare a query: ' . $db_handler->errstr;
    $db_launches->execute
      or croak 'Can\'t execute a query: ' . $db_handler->errstr;
    my $filestr = q{};

    while ( my $launch_info = $db_launches->fetchrow_hashref ) {
        my $model  = ${$launch_info}{'model'}  || 'NULL';
        my $module = ${$launch_info}{'module'} || 'NULL';
        my $main   = ${$launch_info}{'main'}   || 'NULL';
        my $rcv_memory;
        my $rcv_time;
        my $trace_id    = ${$launch_info}{'trace_id'};
        my $select_time = $db_handler->prepare(
"SELECT time_average AS time FROM processes WHERE trace_id=$trace_id AND pattern='ALL' AND name='rcv'"
        ) or croak 'Can\'t prepare a select: ' . $db_handler->errstr;
        my $select_memory = $db_handler->prepare(
"SELECT time_average AS memory FROM processes WHERE trace_id=$trace_id AND pattern='memory' AND name='rcv'"
        ) or croak 'Can\'t prepare a select: ' . $db_handler->errstr;
        $select_time->execute and $select_memory->execute
          or croak 'Can\'t execute a query: ' . $db_handler->errstr;
        $select_time = $select_time->fetchrow_hashref
          and $rcv_time = ${$select_time}{'time'}
          or $rcv_time = q{-};
        $select_memory = $select_memory->fetchrow_hashref
          and $rcv_memory = ${$select_memory}{'memory'}
          or $rcv_memory = q{-};
        $filestr .=
"driver=${$launch_info}{'driver'};origin=${$launch_info}{'origin'};kernel=${$launch_info}{'kernel'};model=$model;module=$module;main=$main;verdict=${$launch_info}{'verdict'};memory=$rcv_memory;time=$rcv_time;";

        if ( ${$launch_info}{'verdict'} eq 'unknown' ) {
            my $tool_fail_id;
            Readonly my $FOUR => 4;
            my @launch_info_arr = (
                ${$launch_info}{'BCE success'},
                ${$launch_info}{'DEG success'},
                ${$launch_info}{'DSCV success'},
                ${$launch_info}{'RI success'},
                ${$launch_info}{'RCV success'},
            );
            my @launch_info_tool  = qw(BCE DEG DSCV RI RCV);
            my $launch_info_found = 0;
            foreach my $lauch_info_txt (@launch_info_arr) {
                if ( not $lauch_info_txt ) {
                    $launch_info_found = 1;
                    last;
                }
            }
            if ( not $launch_info_found ) {
                print_debug_warning(
                    'All tools finished successfully, but verdict=unknown!');
            }
            else {
                foreach my $info_id ( 0 .. $FOUR ) {
                    if ( not $launch_info_arr[$info_id] ) {
                        $filestr .= "$launch_info_tool[$info_id]_status=fail;";
                        $tool_fail_id =
                          ${$launch_info}{"$launch_info_tool[$info_id] id"};
                        last;
                    }
                }
            }
            $db_problems->execute($tool_fail_id)
              or croak 'Can\'t execute a query: ' . $db_handler->errstr;

            $filestr .= 'problems=';
            while ( my $problem = $db_problems->fetchrow_hashref ) {
                $filestr .= "${$problem}{'problem'};";
            }
        }
        $filestr .= "\n";
    }
    open my $res_file, '>', $result_file
      or croak "Can't open the file '$result_file' for write: $ERRNO";
    print {$res_file} $filestr
      or carp "Couldn\'t print to file '$result_file': $ERRNO";
    close $res_file
      or croak "Can't close the file '$result_file': $ERRNO";
    print_debug_normal 'Results were loaded successfully';
    return;
}
