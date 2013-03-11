#! /usr/bin/perl -w

use English;
use strict;
use Switch;

use Cwd qw(cwd);
use File::Path qw(mkpath rmtree);
use File::Copy qw(copy);

use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use Env qw(LDV_DEBUG LDV_COMMIT_TEST_DEBUG LDVDBHOSTCTEST LDVDBCTEST LDVUSERCTEST LDVDBPASSWDCTEST);
use FindBin;
use lib("$FindBin::RealBin/../shared/perl");

use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info
  print_debug_debug print_debug_trace print_debug_all get_debug_level
  check_system_call);

#######################################################################
# Subroutine prototypes.
#######################################################################
sub get_test_opt();

sub help();

sub get_commit_test_tasks();

sub prepare_files_and_dirs();

sub run_commit_test();

sub run_ldv_tools($);

sub change_commit($);

sub upload_commit_test_results();

sub upload_right_results($);

sub load_results();
sub check_results_and_print_report();
#######################################################################
# Global variables
#######################################################################
my $current_working_dir;
my $launcher_work_dir;
my $launcher_results_dir;

my $opt_result_file;
my $load_result_file = 'load_result.txt';
my $opt_task_file;
my $results_in_html = 'commit-testing-results.html';
my $debug_name = 'commit-tester';

my %task_map;

my $num_of_tasks = 0;
my $opt_help;
my $new_commit = '';

my $tool_aux_dir = "$FindBin::RealBin/../ldv-tests/commit-tests";

my $upload_script = 'commit-upload.pl';
my $load_script = 'commit-load.pl';

#######################################################################
# Main section
#######################################################################
get_debug_level($debug_name, $LDV_DEBUG, $LDV_COMMIT_TEST_DEBUG);
print_debug_normal("Process the command-line options");
get_test_opt();
print_debug_normal("Starting getting tasks..");
get_commit_test_tasks();
print_debug_normal("Starting preparing files and directories..");
prepare_files_and_dirs();
print_debug_normal("Running test..");
run_commit_test();
upload_commit_test_results();
print_debug_normal("Starting loading results from the database..");
load_results();
print_debug_normal("Starting generation of results");
check_results_and_print_report();
print_debug_normal("Make all successfully..");
#######################################################################
# Subroutines.
#######################################################################
sub get_test_opt()
{
	unless (GetOptions(
		'result-file|o=s' => \$opt_result_file,
		'help|h' => \$opt_help,
		'test-set=s' => \$opt_task_file))
	{
		warn("Incorrect options may completely change the meaning! 
		Please run script with the --help option to see how you may use this tool.");
		help();
	}
	
	help() if ($opt_help);
	$results_in_html = $opt_result_file if ($opt_result_file);
	
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
	   specified then the output is placed to the file '$opt_result_file'
	   in the current directory. If file was already existed it will be |>>>rewrited<<<|.
	-h, --help
	   Print this help and exit with an error.
	--test-set=<file>
		Run tasks in <file>. You should always write this option.
		You should observe format:
			kernel_place=PATH_TO_KERNEL
			commit=..;rule=..;driver=...ko;main_num=<x>;verdict=..;ideal_verdict=..;#Comment
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
		Also you can leave some empty strings if it would be easy-to-use.
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
		<passwd> is password for <user> if you set it up.
ldv-manager ENV
	You can set for example RCV_MEMLIMIT, RCV_TIMELIMIT, etc.
EOM
	exit(1);
}

sub prepare_files_and_dirs()
{
	$upload_script = "$tool_aux_dir/$upload_script";
	$load_script = "$tool_aux_dir/$load_script";

	die("Uploader script wasn't found") unless(-x $upload_script);
	die("Loader script wasn't found") unless(-x $load_script);
	$current_working_dir = Cwd::cwd() or die("Can't obtain current directory!");
	print_debug_normal("Current directory is '$current_working_dir'");

	$launcher_work_dir = $current_working_dir . "/commit-test-work";
	$launcher_results_dir = $current_working_dir . "/commit-test-results";
	mkpath("$launcher_work_dir")
		or die("Couldn't recursively create directory '$launcher_work_dir': $ERRNO");
	mkpath("$launcher_results_dir")
		or die("Couldn't recursively create directory '$launcher_results_dir': $ERRNO");
	my $i = 1;
	my $commit_test_work_dir;
	while($i <= $num_of_tasks)
	{
		$commit_test_work_dir = 'task-' . $i . '--' . $task_map{$i}{'kernel_name'} . '--dir';
		$task_map{$i}{'workdir'} = $commit_test_work_dir;
		mkpath("$launcher_work_dir/$commit_test_work_dir")
			or die("Couldn't recursively create work directory '$commit_test_work_dir': $ERRNO");
		mkpath("$launcher_results_dir/$commit_test_work_dir")
			or die("Couldn't recursively create result directory '$commit_test_work_dir': $ERRNO");
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
	open (my $commit_test_task, '<', "$opt_task_file")
		or die("Can't open file '$opt_task_file' for read: $ERRNO");
	my $kernel_place;
	my $kernel_name;
	foreach my $task_str (<$commit_test_task>)
	{
		chomp($task_str);
		next if ($task_str =~ /^\s*$/);
		if($task_str =~ /^kernel_place=(.*)\s*$/)
		{
			die("Kernel wasn't found") unless (-d "$1");
			$kernel_place = $1;
			if ($kernel_place =~ /(.*)\/$/)
			{
				$kernel_place = $1;
			}
			$kernel_name = $kernel_place;
			while(1)
			{
				last unless ($kernel_name =~ /\//);
				$kernel_name = $POSTMATCH;
			}
		}
		elsif ($task_str =~ /^commit=(.*);rule=(.*);driver=(.*);main_num=(.*);verdict=(.*);ideal_verdict=(.*);#(.*)$/)
		{
			if(defined($kernel_place) and defined($kernel_name))
			{
				$num_of_tasks++;
				$task_map{$num_of_tasks} = {
					'commit' => $1,
					'rule' => $2,
					'driver' => $3,
					'main_num' => $4,
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
			}
			else
			{
				print_debug_warning("You must to set kernel place before tasks!");
				close($commit_test_task) or die("Can't close the file '$opt_task_file': $ERRNO\n");
				help();
			}
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
				print_debug_normal("Kernel HEAD is now '$task_map{$i}{'commit'}' = '$new_commit'..");
				run_ldv_tools($i);
			}
			else
			{
				print_debug_warning("Unknown error in switching commit!");
				$task_map{$i}{'problem'} = "Unknown error in switching commit!";
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
	system($switch_commit_task);
	die("Switching commit failed!") if(check_system_call());
	open(MYFILE, '<', $file_temp)
		or die("Couldn't open $file_temp for read: $ERRNO");

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
			last;
		}
		elsif($_ =~/fatal: Not a git repository/)
		{
			$result = 'nogit';
			last;
		}
	}
	close(MYFILE) or die("Couldn't close file $file_temp");
	unless($result eq 'unknown')
	{
		unlink("$file_temp");
	}
	chdir("$current_working_dir");
	return $result;
}

sub run_ldv_tools($)
{
	my $i = shift;
	my $ldv_work_dir = "$launcher_work_dir/$task_map{$i}{'workdir'}";
	print_debug_normal("Run ldv-tools for commit=$task_map{$i}{'commit'}");
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
			unless(-d "$task_map{$i}{'kernel_place'}")
			{
				print_debug_warning("Couldn't rename '$tmp_kernel_dir' to '$task_map{$i}{'kernel_place'}'");
			}
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
				
	foreach my $file (<$launcher_work_dir/$task_map{$i}{'workdir'}/finished/*.pax>)
	{
		copy("$file", "$launcher_results_dir/$task_map{$i}{'workdir'}");
	}
	chdir($current_working_dir);
	print_debug_normal("ldv-manager was successfully finished.");
}

sub upload_commit_test_results()
{
	print_debug_normal("Start uploading results..");
	my @upload_my_res = ($upload_script, "--results=$launcher_results_dir");

	print_debug_debug("Executing command '@upload_my_res'");
	system(@upload_my_res);
	die("Uploader script failed!") if(check_system_call());
	print_debug_normal("Results were successfully uploaded");
}


sub load_results()
{
	my @load_task = ($load_script,
					  "--resdir=$launcher_results_dir",
					  "--result=$launcher_results_dir/$load_result_file");
	print_debug_debug("Execute the command @load_task");
	system(@load_task);
	die("Loader script failed!") if(check_system_call());
}

sub check_results_and_print_report()
{
	my $file;
	my %temp_map;
	my $num_of_load_tasks = 0;
	my $final_results;
	
	my $num_safe_unsafe = 0;
	my $num_safe_unknown = 0;
	my $num_unsafe_unknown = 0;
	my $num_unsafe_safe = 0;
	my $num_unknown_safe = 0;
	my $num_unknown_unsafe = 0;
	my $num_of_found_bugs = 0;
	my $num_of_all_bugs = 0;
	
	open($file, "<", "$launcher_results_dir/$load_result_file") or die("Couldn't open $load_result_file for read: $ERRNO");
	while(my $line = <$file>)
	{
		chomp($line);
		if($line =~ /^driver=(.*);origin=kernel;kernel=(.*);model=(.*);module=.*;main=ldv_main(\d+)_sequence_infinite_withcheck_stateful;verdict=(\w+)/)
		{
			$num_of_load_tasks++;
			$temp_map{$num_of_load_tasks} = {
				'driver' => $1,
				'kernel' => $2,
				'rule' => $3,
				'main_num' => $4,
				'verdict' => $5,
				'status' => 'na',
				'problems' => 'na'
			};

			if(($temp_map{$num_of_load_tasks}{'verdict'} eq 'unknown') and $POSTMATCH = ~ /^;(.*);problems=(.*)$/)
			{
				$temp_map{$num_of_load_tasks}{'status'} = $1;
				$temp_map{$num_of_load_tasks}{'problems'} = $2;
			}
		}
	}
	close($file) or die("Couldn't close $load_result_file: $ERRNO");
	
	open($final_results, ">", "$launcher_results_dir/final_results.txt") or die("Couldn't open $launcher_results_dir/final_results.txt for write: $ERRNO");
	open(my $html_results, ">", "$results_in_html") or die("Couldn't open $results_in_html for write: $ERRNO");
	print($html_results "<!DOCTYPE html>
	<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\"> 
<html>
	<head>
		<style type=\"text\/css\">
		body {background-color:rgb(255, 235, 205) }
		p {color:rgb(47, 79, 79)}
		th {color:#FFA500}
		td {background:rgb(152, 251, 152)}
		td {color:#191970}
		th {background:#3CB371}
		</style>
	</head>
<body>

<h1 align=center style=\"color:#FF4500\">Commit tests results</h1>

<p style=\"color:#483D8B\"><big>Result table:</big></p>

<table border=\"2\">
	<tr>
		<th>Rule</th>
		<th>Kernel</th>
		<th>Commit</th>
		<th>Module</th>
		<th>Main</th>
		<th>Ideal verdict</th>
		<th>Real->New verdict</th>
		<th>Comment</th>
		<th>Problems</th>
	</tr>");
	my $i = 1;
	while($i <= $num_of_tasks)
	{
		my $j = 1;
		while($j <= $num_of_load_tasks)
		{
			my $temp_name_of_kernel = "kernel-$task_map{$i}{'commit'}";
			while($temp_name_of_kernel =~ /^(.*)~(.*)$/)
			{
				$temp_name_of_kernel = $1 . "-" . $2;
			}

			if(($task_map{$i}{'driver'} eq $temp_map{$j}{'driver'}) and
				($task_map{$i}{'rule'} eq $temp_map{$j}{'rule'}) and
				($task_map{$i}{'main_num'} eq $temp_map{$j}{'main_num'}) and
				($temp_name_of_kernel eq $temp_map{$j}{'kernel'})
			)
			{
				$task_map{$i}{'is_in_final'} = 'yes';
				print($final_results "Commit=$task_map{$i}{'commit'}; kernel=$task_map{$i}{'kernel_name'};
Ideal Verdict: $task_map{$i}{'ideal'}; Real Verdict: $task_map{$i}{'verdict'}->$temp_map{$j}{'verdict'};\n");
				print($final_results "This unsafe is no-purpose\n")
					if(($task_map{$i}{'verdict_type'} eq 2)
						and ($task_map{$i}{'verdict'} eq 'unsafe')
						and ($temp_map{$j}{'verdict'} eq 'unsafe'));
				print($final_results "Comment: $task_map{$i}{'comment'};");
				print($final_results "Problems: $temp_map{$j}{'status'};")
					unless($temp_map{$j}{'status'} eq 'na');
				print($final_results  " $temp_map{$j}{'problems'}")
					unless($temp_map{$j}{'problems'} eq 'na');

				print($final_results "\n\n");
				
				$num_of_found_bugs++ if(($temp_map{$j}{'verdict'} eq 'unsafe')
											and ($task_map{$i}{'verdict_type'} eq 1)
											and ($task_map{$i}{'ideal'} eq 'unsafe'));
				$num_safe_unsafe++ if(($task_map{$i}{'verdict'} eq 'safe')
										  and ($temp_map{$j}{'verdict'} eq 'unsafe'));
				$num_safe_unknown++ if(($task_map{$i}{'verdict'} eq 'safe')
										  and ($temp_map{$j}{'verdict'} eq 'unknown'));
				$num_unsafe_safe++ if(($task_map{$i}{'verdict'} eq 'unsafe')
										  and ($temp_map{$j}{'verdict'} eq 'safe'));
				$num_unsafe_unknown++ if(($task_map{$i}{'verdict'} eq 'unsafe')
										  and ($temp_map{$j}{'verdict'} eq 'unknown'));
				$num_unknown_unsafe++ if(($task_map{$i}{'verdict'} eq 'unknown')
										  and ($temp_map{$j}{'verdict'} eq 'unsafe'));
				$num_unknown_safe++ if(($task_map{$i}{'verdict'} eq 'unknown')
										  and ($temp_map{$j}{'verdict'} eq 'safe'));
				
				print($html_results "
						<tr><td>$task_map{$i}{'rule'}</td>
						<td>$task_map{$i}{'kernel_name'}</td>
						<td>$task_map{$i}{'commit'}</td>
						<td><small>$task_map{$i}{'driver'}</small></td>
						<td>$task_map{$i}{'main_num'}</td>
						<td>$task_map{$i}{'ideal'}</td>
						<td");
				print($html_results " style=\"color:#8B8386\"") if($task_map{$i}{'verdict_type'} eq 2);
				print($html_results ">$task_map{$i}{'verdict'}->$temp_map{$j}{'verdict'}</td>
						<td");
				print($html_results " style=\"color:#8B8386\"") if($task_map{$i}{'verdict_type'} eq 2);
				print($html_results "><small>$task_map{$i}{'comment'}</small></td>
						<td><small>");
				print ($html_results "$temp_map{$j}{'problems'}") unless($temp_map{$j}{'problems'} eq 'na');
				print($html_results "</small></td></tr>");
			}
			$j++;
		}
		$i++;
	}
	$i = 1;
	while($i <= $num_of_tasks)
	{
		if($task_map{$i}{'is_in_final'} eq 'no')
		{
			print($final_results "Commit $task_map{$i}{'commit'} wasn't tested in any reason.\n");
			print($final_results "Problem is: $task_map{$i}{'problem'}\n\n");
			print($html_results "
						<tr><td>$task_map{$i}{'rule'}</td>
						<td>$task_map{$i}{'kernel_name'}</td>
						<td>$task_map{$i}{'commit'}</td>
						<td>$task_map{$i}{'driver'}</td>
						<td>$task_map{$i}{'main_num'}</td>
						<td>$task_map{$i}{'ideal'}</td>
						<td");
			print($html_results " style=\"color:#8B8386\"") if($task_map{$i}{'verdict_type'} eq 2);
			print($html_results ">$task_map{$i}{'verdict'}->unknown</td>
						<td");
			print($html_results " style=\"color:#8B8386\"") if($task_map{$i}{'verdict_type'} eq 2);
			print($html_results "><small>$task_map{$i}{'comment'}</small></td>
								<td><small>$task_map{$i}{'problem'}</small></td></tr>");
			$num_safe_unknown++ if($task_map{$i}{'verdict'} eq 'safe');
			$num_unsafe_unknown++ if($task_map{$i}{'verdict'} eq 'unsafe');
		}
		if(($task_map{$i}{'ideal'} eq 'unsafe'))
		{
			$num_of_all_bugs++;
		}
		$i++;
	}
	
	print($final_results "SUMMARY\n
safe->unsafe: $num_safe_unsafe;
safe->unknown: $num_safe_unknown;
unsafe->safe: $num_unsafe_safe;
unsafe->unknown: $num_unsafe_unknown;
unknown->safe: $num_unknown_safe;
unknown->unsafe: $num_unknown_unsafe;\n\nTARGET BUGS\nLdv-tools found $num_of_found_bugs of $num_of_all_bugs bugs;\n");
print($html_results "<\/table>
<br>
<br>");
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

print($html_results "<hr>
<a href=\"$link_to_results\">Result paxes are here.</a>") if($link_to_results);
print($html_results "
<hr>
<p style=\"color:#483D8B\"><big>Summary</big></p>
<p>safe->unsafe: $num_safe_unsafe<br>
safe->unknown: $num_safe_unknown<br>
unsafe->safe: $num_unsafe_safe<br>
unsafe->unknown: $num_unsafe_unknown<br>
unknown->safe: $num_unknown_safe<br>
unknown->unsafe: $num_unknown_unsafe<br>
</p>
<p style=\"color:#483D8B\"><big>Target bugs</big></p>
<p>Ldv-tools found $num_of_found_bugs of $num_of_all_bugs bugs</p>
</body>
</html>");

	close($final_results) or die("Couldn't close $launcher_results_dir/final_results.txt: $ERRNO");
	close($html_results) or die("Couldn't close $results_in_html: $ERRNO");
}
