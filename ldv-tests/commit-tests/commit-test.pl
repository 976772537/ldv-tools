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
# args: name of repository
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
my $report_script = 'commit-tester-report.pl';

my $comment_for_report;

my $do_rewrite;
#######################################################################
# Main section
#######################################################################

# Obtain the debug level.
get_debug_level($debug_name, $LDV_DEBUG, $LDV_COMMIT_TEST_DEBUG);
print_debug_normal("Process the command-line options");
get_test_opt();

$current_working_dir = Cwd::cwd() or die("Can't obtain current directory!");
print_debug_normal("Current directory is '$current_working_dir'");
$launcher_work_dir = $current_working_dir . "/commit-tester-work";
$launcher_results_dir = $current_working_dir . "/commit-tester-results";
print_debug_debug("Creating directories for work");
mkpath("$launcher_work_dir")
	or die("Couldn't recursively create directory '$launcher_work_dir': $ERRNO");
mkpath("$launcher_results_dir")
	or die("Couldn't recursively create directory '$launcher_results_dir': $ERRNO");

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
		'kernels=s' => \$opt_kernels_dir,
		'comment|c=s' => \$comment_for_report,
		'rewrite' => \$do_rewrite))
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
	$comment_for_report = '('.$comment_for_report.')' if($comment_for_report);
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
	   in the current directory. If file was already existed you will be
	   asked if you want to rewrite it.
	-h, --help
	   Print this help and exit with an error.
	--test-set=<file>
		Run tasks in <file>. You should always write this option.
		You should observe format:
			kernel_place=PATH_TO_KERNEL
			commit=..;rule=..;driver=...ko;main=<main>;verdict=..;ideal_verdict=..;#Comment
		You can use 'repository=<name>' instead of 'kernel_place=<path>' where <name> is
		adress of repository (for example 'git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git').
		You can set a several kernel places:
			kernel_place=PLACE1
			commit=...
			...
			kernel_place=PLACE2
			commit=...
			...
		For no-purpose commits (when ideal verdict is safe,
		but result is unsafe as a result of another bug in driver)
		comments should be started with two symbols '##'.
		
		<main> is main. This tool supportes next formats of mains:

		If you don't know main number you should write 'n/a'.
		For example: 'main=n/a'. In this case you haven't to set 'verdict'.
		
		If rule wasn't developed for any commit you should write 'rule=n/a'.
		In this case you haven't to set 'verdict' and 'main'.
		
		Russian comments are also supported.
	--kernels=<path>
		<path> is place where are all needed kernels repositories.
		If needed repository wouldn't be found it will be downloaded
		to the current directory. If cloning will failed see file "clone_log"
		in the current dir.
	--comment="..."
		comment that will be showed at the head of the table.
	--rewrite
		Do not ask confirm of html file rewriting if it already exists.
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

sub prepare_files_and_dirs()
{
	$upload_script = "$tool_aux_dir/$upload_script";
	$load_script = "$tool_aux_dir/$load_script";
	$report_script = "$tool_aux_dir/$report_script";
	die("Uploader script wasn't found") unless(-x $upload_script);
	die("Loader script wasn't found") unless(-x $load_script);
	die("Report script wasn't found") unless(-x $report_script);
	
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
		mkpath("$launcher_work_dir/$commit_test_work_dir")
			or die("Couldn't recursively create work directory '$commit_test_work_dir': $ERRNO");
		mkpath("$launcher_results_dir/$commit_test_work_dir")
			or die("Couldn't recursively create result directory '$commit_test_work_dir': $ERRNO");
		$task_map{$i}{'workdir'} = $commit_test_work_dir;
		$i++;
	}
	print_debug_normal("Directories and files were prepared successfully");
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
								if($1 =~ /$repos_name/)
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
			else
			{
				foreach my $repos_dir (<$current_working_dir/*>)
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
								if($1 =~ /$repos_name/)
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
			if($rep_found)
			{
				print_debug_debug("Repository '$repos_name' was found, copying it...");
				my $func_return = clone_repos($kernel_place);
				die "Couldn't detect repository with name '$repos_name' after copying!" unless($func_return);
				$kernel_place = $func_return;
			}
			else
			{
				print_debug_debug("Repository '$repos_name' wasn't found, cloning it...");
				my $func_return = clone_repos($repos_name);
				die "Couldn't detect repository with name '$repos_name' after cloning!" unless($func_return);
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
		elsif($task_str =~ /^commit=(.*);arch_opt=(.*);config=(.*);rule=(.*);driver=(.*);main=(.*);verdict=(.*);ideal_verdict=(.*);#(.*)$/)
		{
			if(defined($kernel_place) and defined($kernel_name))
			{
				$num_of_tasks++;
				$task_map{$num_of_tasks} = {
					'commit' => $1,
					'arch_opt' => $2,
					'config' => $3,
					'rule' => $4,
					'driver' => $5,
					'main' => $6,
					'verdict' => $7,
					'ideal' => $8,
					'comment' => $9,
					'is_in_final' => 'no',
					'verdict_type' => 1,
					'kernel_name' => $kernel_name,
					'kernel_place' => $kernel_place,
					'problem' => '',
					'ldv_run' => 1
				};
				if($task_map{$num_of_tasks}{'comment'} =~ /^#/)
				{
					$task_map{$num_of_tasks}{'comment'} = $POSTMATCH;
					$task_map{$num_of_tasks}{'verdict_type'} = 2;
				}
				if(($task_map{$num_of_tasks}{'main'} eq 'n/a')
					or ($task_map{$num_of_tasks}{'rule'} eq 'n/a'))
				{
					$task_map{$num_of_tasks}{'verdict'} = 'unknown';
					$task_map{$num_of_tasks}{'ldv_run'} = 0;
				}
				die "Couldn't find '$tool_aux_dir/configs/$task_map{$num_of_tasks}{'config'}'"
					unless(-f "$tool_aux_dir/configs/$task_map{$num_of_tasks}{'config'}");
			}
			else
			{
				print_debug_warning("You must set kernel place before tasks!");
				close($commit_test_task) or die("Can't close the file '$opt_task_file': $ERRNO\n");
				help();
			}
		}
		elsif($task_str =~ /^commit=(.*);arch_opt=(.*);rule=(.*);driver=(.*);main=(.*);verdict=(.*);ideal_verdict=(.*);#(.*)$/)
		{
			if(defined($kernel_place) and defined($kernel_name))
			{
				$num_of_tasks++;
				$task_map{$num_of_tasks} = {
					'commit' => $1,
					'arch_opt' => $2,
					'rule' => $3,
					'driver' => $4,
					'main' => $5,
					'verdict' => $6,
					'ideal' => $7,
					'comment' => $8,
					'is_in_final' => 'no',
					'verdict_type' => 1,
					'kernel_name' => $kernel_name,
					'kernel_place' => $kernel_place,
					'problem' => '',
					'ldv_run' => 1
				};
				if($task_map{$num_of_tasks}{'comment'} =~ /^#/)
				{
					$task_map{$num_of_tasks}{'comment'} = $POSTMATCH;
					$task_map{$num_of_tasks}{'verdict_type'} = 2;
				}
				if(($task_map{$num_of_tasks}{'main'} eq 'n/a')
					or ($task_map{$num_of_tasks}{'rule'} eq 'n/a'))
				{
					$task_map{$num_of_tasks}{'verdict'} = 'unknown';
					$task_map{$num_of_tasks}{'ldv_run'} = 0;
				}
			}
			else
			{
				print_debug_warning("You must set kernel place before tasks!");
				close($commit_test_task) or die("Can't close the file '$opt_task_file': $ERRNO\n");
				help();
			}
		}
		elsif($task_str =~ /^commit=(.*);config=(.*);rule=(.*);driver=(.*);main=(.*);verdict=(.*);ideal_verdict=(.*);#(.*)$/)
		{
			if(defined($kernel_place) and defined($kernel_name))
			{
				$num_of_tasks++;
				$task_map{$num_of_tasks} = {
					'commit' => $1,
					'config' => $2,
					'rule' => $3,
					'driver' => $4,
					'main' => $5,
					'verdict' => $6,
					'ideal' => $7,
					'comment' => $8,
					'is_in_final' => 'no',
					'verdict_type' => 1,
					'kernel_name' => $kernel_name,
					'kernel_place' => $kernel_place,
					'problem' => '',
					'ldv_run' => 1
				};
				if($task_map{$num_of_tasks}{'comment'} =~ /^#/)
				{
					$task_map{$num_of_tasks}{'comment'} = $POSTMATCH;
					$task_map{$num_of_tasks}{'verdict_type'} = 2;
				}
				if(($task_map{$num_of_tasks}{'main'} eq 'n/a')
					or ($task_map{$num_of_tasks}{'rule'} eq 'n/a'))
				{
					$task_map{$num_of_tasks}{'verdict'} = 'unknown';
					$task_map{$num_of_tasks}{'ldv_run'} = 0;
				}
				die "Couldn't find '$tool_aux_dir/configs/$task_map{$num_of_tasks}{'config'}'"
					unless(-f "$tool_aux_dir/configs/$task_map{$num_of_tasks}{'config'}");
			}
			else
			{
				print_debug_warning("You must set kernel place before tasks!");
				close($commit_test_task) or die("Can't close the file '$opt_task_file': $ERRNO\n");
				help();
			}
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
					'problem' => '',
					'ldv_run' => 1
				};
				if($task_map{$num_of_tasks}{'comment'} =~ /^#/)
				{
					$task_map{$num_of_tasks}{'comment'} = $POSTMATCH;
					$task_map{$num_of_tasks}{'verdict_type'} = 2;
				}
				if(($task_map{$num_of_tasks}{'main'} eq 'n/a')
					or ($task_map{$num_of_tasks}{'rule'} eq 'n/a'))
				{
					$task_map{$num_of_tasks}{'verdict'} = 'unknown';
					$task_map{$num_of_tasks}{'ldv_run'} = 0;
				}
			}
			else
			{
				print_debug_warning("You must set kernel place before tasks!");
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
					'main' => 'n/a',
					'verdict' => '',
					'ideal' => $3,
					'comment' => $4,
					'is_in_final' => 'no',
					'verdict_type' => 0,
					'kernel_name' => $na_kernel_name,
					'kernel_place' => '',
					'problem' => '',
					'ldv_run' => 0
			};
		}
		elsif($task_str =~ /^commit=(.*);rule=(.*);driver=(.*);main=.*;ideal_verdict=(.*);#(.*)$/)
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
					'problem' => '',
					'ldv_run' => 0
			};
		}
	}
	close($commit_test_task) or die("Can't close the file '$opt_task_file': $ERRNO\n");
	print_debug_normal("Tasks was got successfully. Number of found tasks is $num_of_tasks");
}

sub run_commit_test()
{
	my $i = 1;
	while($i <= $num_of_tasks)
	{
		if($task_map{$i}{'ldv_run'})
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
					foreach my $main_key (keys %task_map)
					{
						$task_map{$main_key}{'ldv_run'} = 0
							if(($task_map{$main_key}{'commit'} eq $task_map{$i}{'commit'})
							and ($task_map{$main_key}{'driver'} eq $task_map{$i}{'driver'})
							and ($task_map{$main_key}{'rule'} eq $task_map{$i}{'rule'})
							and ($task_map{$main_key}{'kernel_name'} eq $task_map{$i}{'kernel_name'}));
					}
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
		if($_ =~ /HEAD is now at (.*)... /)
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
		my $ldv_manager_task = "";
		$ldv_manager_task .= "LDV_ASPECTATOR=aspectator CONFIG_OPT=$task_map{$i}{'arch_opt'} " if($task_map{$i}{'arch_opt'});
		$ldv_manager_task .= "CONFIG_FILE=$tool_aux_dir/configs/$task_map{$i}{'config'} " if($task_map{$i}{'config'});
		$ldv_manager_task .= "ldv-manager envs=$tmp_kernel_dir kernel_driver=1 drivers=$task_map{$i}{'driver'} rule_models=$task_map{$i}{'rule'}";

		print_debug_debug("Executing command '$ldv_manager_task'");
		system($ldv_manager_task);
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
	open($file, "<", "$launcher_results_dir/$load_result_file")
		or die("Couldn't open $load_result_file for read: $ERRNO");
	while(my $line = <$file>)
	{
		chomp($line);
		if($line =~ /^driver=.*;origin=kernel;kernel=(.*);model=(.*);module=(.*);main=(.*);verdict=(.*);memory=(.*);time=(\d+)/)
		{
			$num_of_load_tasks++;
			$temp_map{$num_of_load_tasks} = {
				'driver' => $3,
				'kernel' => $1,
				'rule' => $2,
				'main' => $4,
				'verdict' => $5,
				'memory' => $6,
				'time' => $7,
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
	}
	close($file) or die("Couldn't close $load_result_file: $ERRNO");
	
	open(my $final_results, ">", "$launcher_results_dir/$results_in_txt")
		or die("Couldn't open $launcher_results_dir/$results_in_txt for write: $ERRNO");
		
	my $verifier = 'blast';
	$verifier = $ENV{'RCV_VERIFIER'} if($ENV{'RCV_VERIFIER'});
	my $timelimit = '15m';
	$timelimit = $ENV{'RCV_TIMELIMIT'} if($ENV{'RCV_TIMELIMIT'});
	my $memlimit = '1Gb';
	$memlimit = $ENV{'RCV_MEMLIMIT'} if($ENV{'RCV_MEMLIMIT'});
	my ($local_time_min, $local_time_hour, $local_time_day, $local_time_mon, $local_time_year) = (localtime)[1,2,3,4,5];
	printf($final_results "name_of_runtask=$verifier;<br>timelimit=$timelimit;<br>memlimit=$memlimit;<br>%02d.%02d.%04d %02d:%02d<br>$comment_for_report\n",
		$local_time_day, $local_time_mon + 1, $local_time_year + 1900, $local_time_hour, $local_time_min);
	print($final_results "verifier=$verifier\n");

	for(my $i = 1; $i <= $num_of_tasks; $i++)
	{
		for(my $j = 1; $j <= $num_of_load_tasks; $j++)
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
				print($final_results "commit=$task_map{$i}{'commit'};memory=$temp_map{$j}{'memory'};time=$temp_map{$j}{'time'};");
				print($final_results "rule=$task_map{$i}{'rule'};kernel=$task_map{$i}{'kernel_name'};driver=$task_map{$i}{'driver'};");
				print($final_results "main=$task_map{$i}{'main'};verdict=$temp_map{$j}{'verdict'};");
				print($final_results "ideal_verdict=$task_map{$i}{'ideal'};old_verdict=$task_map{$i}{'verdict'};#");
				print($final_results "#") if($task_map{$num_of_tasks}{'verdict_type'} == 2);
				print($final_results "$task_map{$i}{'comment'}<@>");
				print($final_results "$temp_map{$j}{'status'}; ")	unless($temp_map{$j}{'status'} eq 'na');
				print($final_results "$temp_map{$j}{'problems'}")	unless($temp_map{$j}{'problems'} eq 'na');
				print($final_results "\n");
			}
		}
	}
	for(my $i = 1; $i <= $num_of_tasks; $i++)
	{
		if(($task_map{$i}{'is_in_final'} eq 'no')
			and ($task_map{$i}{'main'} ne 'n/a')
			and ($task_map{$i}{'rule'} ne 'n/a'))
		{
			print($final_results "commit=$task_map{$i}{'commit'};memory=0;time=0;rule=$task_map{$i}{'rule'};");
			print($final_results "kernel=$task_map{$i}{'kernel_name'};driver=$task_map{$i}{'driver'};");
			print($final_results "main=$task_map{$i}{'main'};verdict=unknown;");
			print($final_results "ideal_verdict=$task_map{$i}{'ideal'};old_verdict=$task_map{$i}{'verdict'};#");
			print($final_results "#") if($task_map{$num_of_tasks}{'verdict_type'} == 2);
			print($final_results "$task_map{$i}{'comment'}");
			print($final_results "<@>failed before or at RI");
			print($final_results "\n");
		}
		if(($task_map{$i}{'main'} eq 'n/a') or ($task_map{$i}{'rule'} eq 'n/a'))
		{
			print($final_results "commit=$task_map{$i}{'commit'};memory=-;time=-;rule=$task_map{$i}{'rule'};kernel=$task_map{$i}{'kernel_name'};");
			print($final_results "driver=$task_map{$i}{'driver'};main=n/a;verdict=unknown;");
			print($final_results "ideal_verdict=$task_map{$i}{'ideal'};old_verdict=$task_map{$i}{'verdict'};");
			print($final_results "#$task_map{$i}{'comment'}<@>\n");
		}
	}
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
	print($final_results "link_to_results=$link_to_results\n");
	
	close($final_results) or die("Couldn't close $launcher_results_dir/results.txt: $ERRNO");
	print_debug_normal("File with results were generated: '$launcher_results_dir/$results_in_txt'");
	my $report_command = "$report_script --files $launcher_results_dir/$results_in_txt -o $results_in_html";
	$report_command .= " --rewrite" if($do_rewrite);
	print_debug_trace "Execute the command '$report_command'";
	system($report_command);
	print_debug_warning "Report script failed!" if(check_system_call());
}

sub clone_repos($)
{
	my $rep_name = shift;
	my $ret_place;
	chdir($rep_name);
	print_debug_debug("Execute command 'git fetch' at '$rep_name'.");
	system("git fetch");
	chdir($launcher_work_dir);
	print_debug_debug("Execute command 'git clone $rep_name'");
	system("git clone $rep_name 2>&1 | tee git_clone_log");
	chdir($current_working_dir);
	open(CLOLOG, '<', "$launcher_work_dir/git_clone_log")
		or die "Couldn't open '$launcher_work_dir/clone_log' for read!";
	while(<CLOLOG>)
	{
		chomp($_);
		if($_ =~ /Cloning into '(.*)'.../)
		{
			close(CLOLOG);
			$ret_place = $launcher_work_dir . '/' . $1;
			die "Couldn't clone $rep_name" unless(-d $ret_place);
			unlink("$launcher_work_dir/git_clone_log");
			return $ret_place;
		}
		elsif($_ =~ /fatal:(.*)$/)
		{
			close(CLOLOG);
			die "FATAL ERROR while cloning repository to the current dir:$1";
		}
	}
	close(CLOLOG);
	return $ret_place;
}
