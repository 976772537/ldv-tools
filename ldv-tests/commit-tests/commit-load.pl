#! /usr/bin/perl -w

use DBI;
use English;
use strict;
use Cwd qw(cwd);
use Getopt::Long qw(GetOptions);
use Env qw(LDV_DEBUG LDV_COMMIT_TEST_LOADER_DEBUG LDVDBCTEST LDVDBHOSTCTEST LDVUSERCTEST LDVDBPASSWDCTEST);
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
sub get_test_opt();

# Print help message on the screen and exit.
# args: no.
# retn: nothing.
sub help();

# Load data from database and print it to file.
# args: no.
# retn: nothing.
sub load_data();
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
get_debug_level($debug_name, $LDV_DEBUG, $LDV_COMMIT_TEST_LOADER_DEBUG);
print_debug_normal("Process the command-line options");
get_test_opt();
print_debug_normal("Starting loading data");
load_data();
#######################################################################
# Subroutines
#######################################################################
sub get_test_opt()
{
	my $opt_help;
	my $opt_result_file;
	unless (GetOptions(
		'help|h' => \$opt_help,
		'result|o=s' => \$opt_result_file))
	{
		warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
		help();
	}
	help() if ($opt_help);
	if($opt_result_file)
	{
		$result_file = $opt_result_file;
	}
	else
	{
		my $current_dir = Cwd::cwd() or die("Can't obtain the current working directory");
		$result_file = $current_dir . '/' . $result_file;
	}
	print_debug_normal("Results will be put in $result_file");
	print_debug_debug("The command-line options are processed successfully");
}

sub help()
{
	print(STDERR << "EOM");
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
	exit(1);
}

sub load_data()
{
	print_debug_debug("Check that database connection is setup");
	die("You don't setup connection to your database. See --help for details")
		unless ($LDVDBCTEST and $LDVUSERCTEST);
	$db_host = $LDVDBHOSTCTEST if ($LDVDBHOSTCTEST);
	my $db_password = $LDVDBPASSWDCTEST if ($LDVDBPASSWDCTEST);
	
	print_debug_debug("Connect to the specified database");
	my $db_handler = DBI->connect("DBI:mysql:$LDVDBCTEST:$db_host", $LDVUSERCTEST, $db_password)
		or die("Can't connect to the database: $DBI::errstr");

	my $db_launches = $db_handler->prepare("
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
		, rule_models.name, scenarios.executable, scenarios.main")
		or die("Can't prepare a query: " . $db_handler->errstr);
	my $db_problems = $db_handler->prepare("
		SELECT problems.name as 'problem'
		FROM stats
		LEFT JOIN problems_stats ON stats.id=problems_stats.stats_id
		LEFT JOIN problems ON problems_stats.problem_id=problems.id
		WHERE stats.id=? AND problems.id IS NOT NULL
		ORDER BY problems.name")
		or die("Can't prepare a query: " . $db_handler->errstr);
		
	
	
	$db_launches->execute or die("Can't execute a query: " . $db_handler->errstr);
	open(my $res_file, '>', "$result_file") or die("Can't open the file '$result_file' for write: $ERRNO");
	while (my $launch_info = $db_launches->fetchrow_hashref)
	{
		my $model = ${$launch_info}{'model'} || 'NULL';
		my $module = ${$launch_info}{'module'} || 'NULL';
		my $main = ${$launch_info}{'main'} || 'NULL';
		my $rcv_memory = 0;
		my $rcv_time = 0;
		my $trace_id = ${$launch_info}{'trace_id'};
		my $select_time = $db_handler->prepare("
			SELECT time_average FROM processes
			WHERE trace_id=$trace_id AND pattern='ALL' AND name='rcv'")
			or die("Can't prepare a select: " . $db_handler->errstr);
		my $select_memory = $db_handler->prepare("
			SELECT time_average FROM processes
			WHERE trace_id=$trace_id AND pattern='memory' AND name='rcv'")
			or die("Can't prepare a select: " . $db_handler->errstr);
	
		$select_time->execute or die("Can't execute a query: " . $db_handler->errstr);
		$select_memory->execute or die("Can't execute a query: " . $db_handler->errstr);
		($select_time = $select_time->fetchrow_hashref and $rcv_time = ${$select_time}{'time_average'})
			or $rcv_time = '-';
		($select_memory = $select_memory->fetchrow_hashref and $rcv_memory = ${$select_memory}{'time_average'})
			or $rcv_memory = '-';
		print($res_file "driver=${$launch_info}{'driver'};origin=${$launch_info}{'origin'};kernel=${$launch_info}{'kernel'};model=$model;module=$module;main=$main;verdict=${$launch_info}{'verdict'};memory=$rcv_memory;time=$rcv_time;");

		if (${$launch_info}{'verdict'} eq 'unknown')
		{
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
								print($res_file "RCV_status=fail;");
								$tool_fail_id = ${$launch_info}{'RCV id'};
							}
						}
						else
						{
							print($res_file "RI_status=fail;");
							$tool_fail_id = ${$launch_info}{'RI id'};
						}
					}
					else
					{
						print($res_file "DSCV_status=fail;");
						$tool_fail_id = ${$launch_info}{'DSCV id'};
					}
				}
				else
				{
					print($res_file "DEG_status=fail;");
					$tool_fail_id = ${$launch_info}{'DEG id'};
				}
			}
			else
			{
				print($res_file "BCE_status=fail;");
				$tool_fail_id = ${$launch_info}{'BCE id'};
			}

			$db_problems->execute($tool_fail_id)
				or die("Can't execute a query: " . $db_handler->errstr);

			print($res_file "problems=");
			my $isfirst = 1;
			while (my $problem = $db_problems->fetchrow_hashref)
			{
				if ($isfirst)
				{
					$isfirst = 0;
				}
				else
				{
					print($res_file ",");
				}
				print($res_file "${$problem}{'problem'};");
			}
		}
		print($res_file "\n");
	}
	close($res_file) or die("Can't close the file '$result_file': $ERRNO\n");
	print_debug_normal("Results were loaded successfully");
}
