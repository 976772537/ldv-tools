#! /usr/bin/perl -w

use English;
use strict;
use Switch;

use Cwd qw(cwd abs_path);
use File::Path qw(mkpath rmtree);
use File::Copy qw(copy);

use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use Env qw(LDV_DEBUG LDV_COMMIT_TEST_DEBUG LDVDBHOSTCTEST LDVDBCTEST LDVUSERCTEST LDVDBPASSWDCTEST);
use FindBin;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../shared/perl");

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

# Read file with test tasks from file that was set in --test-set option.
# args: no.
# retn: nothing
sub get_commit_test_tasks();

# Creates directories for work and results, check files, needed scripts and dirs.
# args: no.
# retn: nothing.
sub prepare_files_and_dirs();

# Run test for all found tasks and copy result pax archives to result dir.
# args: no.
# retn: nothing.
sub run_commit_test();

# Run ldv-manager for one task.
# args: number of task.
# retn: nothing.
sub run_ldv_tools($);

# Change commit for one task.
# args: number of task.
# retn: result of changing (cool/fail/nogit/unknown)
sub change_commit($);

# Upload all pax archives in result dir to specified database with another script.
# args: no.
# retn: nothing.
sub upload_commit_test_results();

# Load all resuls from specified database.
# args: no.
# retn: nothing.
sub load_results();

# Compare result verdicts with verdicts in task file, generates report in 'txt' and 'html' format.
# args: no.
# retn: nothing.
sub check_results_and_print_report();

# Clone repository to current dir and return path to it
# args: name of repository (stable or torvalds)
# retn: path to repository
sub clone_repos($);
#######################################################################
# Global variables
#######################################################################
# Name of this tool
my $debug_name = 'commit-tester';

# Directories where are results
my $current_working_dir;
my $launcher_work_dir;
my $launcher_results_dir;

# File with results of subroutine load_results run.
my $load_result_file = 'load_result.txt';

# Directory with kernels repositories
my $opt_kernels_dir;

# File with tasks that set in --test-set option.
my $opt_task_file;

# Default name of file with results in html and txt format
my $results_in_html = 'commit-tester-results.html';
my $results_in_txt = 'commit-tester-results.txt';

# Tasks parameters are here
my %task_map;

# Number of found tasks in task file.
my $num_of_tasks = 0;

# Temporary place for commit name.
my $new_commit = '';

# The auxiliary directory where commit tests auxiliary scripts are placed.
my $tool_aux_dir = "$FindBin::RealBin/../ldv-tests/commit-tests";

# Scripts required for regression tests performing. They are in the tool
# auxiliary directory.
my $upload_script = 'commit-upload.pl';
my $load_script = 'commit-load.pl';
#######################################################################
# Main section
#######################################################################

# Obtain the debug level.
get_debug_level($debug_name, $LDV_DEBUG, $LDV_COMMIT_TEST_DEBUG);
print_debug_normal("Process the command-line options");
get_test_opt();

$current_working_dir = Cwd::cwd() or die("Can't obtain current directory!");
print_debug_normal("Current directory is '$current_working_dir'");

print_debug_normal("Starting getting tasks..");
get_commit_test_tasks();
print_debug_normal("Starting preparing files and directories..");
prepare_files_and_dirs();
print_debug_normal("Running test..");
run_commit_test();
print_debug_normal("Start uploading results..");
upload_commit_test_results();
print_debug_normal("Starting loading results from the database..");
load_results();
print_debug_normal("Starting generation of results");
check_results_and_print_report();
print_debug_normal("Make all successfully");
#######################################################################
# Subroutines.
#######################################################################
sub get_test_opt()
{
	my $opt_result_file;
	my $opt_help;
	unless (GetOptions(
		'result-file|o=s' => \$opt_result_file,
		'help|h' => \$opt_help,
		'test-set=s' => \$opt_task_file,
		'kernels=s' => \$opt_kernels_dir))
	{
		warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
		help();
	}
	help() if ($opt_help);
	if ($opt_result_file)
	{
		$opt_result_file .= ".html" if ($opt_result_file !~ /.html$/);
		$results_in_html = $opt_result_file;
	}
	print_debug_trace("Results in html format will be written  to '$results_in_html'");
	print_debug_debug("The command-line options are processed successfully");
}

sub help()
{
	print(STDERR << "EOM");
NAME
	$PROGRAM_NAME: The program runs ldv-tools for commits at linux kernels.
SYNOPSIS
	[database sets] [ldv-manager env] $PROGRAM_NAME [option...]
OPTIONS
	-o, --result-file <file>
	   <file> is a file where results will be put in html format. If it isn't
	   specified then the output is placed to the file '$results_in_html'
	   in the current directory. If file was already existed it will be |>>>rewrited<<<|.
	-h, --help
	   Print this help and exit with an error.
	--test-set=<file>
		Run tasks in <file>. You should always write this option.
		You should observe format:
			kernel_place=PATH_TO_KERNEL
			commit=..;rule=..;driver=...ko;main=<x>;verdict=..;ideal_verdict=..;#Comment
		You can use 'repository=<name>' instead of 'kernel_place=<path>' where <name> is
		repository name (for example, 'torvalds' or 'stable').
		You can set a several kernel places:
			kernel_place=PLACE1
			commit=...
			...
			kernel_place=PLACE2
			commit=...
			...
		For no-purpose commits (when ideal verdict is save,
		but result is unsafe as a result of another bug in driver)
		comments should be started with two symbols '##'.
		
		<x> is main or main number. This tool supportes next formats of mains:
			entry_point
			<number>
			<word><number><word>
			n/a
		If you don't know main number you should write 'n/a'.
		For example: 'main=n/a'. In this case you haven't to set 'verdict'.
		
		If rule wasn't developed for any commit you should write 'rule=n/a'.
		In this case you haven't to set 'verdict' and 'main'.
		
		All comments that not in task format are supported.
	--kernels=<path>
		<path> is place where are all needed kernels repositories.
		If needed repository wouldn't be found it will be downloaded
		to the current directory. If cloning will failed see file "clone_log"
		in the current dir.
DATABASE SETS
	LDVDBCTEST=<dbname>
		<dbname> is name of database where results will be uploaded.
		==================================================================
		>>>>>>ATTENTION! All other results will be removed from it.<<<<<<<
		==================================================================
	LDVUSERCTEST=<user>
		<user> is username for <dbname>
	[LDVDBHOSTCTEST=<dbhost>]
		<dbhost> is host of your database. If you didn't set this parameter
		it would be set to 'localhost'.
	[LDVDBPASSWDCTEST=<passwd>]
		<passwd> is password for <user> if you set it.
ldv-manager ENV
	You can set for example RCV_MEMLIMIT, RCV_TIMELIMIT, etc.
-----------------------------------------------------------------------------
-If you have error with switching commit, you could find error trace
	in file commit-test-work/tempfile-<n>, where <n> is number of task
	in your task file.
EOM
	exit(1);
}

sub get_commit_test_tasks()
{
	unless (-f "$opt_task_file")
	{
		print_debug_warning("File with tasks wasn't found!");
		help();
	}
	print_debug_trace("Reading file '$opt_task_file'");
	open (my $commit_test_task, '<', "$opt_task_file")
		or die("Can't open file '$opt_task_file' for read: $ERRNO");
	my $kernel_place;
	my $kernel_name;
	foreach my $task_str (<$commit_test_task>)
	{
		chomp($task_str);
		next if($task_str =~ /^\s*$/);
		if($task_str =~ /^kernel_place=(.*)\s*$/)
		{
			die("Kernel wasn't found") unless (-d "$1");
			$kernel_place = $1;
			if($kernel_place =~ /(.*)\/$/)
			{
				$kernel_place = $1;
			}
			$kernel_name = $kernel_place;
			while(1)
			{
				last unless($kernel_name =~ /\//);
				$kernel_name = $POSTMATCH;
			}
		}
		elsif($task_str =~ /^repository=(.*)\s*$/)
		{
			my $rep_found = 0;
			my $repos_name = $1;
			if($opt_kernels_dir and (-d $opt_kernels_dir))
			{
				foreach my $repos_dir (<$opt_kernels_dir/*>)
				{
					my $repos_config = "$repos_dir/.git/config";
					if((-d "$repos_dir") and (-f $repos_config))
					{
						open(REPCONF, '<', $repos_config)
							or die("Couldn't open $repos_config for read: $ERRNO");
						while(<REPCONF>)
						{
							chomp($_);
							if($_ =~ /\s*url\s*=\s*(.*)$/)
							{
								if($1 =~ /git.*\/$repos_name.*git/)
								{
									$kernel_place = $repos_dir;
									$kernel_place = abs_path($kernel_place);
									$rep_found = 1;
								}
							}
						}
						close(REPCONF);
					}
				}
			}
			unless($rep_found)
			{
				print_debug_debug("Repository '$repos_name' wasn't found, cloning it...");
				my $func_return = clone_repos($repos_name);
				die "Couldn't detect repository with name '$repos_name'!" unless($func_return);
				$kernel_place = $func_return;
			}
			$kernel_name = $kernel_place;
			while(1)
			{
				last unless($kernel_name =~ /\//);
				$kernel_name = $POSTMATCH;
			}
			print_debug_debug("Kernel place = '$kernel_place'");
		}
		elsif($task_str =~ /^commit=(.*);rule=(.*);driver=(.*);main=(.*);verdict=(.*);ideal_verdict=(.*);#(.*)$/)
		{
			if(defined($kernel_place) and defined($kernel_name))
			{
				$num_of_tasks++;
				$task_map{$num_of_tasks} = {
					'commit' => $1,
					'rule' => $2,
					'driver' => $3,
					'main' => $4,
					'verdict' => $5,
					'ideal' => $6,
					'comment' => $7,
					'is_in_final' => 'no',
					'verdict_type' => 1,
					'kernel_name' => $kernel_name,
					'kernel_place' => $kernel_place,
					'problem' => ''
				};
				if($task_map{$num_of_tasks}{'comment'} =~ /^#/)
				{
					$task_map{$num_of_tasks}{'comment'} = $POSTMATCH;
					$task_map{$num_of_tasks}{'verdict_type'} = 2;
				}
				if($task_map{$num_of_tasks}{'main'} =~ /entry_point/)
				{
					$task_map{$num_of_tasks}{'main'} = 0;
				}
				elsif($task_map{$num_of_tasks}{'main'} =~ /^\w*(\d+)\w*$/)
				{
					$task_map{$num_of_tasks}{'main'} = $1;
				}
				else
				{
					$task_map{$num_of_tasks}{'main'} = 'n/a';
					$task_map{$num_of_tasks}{'verdict'} = 'unknown';
				}
			}
			else
			{
				print_debug_warning("You must to set kernel place before tasks!");
				close($commit_test_task) or die("Can't close the file '$opt_task_file': $ERRNO\n");
				help();
			}
		}
		elsif($task_str =~ /^commit=(.*);rule=n\/a;driver=(.*);ideal_verdict=(.*);#(.*)$/)
		{
			$num_of_tasks++;
			my $na_kernel_name = 'n/a';
			$na_kernel_name = $kernel_name if(defined($kernel_name));
			$task_map{$num_of_tasks} = {
					'commit' => $1,
					'rule' => 'n/a',
					'driver' => $2,
					'main' => 9999,
					'verdict' => '',
					'ideal' => $3,
					'comment' => $4,
					'is_in_final' => 'no',
					'verdict_type' => 0,
					'kernel_name' => $na_kernel_name,
					'kernel_place' => '',
					'problem' => ''
			};
		}
		elsif($task_str =~ /^commit=(.*);rule=(.*);driver=(.*);main=\D+;ideal_verdict=(.*);#(.*)$/)
		{
			$num_of_tasks++;
			my $na_kernel_name = 'n/a';
			$na_kernel_name = $kernel_name if(defined($kernel_name));
			$task_map{$num_of_tasks} = {
					'commit' => $1,
					'rule' => $2,
					'driver' => $3,
					'main' => 'n/a',
					'verdict' => 'unknown',
					'ideal' => $4,
					'comment' => $5,
					'is_in_final' => 'no',
					'verdict_type' => 0,
					'kernel_name' => $na_kernel_name,
					'kernel_place' => '',
					'problem' => ''
			};
		}
	}
	close($commit_test_task) or die("Can't close the file '$opt_task_file': $ERRNO\n");
	print_debug_normal("Tasks was got successfully. Number of found tasks is $num_of_tasks");
}

sub prepare_files_and_dirs()
{
	$upload_script = "$tool_aux_dir/$upload_script";
	$load_script = "$tool_aux_dir/$load_script";
	die("Uploader script wasn't found") unless(-x $upload_script);
	die("Loader script wasn't found") unless(-x $load_script);

	$launcher_work_dir = $current_working_dir . "/commit-test-work";
	$launcher_results_dir = $current_working_dir . "/commit-test-results";
	print_debug_debug("Creating directories for work");
	mkpath("$launcher_work_dir")
		or die("Couldn't recursively create directory '$launcher_work_dir': $ERRNO");
	mkpath("$launcher_results_dir")
		or die("Couldn't recursively create directory '$launcher_results_dir': $ERRNO");
	my $i = 1;
	my $commit_test_work_dir;
	while($i <= $num_of_tasks)
	{
		if($i < 10)
		{
			$commit_test_work_dir = 'task-00' . $i . '--' . $task_map{$i}{'kernel_name'} . '--dir';
		}
		elsif($i < 100)
		{
			$commit_test_work_dir = 'task-0' . $i . '--' . $task_map{$i}{'kernel_name'} . '--dir';
		}
		else
		{
			$commit_test_work_dir = 'task-' . $i . '--' . $task_map{$i}{'kernel_name'} . '--dir';
		}
		$task_map{$i}{'workdir'} = $commit_test_work_dir;
		mkpath("$launcher_work_dir/$commit_test_work_dir")
			or die("Couldn't recursively create work directory '$commit_test_work_dir': $ERRNO");
		mkpath("$launcher_results_dir/$commit_test_work_dir")
			or die("Couldn't recursively create result directory '$commit_test_work_dir': $ERRNO");
		$i++;
	}
	print_debug_normal("Directories and files were prepared successfully");
}

sub run_commit_test()
{
	my $i = 1;
	while($i <= $num_of_tasks)
	{
		if(($task_map{$i}{'rule'} !~ /^n\/a$/) and ($task_map{$i}{'main'} =~ /^\d+$/))
		{
			switch (change_commit($i))
			{
				case 'fail'
				{
					print_debug_warning("There is no such commit: '$task_map{$i}{'commit'}'!");
					$task_map{$i}{'problem'} = "There is no such commit: '$task_map{$i}{'commit'}'!";
				}
				case 'nogit'
				{
					print_debug_warning("Not a git repository: '$task_map{$i}{'kernel_place'}'!!");
					$task_map{$i}{'problem'} = "Not a git repository: '$task_map{$i}{'kernel_place'}'!!";
				}
				case 'cool'
				{
					print_debug_normal("Kernel HEAD is now at '$task_map{$i}{'commit'}' = '$new_commit'..");
					run_ldv_tools($i);
				}
				else
				{
					print_debug_warning("Unknown error in switching commit!");
					$task_map{$i}{'problem'} = "Unknown error in switching commit!";
				}
			}
		}
		$i++;
	}
}

sub change_commit($)
{
	my $i = shift;
	my $result = 'unknown';
	my $file_temp = "$launcher_work_dir/tempfile-$i";
	my $switch_commit_task = "git checkout $task_map{$i}{'commit'} 2>&1 | tee $file_temp";
	chdir("$task_map{$i}{'kernel_place'}");
	print_debug_debug("Execute the command '$switch_commit_task'");
	system($switch_commit_task);
	die("Switching commit failed!") if(check_system_call());
	chdir("$current_working_dir");
	open(MYFILE, '<', $file_temp)	or die("Couldn't open $file_temp for read: $ERRNO");

	while(<MYFILE>)
	{
		if($_ =~ /HEAD is now at (.*).../)
		{
			$new_commit = $1;
			$result = 'cool';
			last;
		}
		elsif ($_ =~ /error: pathspec.*did not match any file.*known to git/)
		{
			$result = 'fail';
			print_debug_warning("Commit '$task_map{$i}{'commit'}' wasn't found");
			last;
		}
		elsif($_ =~/fatal: Not a git repository/)
		{
			$result = 'nogit';
			print_debug_warning("Not a git repository: '$task_map{$i}{'kernel_place'}'");
			last;
		}
	}
	close(MYFILE) or die("Couldn't close file $file_temp");
	unlink("$file_temp") unless($result eq 'unknown');
	return $result;
}

sub run_ldv_tools($)
{
	my $i = shift;
	my $ldv_work_dir = "$launcher_work_dir/$task_map{$i}{'workdir'}";
	print_debug_normal("Run ldv-tools for commit=$task_map{$i}{'commit'}, task number is $i");
	chdir($ldv_work_dir);
	if($task_map{$i}{'kernel_place'} =~ /(.*)$task_map{$i}{'kernel_name'}$/)
	{
		my $tmp_kernel_dir;
		$tmp_kernel_dir = $1 . "$task_map{$i}{'kernel_name'}-$task_map{$i}{'commit'}";
		while($tmp_kernel_dir =~ /^(.*)~(.*)$/)
		{
			$tmp_kernel_dir = $1 . "-" . $2;
		}
		rename ("$task_map{$i}{'kernel_place'}", "$tmp_kernel_dir");
		unless(-d "$tmp_kernel_dir")
		{
			print_debug_warning("Couldn't rename '$task_map{$i}{'kernel_place'}' to '$tmp_kernel_dir'");
			exit(1);
		}
		print_debug_debug("Successfully rename '$task_map{$i}{'kernel_place'}' to '$tmp_kernel_dir'");
		my @ldv_manager_task = ("ldv-manager",
								"envs=$tmp_kernel_dir",
								"kernel_driver=1",
								"drivers=$task_map{$i}{'driver'}",
								"rule_models=$task_map{$i}{'rule'}");
		print_debug_debug("Executing command @ldv_manager_task");
		system(@ldv_manager_task);
		if(check_system_call() == -1)
		{
			print_debug_warning("There is no the ldv-manager executable in your PATH!");
			rename ("$tmp_kernel_dir", "$task_map{$i}{'kernel_place'}");
			print_debug_warning("Couldn't rename '$tmp_kernel_dir' to '$task_map{$i}{'kernel_place'}'")
				unless(-d "$task_map{$i}{'kernel_place'}");
			exit(1);
		}
		rename ("$tmp_kernel_dir", "$task_map{$i}{'kernel_place'}");
		unless(-d "$task_map{$i}{'kernel_place'}")
		{
			print_debug_warning("Couldn't rename '$tmp_kernel_dir' to '$task_map{$i}{'kernel_place'}'");
			exit(1);
		}
		print_debug_debug("Successfully rename '$tmp_kernel_dir' to '$task_map{$i}{'kernel_place'}'");
	}
	foreach my $file (<$ldv_work_dir/finished/*.pax>)
	{
		print_debug_debug("Copying pax archives to result dir '$task_map{$i}{'workdir'}'");
		copy("$file", "$launcher_results_dir/$task_map{$i}{'workdir'}");
	}
	print_debug_debug("Removing 'inst' directory..");
	rmtree("$ldv_work_dir/inst");
	chdir($current_working_dir);
	print_debug_normal("ldv-manager was successfully finished.");
}

sub upload_commit_test_results()
{
	my @upload_my_res = ($upload_script, "--results=$launcher_results_dir");
	print_debug_debug("Executing command '@upload_my_res'");
	system(@upload_my_res);
	die("Uploader script failed!") if(check_system_call());
	print_debug_normal("Results were successfully uploaded");
}

sub load_results()
{
	my @load_task = ($load_script, "--result=$launcher_results_dir/$load_result_file");
	print_debug_debug("Execute the command @load_task");
	system(@load_task);
	die("Loader script failed!") if(check_system_call());
	print_debug_normal("Results were successfully loaded to '$launcher_results_dir/$load_result_file'");
}

sub check_results_and_print_report()
{
	my $file;
	my %temp_map;
	my $num_of_load_tasks = 0;
	my $final_results;

	my $num_safe_safe = 0;
	my $num_safe_unsafe = 0;
	my $num_safe_unknown = 0;
	my $num_unsafe_safe = 0;
	my $num_unsafe_unsafe = 0;
	my $num_unsafe_unknown = 0;
	my $num_unknown_safe = 0;
	my $num_unknown_unsafe = 0;
	my $num_unknown_unknown = 0;
	my $num_ideal_safe_safe = 0;
	my $num_ideal_safe_unsafe = 0;
	my $num_ideal_safe_unknown = 0;
	my $num_ideal_unsafe_safe = 0;
	my $num_ideal_unsafe_unsafe = 0;
	my $num_ideal_unsafe_unknown = 0;
	my $num_of_found_bugs = 0;
	my $num_of_all_bugs = 0;
	
	open($file, "<", "$launcher_results_dir/$load_result_file")
		or die("Couldn't open $load_result_file for read: $ERRNO");
	while(my $line = <$file>)
	{
		chomp($line);
		if($line =~ /^driver=(.*);origin=kernel;kernel=(.*);model=(.*);module=.*;main=\w*(\d+)\w*;verdict=(\w+)/)
		{
			$num_of_load_tasks++;
			$temp_map{$num_of_load_tasks} = {
				'driver' => $1,
				'kernel' => $2,
				'rule' => $3,
				'main' => $4,
				'verdict' => $5,
				'status' => 'na',
				'problems' => 'na'
			};

			if(($temp_map{$num_of_load_tasks}{'verdict'} eq 'unknown')
				and ($POSTMATCH =~ /^;(.*);problems=(.*)$/))
			{
				$temp_map{$num_of_load_tasks}{'status'} = $1;
				$temp_map{$num_of_load_tasks}{'problems'} = $2;
			}
		}
		elsif($line =~ /^driver=(.*);origin=kernel;kernel=(.*);model=(.*);module=.*;main=entry_point;verdict=(\w+)/)
		{
			$num_of_load_tasks++;
			$temp_map{$num_of_load_tasks} = {
				'driver' => $1,
				'kernel' => $2,
				'rule' => $3,
				'main' => 0,
				'verdict' => $4,
				'status' => 'na',
				'problems' => 'na'
			};
			if(($temp_map{$num_of_load_tasks}{'verdict'} eq 'unknown')
				and ($POSTMATCH =~ /^;(.*);problems=(.*)$/))
			{
				$temp_map{$num_of_load_tasks}{'status'} = $1;
				$temp_map{$num_of_load_tasks}{'problems'} = $2;
			}

			my $k = 1;
			while($k <= $num_of_tasks)
			{
				my $temp2_name_of_kernel = "$task_map{$k}{'kernel_name'}-$task_map{$k}{'commit'}";
				while($temp2_name_of_kernel =~ /^(.*)~(.*)$/)
				{
					$temp2_name_of_kernel = $1 . "-" . $2;
				}
				if(($task_map{$k}{'driver'} eq $temp_map{$num_of_load_tasks}{'driver'}) and
				($task_map{$k}{'rule'} eq $temp_map{$num_of_load_tasks}{'rule'}) and
				($temp2_name_of_kernel eq $temp_map{$num_of_load_tasks}{'kernel'}))
				{
					$task_map{$k}{'main'} = 0;
				}
				$k++;
			}
		}
	}
	close($file) or die("Couldn't close $load_result_file: $ERRNO");
	
	open($final_results, ">", "$launcher_results_dir/$results_in_txt")
		or die("Couldn't open $launcher_results_dir/$results_in_txt for write: $ERRNO");
	open(my $html_results, ">", "$results_in_html")
		or die("Couldn't open $results_in_html for write: $ERRNO");
	print($html_results "<!DOCTYPE html>
<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">\n<html>
	<head>
		<style type=\"text\/css\">
		body {background-color:#FFEBCD}
		p {color:#2F4F4F}
		th {color:#FFA500}
		td {background:#98FB98}
		td {color:#191970}
		th {background:#3CB371}
		</style>
	</head>
<body>

<h1 align=center style=\"color:#FF4500\"><u>Commit tests results</u></h1>

<p style=\"color:#483D8B\"><big>Result table:</big></p>

<table border=\"2\">\n<tr>
	<th>№</th>
	<th>Rule</th>
	<th>Kernel</th>
	<th>Commit</th>
	<th>Module</th>
	<th>Main</th>
	<th>Ideal->New verdict</th>
	<th>Old->New verdict</th>
	<th>Comment</th>
	<th>Problems</th>\n</tr>");
	my $i = 1;
	my $cnt = 1;
	my $num_of_all_checked_bugs = 0;
	while($i <= $num_of_tasks)
	{
		my $j = 1;
		while($j <= $num_of_load_tasks)
		{
			my $temp_name_of_kernel = "$task_map{$i}{'kernel_name'}-$task_map{$i}{'commit'}";
			while($temp_name_of_kernel =~ /^(.*)~(.*)$/)
			{
				$temp_name_of_kernel = $1 . "-" . $2;
			}

			if(($task_map{$i}{'driver'} eq $temp_map{$j}{'driver'}) and
				($task_map{$i}{'rule'} eq $temp_map{$j}{'rule'}) and
				($task_map{$i}{'main'} eq $temp_map{$j}{'main'}) and
				($temp_name_of_kernel eq $temp_map{$j}{'kernel'}))
			{
				$task_map{$i}{'is_in_final'} = 'yes';
				print($final_results "Commit=$task_map{$i}{'commit'}; kernel=$task_map{$i}{'kernel_name'};
Ideal Verdict: $task_map{$i}{'ideal'}; Real Verdict: $task_map{$i}{'verdict'}->$temp_map{$j}{'verdict'};\n");
				print($final_results "This unsafe is no-purpose\n")
					if(($task_map{$i}{'verdict_type'} == 2)
						and ($task_map{$i}{'verdict'} eq 'unsafe')
						and ($temp_map{$j}{'verdict'} eq 'unsafe'));
				print($final_results "Comment: $task_map{$i}{'comment'};");
				print($final_results "Problems: $temp_map{$j}{'status'};")
					unless($temp_map{$j}{'status'} eq 'na');
				print($final_results  " $temp_map{$j}{'problems'}")
					unless($temp_map{$j}{'problems'} eq 'na');

				print($final_results "\n\n");
				
				$num_of_found_bugs++ if(($temp_map{$j}{'verdict'} eq 'unsafe')
											and ($task_map{$i}{'verdict_type'} == 1)
											and ($task_map{$i}{'ideal'} eq 'unsafe'));
				$num_safe_unsafe++ if(($task_map{$i}{'verdict'} eq 'safe')
										  and ($temp_map{$j}{'verdict'} eq 'unsafe'));
				$num_safe_unknown++ if(($task_map{$i}{'verdict'} eq 'safe')
										  and ($temp_map{$j}{'verdict'} eq 'unknown'));
				$num_unsafe_safe++ if(($task_map{$i}{'verdict'} eq 'unsafe')
										  and ($temp_map{$j}{'verdict'} eq 'safe'));
  				$num_safe_safe++ if(($task_map{$i}{'verdict'} eq 'safe')
										  and ($temp_map{$j}{'verdict'} eq 'safe'));
  				$num_unsafe_unsafe++ if(($task_map{$i}{'verdict'} eq 'unsafe')
										  and ($temp_map{$j}{'verdict'} eq 'unsafe'));
  				$num_unknown_unknown++ if(($task_map{$i}{'verdict'} eq 'unknown')
										  and ($temp_map{$j}{'verdict'} eq 'unknown'));
				$num_unsafe_unknown++ if(($task_map{$i}{'verdict'} eq 'unsafe')
										  and ($temp_map{$j}{'verdict'} eq 'unknown'));
				$num_unknown_unsafe++ if(($task_map{$i}{'verdict'} eq 'unknown')
										  and ($temp_map{$j}{'verdict'} eq 'unsafe'));
				$num_unknown_safe++ if(($task_map{$i}{'verdict'} eq 'unknown')
										  and ($temp_map{$j}{'verdict'} eq 'safe'));
				$num_ideal_safe_unsafe++ if(($task_map{$i}{'ideal'} eq 'safe')
												and ($temp_map{$j}{'verdict'} eq 'unsafe'));
				$num_ideal_safe_safe++ if(($task_map{$i}{'ideal'} eq 'safe')
												and ($temp_map{$j}{'verdict'} eq 'safe'));
				$num_ideal_unsafe_unsafe++ if(($task_map{$i}{'ideal'} eq 'unsafe')
												and ($temp_map{$j}{'verdict'} eq 'unsafe'));
				$num_ideal_safe_unknown++ if(($task_map{$i}{'ideal'} eq 'safe')
												and ($temp_map{$j}{'verdict'} eq 'unknown'));
				$num_ideal_unsafe_safe++ if(($task_map{$i}{'ideal'} eq 'unsafe')
												and ($temp_map{$j}{'verdict'} eq 'safe'));
				$num_ideal_unsafe_unknown++ if(($task_map{$i}{'ideal'} eq 'unsafe')
												and ($temp_map{$j}{'verdict'} eq 'unknown'));
				print($html_results "\n<tr>
						<td>$cnt</td>
						<td>$task_map{$i}{'rule'}</td>
						<td>$task_map{$i}{'kernel_name'}</td>
						<td>$task_map{$i}{'commit'}</td>
						<td><small>$task_map{$i}{'driver'}</small></td>
						<td>$task_map{$i}{'main'}</td>
						<td style=\"color:#");
				if($task_map{$i}{'ideal'} ne $temp_map{$j}{'verdict'})
				{
					print($html_results "CD2626");
				}
				else
				{
					print($html_results "191970");
				}
				print($html_results ";background:#9F79EE")
					if(($task_map{$i}{'verdict_type'} == 2)
						and ($task_map{$i}{'ideal'} eq 'unsafe'));
				print($html_results "\">$task_map{$i}{'ideal'}->$temp_map{$j}{'verdict'}</td>
						<td");
				print($html_results " style=\"color:#CD2626\"") if($task_map{$i}{'verdict'} ne $temp_map{$j}{'verdict'});
				print($html_results ">$task_map{$i}{'verdict'}->$temp_map{$j}{'verdict'}</td>
						<td><small>$task_map{$i}{'comment'}</small></td>
						<td><small>");
				print ($html_results "$temp_map{$j}{'problems'}") unless($temp_map{$j}{'problems'} eq 'na');
				print($html_results "</small></td>\n</tr>\n");
				$num_of_all_checked_bugs++ if ($task_map{$i}{'ideal'} eq 'unsafe');
				$cnt++;
			}
			$j++;
		}
		$i++;
	}
	$i = 1;
	my $num_of_unknown_mains = 0;
	my $num_of_undev_rules = 0;
	while($i <= $num_of_tasks)
	{
		if(($task_map{$i}{'is_in_final'} eq 'no')
			and ($task_map{$i}{'main'} =~ /^\d+$/)
			and ($task_map{$i}{'rule'} !~ /^n\/a/))
		{
			print($final_results "Commit $task_map{$i}{'commit'} wasn't tested in any reason.\n");
			print($final_results "Problem is: $task_map{$i}{'problem'}\n\n");
			print($html_results "\n<tr>
						<td>$cnt</td>
						<td>$task_map{$i}{'rule'}</td>
						<td>$task_map{$i}{'kernel_name'}</td>
						<td>$task_map{$i}{'commit'}</td>
						<td>$task_map{$i}{'driver'}</td>
						<td>$task_map{$i}{'main'}</td>
						<td style=\"color:#CD2626");
						
			print($html_results ";background:#9F79EE")
				if(($task_map{$i}{'verdict_type'} == 2)
					and ($task_map{$i}{'ideal'} eq 'unsafe'));
			print($html_results "\">$task_map{$i}{'ideal'}->unknown</td>\n\t\t<td");
			print($html_results " style=\"color:#CD2626\"") if($task_map{$i}{'verdict'} ne 'unknown');
			print($html_results ">$task_map{$i}{'verdict'}->unknown</td>
					<td><small>$task_map{$i}{'comment'}</small></td>
					<td><small>$task_map{$i}{'problem'}</small></td>\n</tr>\n");
			$num_safe_unknown++ if($task_map{$i}{'verdict'} eq 'safe');
			$num_unsafe_unknown++ if($task_map{$i}{'verdict'} eq 'unsafe');
			$num_ideal_safe_unknown++ if($task_map{$i}{'ideal'} eq 'safe');
			$num_ideal_unsafe_unknown++ if($task_map{$i}{'ideal'} eq 'unsafe');
			$cnt++;
		}
		if(($task_map{$i}{'ideal'} eq 'unsafe'))
		{
			$num_of_all_bugs++;
		}
		$num_of_unknown_mains++ if($task_map{$i}{'main'} !~ /^\d+$/);
		$num_of_undev_rules++ if($task_map{$i}{'rule'} =~ /^n\/a/);
		$i++;
	}
	print($html_results "<\/table>\n<br>\n<br>");

	print($final_results "SUMMARY\n
	safe->unsafe: $num_safe_unsafe;
	safe->unknown: $num_safe_unknown;
	unsafe->safe: $num_unsafe_safe;
	unsafe->unknown: $num_unsafe_unknown;
	unknown->safe: $num_unknown_safe;
	unknown->unsafe: $num_unknown_unsafe;\n\nTARGET BUGS\nLdv-tools found $num_of_found_bugs of $num_of_all_checked_bugs bugs;<br>
Total number of bugs: $num_of_all_bugs;\n");
	my $temp_db_host = 'localhost';
	$temp_db_host = $LDVDBHOSTCTEST if ($LDVDBHOSTCTEST);
	my $link_to_results = "http://$temp_db_host:8999/stats/index/name/$LDVDBCTEST/host/$temp_db_host/user/$LDVUSERCTEST/password/";
	if($LDVDBPASSWDCTEST)
	{
		$link_to_results .= "$LDVDBPASSWDCTEST";
	}
	else
	{
		$link_to_results .= 'no';
	}

	print($html_results "<hr>\n<a href=\"$link_to_results\">Link to visualizer with your results.</a>");
	print($html_results "\n<hr>
	<p style=\"color:#483D8B\"><big>Summary</big></p>
	<table border=\"1\">\n<tr>
	<th style=\"color:#00008B;background:#66CD00\"></th>
	<th style=\"color:#00008B;background:#66CD00\">Old->New verdict</th>
	<th style=\"color:#00008B;background:#66CD00\">Ideal->New verdict</th>\n</tr>
	<tr>
	<th style=\"color:#00008B;background:#66CD00\">safe->safe:</th>
	<td style=\"color:#00008B;background:#CAFF70\">$num_safe_safe</td>
	<td style=\"color:#00008B;background:#CAFF70\">$num_ideal_safe_safe</td>
	</tr>
	<tr>
	<th style=\"color:#00008B;background:#66CD00\">unsafe->unsafe:</th>
	<td style=\"color:#00008B;background:#CAFF70\">$num_unsafe_unsafe</td>
	<td style=\"color:#00008B;background:#CAFF70\">$num_ideal_unsafe_unsafe</td>
	</tr>
	<tr>
	<th style=\"color:#00008B;background:#66CD00\">safe->unsafe:</th>
	<td style=\"color:#00008B;background:#CAFF70\">$num_safe_unsafe</td>
	<td style=\"color:#00008B;background:#CAFF70\">$num_ideal_safe_unsafe</td>
	</tr>
	<tr>
	<th style=\"color:#00008B;background:#66CD00\">safe->unknown:</th>
	<td style=\"color:#00008B;background:#CAFF70\">$num_safe_unknown</td>
	<td style=\"color:#00008B;background:#CAFF70\">$num_ideal_safe_unknown</td>
	</tr>
	<tr>
	<th style=\"color:#00008B;background:#66CD00\">unsafe->safe:</th>
	<td style=\"color:#00008B;background:#CAFF70\">$num_unsafe_safe</td>
	<td style=\"color:#00008B;background:#CAFF70\">$num_ideal_unsafe_safe</td>
	</tr>
	<tr>
	<th style=\"color:#00008B;background:#66CD00\">unsafe->unknown:</th>
	<td style=\"color:#00008B;background:#CAFF70\">$num_unsafe_unknown</td>
	<td style=\"color:#00008B;background:#CAFF70\">$num_ideal_unsafe_unknown</td>
	</tr>
	<tr>
	<th style=\"color:#00008B;background:#66CD00\">unknown->safe:</th>
	<td style=\"color:#00008B;background:#CAFF70\">$num_unknown_safe</td>
	<td style=\"color:#00008B;background:#CAFF70\">-</td>
	</tr>
	<tr>
	<th style=\"color:#00008B;background:#66CD00\">unknown->unsafe:</th>
	<td style=\"color:#00008B;background:#CAFF70\">$num_unknown_unsafe</td>
	<td style=\"color:#00008B;background:#CAFF70\">-</td>
	</tr>
	<tr>
	<th style=\"color:#00008B;background:#66CD00\">unknown->unknown:</th>
	<td style=\"color:#00008B;background:#CAFF70\">$num_unknown_unknown</td>
	<td style=\"color:#00008B;background:#CAFF70\">-</td>
	</tr>
	</table>
	<p style=\"color:#A52A2A\">No main: $num_of_unknown_mains;<br>No_rule: $num_of_undev_rules;</p>
	<hr>
	<p style=\"color:#483D8B\"><big>Target bugs</big></p>
	<p>Ldv-tools found $num_of_found_bugs of $num_of_all_checked_bugs bugs;<br>
Total number of bugs: $num_of_all_bugs;</p>\n");
	my $cnt2 = 0;
	print($html_results "<hr><p style=\"color:#483D8B\"><big>Modules with unknown mains:</big></p>
		<table border=\"1\">\n<tr>
			<th style=\"background:#00C5CD;color:#191970\">№</th>
			<th style=\"background:#00C5CD;color:#191970\">Rule</th>
			<th style=\"background:#00C5CD;color:#191970\">Kernel</th>
			<th style=\"background:#00C5CD;color:#191970\">Commit</th>
			<th style=\"background:#00C5CD;color:#191970\">Module</th>
			<th style=\"background:#00C5CD;color:#191970\">Ideal verdict</th>
			<th style=\"background:#00C5CD;color:#191970\">Comment</th>
			</tr>");
	$i = 1;
	while($i <= $num_of_tasks)
	{
		if($task_map{$i}{'main'} !~ /^\d+$/)
		{
			$cnt2++;
			print($html_results "<tr>
			<td style=\"background:#87CEFF;color:#551A8B\">$cnt2</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$task_map{$i}{'rule'}</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$task_map{$i}{'kernel_name'}</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$task_map{$i}{'commit'}</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$task_map{$i}{'driver'}</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$task_map{$i}{'ideal'}</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$task_map{$i}{'comment'}</td>\n</tr>");
		}
		$i++;
	}
	print($html_results "</table>\n<br>");
	
	my $cnt3 = 0;
	print($html_results "<hr><p style=\"color:#483D8B\"><big>Undeveloped rules:</big></p><table border=\"1\">\n<tr>
			<th style=\"background:#CD5555;color:#363636\">№</th>
			<th style=\"background:#CD5555;color:#363636\">Kernel</th>
			<th style=\"background:#CD5555;color:#363636\">Commit</th>
			<th style=\"background:#CD5555;color:#363636\">Module</th>
			<th style=\"background:#CD5555;color:#363636\">Ideal verdict</th>
			<th style=\"background:#CD5555;color:#363636\">Comment</th>
			</tr>");
	$i = 1;
	while($i <= $num_of_tasks)
	{
		if($task_map{$i}{'rule'} =~ /^n\/a$/)
		{
			$cnt3++;
			print($html_results "<tr>
			<td style=\"background:#FFC1C1;color:#363636\">$cnt3</td>
			<td style=\"background:#FFC1C1;color:#363636\">$task_map{$i}{'kernel_name'}</td>
			<td style=\"background:#FFC1C1;color:#363636\">$task_map{$i}{'commit'}</td>
			<td style=\"background:#FFC1C1;color:#363636\">$task_map{$i}{'driver'}</td>
			<td style=\"background:#FFC1C1;color:#363636\">$task_map{$i}{'ideal'}</td>
			<td style=\"background:#FFC1C1;color:#363636\">$task_map{$i}{'comment'}</td>\n</tr>");
		}
		$i++;
	}
	print($html_results "\n</table>\n");
	
	print($html_results "<p style=\"color:#CD2626\"><big>You have similar tasks in your task file.
	Results are duplicated!</big></p>\n") if($cnt > ($num_of_tasks + 1));
	print($html_results "</body>\n</html>");

	close($final_results) or die("Couldn't close $launcher_results_dir/results.txt: $ERRNO");
	close($html_results) or die("Couldn't close $results_in_html: $ERRNO");
	print_debug_normal("Results were successfully generated: '$launcher_results_dir/$results_in_txt', '$results_in_html'");
}

sub clone_repos($)
{
	my $rep_name = shift;
	my $ret_place;
	my $repository_clone = "$tool_aux_dir/repository.cfg";
	if(-f "$repository_clone")
	{
		open(MYREPCONG, '<', $repository_clone)
			or die "Couldn't open '$repository_clone' for read: $ERRNO";
		while(<MYREPCONG>)
		{
			chomp($_);
			if($_ =~ /^.*\/$rep_name\/.*git/)
			{
				print_debug_debug("Execute command 'git clone $_'");
				system("git clone $_ 2>&1 | tee git_clone_log");
					open(CLOLOG, '<', "git_clone_log") or die "Couldn't open clone_log for read!";
					while(<CLOLOG>)
					{
						chomp($_);
						if($_ =~ /Cloning into '(.*)'.../)
						{
							$ret_place = $current_working_dir . '/' . $1;
							die "Couldn't clone $_" unless(-d $ret_place);
							unlink("git_clone_log");
							return $ret_place;
						}
						elsif($_ =~ /fatal:(.*)$/)
						{
							die "FATAL ERROR while cloning repository to the current dir: $1";
						}
					}
					close(CLOLOG);
			}
		}
		close(MYREPCONG);
	}
	else
	{
		die "Couldn't find file with repositories!";
	}
	return $ret_place;
}
