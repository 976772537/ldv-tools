#! /usr/bin/perl -w

use English;
use strict;
use Cwd qw(cwd abs_path);
use File::Path qw(mkpath);
use File::Copy qw(copy);

use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);

use Env qw(LDV_DEBUG);

use FindBin;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../../shared/perl");

# Add some nonstandard local Perl packages.
use LDV::Utils qw(print_debug_warning print_debug_normal print_debug_info
	print_debug_debug print_debug_trace print_debug_all get_debug_level
	check_system_call);

#######################################################################
# Subroutine prototypes.
#######################################################################

# Process command-line options. To see detailed description of these options
# run script with --help option.
# args: no.
# retn: nothing.
sub get_opt();

sub create_double_report($$);

sub create_report($);

sub create_several_report(@);

#######################################################################
# Global variables
#######################################################################
my $debug_name = 'commit-tester-report';

my $report_file = "commit-tester-results-x2.html";
my $num_of_files;

my @several_files;
#######################################################################
# Main section.
#######################################################################
get_debug_level($debug_name, $LDV_DEBUG);

get_opt();
if(-f "$report_file")
{
	print "File $report_file already exists. Do you want to rewrite it? (y/n) > ";
	my $ans = <STDIN>;
	chomp($ans);
	if($ans ne 'y')
	{
		print "Exiting without generating html report!\n";
		exit(1);
	}
}
if($num_of_files == 2)
{
	#create_double_report($several_files[0], $several_files[1]);
}
elsif($num_of_files == 1)
{
	#create_report($several_files[0]);
}
else
{
	create_several_report(@several_files);
}

#######################################################################
# Subroutines.
#######################################################################

sub get_opt()
{
	my $opt_result_file;
	my $opt_help;
	my $opt_several_files;
	unless (GetOptions(
		'result-file|o=s' => \$opt_result_file,
		'help|h' => \$opt_help,
		'files=s'=> \$opt_several_files))
	{
		warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
		help();
	}
	help() if ($opt_help);
	@several_files = split(/\s+|;|,/, $opt_several_files);
	if ($opt_result_file)
	{
		$opt_result_file .= ".html" if ($opt_result_file !~ /.html$/);
		$report_file = $opt_result_file;
	}
	$num_of_files = @several_files;
	die "You should set --files=\"<files>\"" unless($num_of_files);
	my $i;
	for($i = 0; $i < $num_of_files; $i++)
	{
		die "Couldn't find file '$several_files[$i]'!" unless(-f $several_files[$i]);
		$several_files[$i] = abs_path($several_files[$i]);
	}
	print_debug_trace("Results in html format will be written  to '$report_file'");
	print_debug_debug("The command-line options are processed successfully. Number of files: '$num_of_files'");
}

sub create_report($)
{
	my $file_txt = shift;
	print_debug_normal "Generating report from results: '$file_txt'";
	my $file_in;
	my $html_results;
	my $link;
	my $num_of_tasks = 0;
	my %results_map;
	print_debug_trace "Reading results..";
	open($file_in, '<', $file_txt) or die "Couldn't open file '$file_txt' for read: $ERRNO!";
	while(<$file_in>)
	{
		chomp($_);
		if($_ =~ /commit=(.*);rule=(.*);kernel=(.*);driver=(.*);main=(.*);verdict=(.*);ideal_verdict=(.*);old_verdict=(.*?);#(.*)<@>(.*)$/)
		{
			$num_of_tasks++;
			$results_map{$num_of_tasks} = {
					'commit' => $1,
					'rule' => $2,
					'kernel' => $3,
					'driver' => $4,
					'main' => $5,
					'new_verdict' => $6,
					'ideal_verdict' => $7,
					'old_verdict' => $8,
					'comment' => $9,
					'problems' => $10,
					'verdict_type' => 0
			};
			if($results_map{$num_of_tasks}{'comment'} =~ /^#/)
			{
				$results_map{$num_of_tasks}{'comment'} = $POSTMATCH;
				$results_map{$num_of_tasks}{'verdict_type'} = 1;
			}
		}
		elsif($_ =~ /link_to_results=(.*)/)
		{
			$link = $1;
		}
	}
	close($file_in);
	
	if($num_of_tasks == 0)
	{
		print_debug_warning "Entry file '$file_txt' hasn't results!\n";
		exit(1);
	}
	print_debug_trace "Results were read. Number of found tasks: $num_of_tasks";
	
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
	my $num_of_unknown_mains = 0;
	my $num_of_undev_rules = 0;

	print_debug_trace "Writing html file..";
	open($html_results, '>', $report_file) or die "Couldn't open file '$html_results' for write: $ERRNO!";
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
	my $cnt = 0;
	for(my $i = 1; $i <= $num_of_tasks; $i++)
	{
		if(($results_map{$i}{'main'} ne 'n/a')
			and ($results_map{$i}{'rule'} ne 'n/a'))
		{
			$cnt++;
			$num_of_found_bugs++ if(($results_map{$i}{'new_verdict'} eq 'unsafe')
										and ($results_map{$i}{'verdict_type'} == 0)
										and ($results_map{$i}{'ideal_verdict'} eq 'unsafe'));
			$num_safe_unsafe++ if(($results_map{$i}{'old_verdict'} eq 'safe')
									  and ($results_map{$i}{'new_verdict'} eq 'unsafe'));
			$num_safe_unknown++ if(($results_map{$i}{'old_verdict'} eq 'safe')
									  and ($results_map{$i}{'new_verdict'} eq 'unknown'));
			$num_unsafe_safe++ if(($results_map{$i}{'old_verdict'} eq 'unsafe')
									  and ($results_map{$i}{'new_verdict'} eq 'safe'));
  			$num_safe_safe++ if(($results_map{$i}{'old_verdict'} eq 'safe')
									and ($results_map{$i}{'new_verdict'} eq 'safe'));
  			$num_unsafe_unsafe++ if(($results_map{$i}{'old_verdict'} eq 'unsafe')
										and ($results_map{$i}{'new_verdict'} eq 'unsafe'));
  			$num_unknown_unknown++ if(($results_map{$i}{'old_verdict'} eq 'unknown')
										  and ($results_map{$i}{'new_verdict'} eq 'unknown'));
			$num_unsafe_unknown++ if(($results_map{$i}{'old_verdict'} eq 'unsafe')
										 and ($results_map{$i}{'new_verdict'} eq 'unknown'));
			$num_unknown_unsafe++ if(($results_map{$i}{'old_verdict'} eq 'unknown')
										 and ($results_map{$i}{'new_verdict'} eq 'unsafe'));
			$num_unknown_safe++ if(($results_map{$i}{'old_verdict'} eq 'unknown')
									   and ($results_map{$i}{'new_verdict'} eq 'safe'));
			$num_ideal_safe_unsafe++ if(($results_map{$i}{'ideal_verdict'} eq 'safe')
											and ($results_map{$i}{'new_verdict'} eq 'unsafe'));
			$num_ideal_safe_safe++ if(($results_map{$i}{'ideal_verdict'} eq 'safe')
										  and ($results_map{$i}{'new_verdict'} eq 'safe'));
			$num_ideal_unsafe_unsafe++ if(($results_map{$i}{'ideal_verdict'} eq 'unsafe')
											  and ($results_map{$i}{'new_verdict'} eq 'unsafe'));
			$num_ideal_safe_unknown++ if(($results_map{$i}{'ideal_verdict'} eq 'safe')
											 and ($results_map{$i}{'new_verdict'} eq 'unknown'));
			$num_ideal_unsafe_safe++ if(($results_map{$i}{'ideal_verdict'} eq 'unsafe')
											and ($results_map{$i}{'new_verdict'} eq 'safe'));
			$num_ideal_unsafe_unknown++ if(($results_map{$i}{'ideal_verdict'} eq 'unsafe')
												and ($results_map{$i}{'new_verdict'} eq 'unknown'));

			print($html_results "\n<tr>
				<td>$cnt</td>
				<td>$results_map{$i}{'rule'}</td>
				<td>$results_map{$i}{'kernel'}</td>
				<td>$results_map{$i}{'commit'}</td>
				<td><small>$results_map{$i}{'driver'}</small></td>
				<td><small>$results_map{$i}{'main'}</small></td>
				<td style=\"color:#");
			if($results_map{$i}{'ideal_verdict'} ne $results_map{$i}{'new_verdict'})
			{
				print($html_results "CD2626");
			}
			else
			{
				print($html_results "191970");
			}
			print($html_results ";background:#9F79EE")
				if(($results_map{$i}{'verdict_type'} == 1)
					and ($results_map{$i}{'ideal_verdict'} eq 'unsafe'));
			print($html_results "\">$results_map{$i}{'ideal_verdict'}->$results_map{$i}{'new_verdict'}</td>
				<td");
			print($html_results " style=\"color:#CD2626\"")
				if($results_map{$i}{'old_verdict'} ne $results_map{$i}{'new_verdict'});
			print($html_results ">$results_map{$i}{'old_verdict'}->$results_map{$i}{'new_verdict'}</td>
				<td><small>$results_map{$i}{'comment'}</small></td>
				<td><small>$results_map{$i}{'problems'}</small></td>\n</tr>\n");
		}
		$num_of_unknown_mains++ if(($results_map{$i}{'main'} eq 'n/a')
										and ($results_map{$i}{'rule'} ne 'n/a'));
		$num_of_undev_rules++ if($results_map{$i}{'rule'} eq 'n/a');
	}
	print($html_results "<\/table>\n<br><br>");
	print($html_results "<hr>\n<a href=\"$link\">Link to visualizer with your results.</a>");
	my $num_of_all_bugs = $num_ideal_unsafe_unsafe + $num_ideal_unsafe_safe + $num_ideal_unsafe_unknown;
	print($html_results "<hr><p style=\"color:#483D8B\"><big>Summary</big></p>\n<table border=\"1\">\n<tr>
		<th style=\"color:#00008B;background:#66CD00\"></th>
		<th style=\"color:#00008B;background:#66CD00\">Ideal->New verdict</th>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">unsafe->unsafe:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_ideal_unsafe_unsafe</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">unsafe->safe:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_ideal_unsafe_safe</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">unsafe->unknown:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_ideal_unsafe_unknown</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">safe->safe:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_ideal_safe_safe</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">safe->unsafe:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_ideal_safe_unsafe</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">safe->unknown:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_ideal_safe_unknown</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">No main</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_of_unknown_mains</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">No rule</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_of_undev_rules</td>\n</tr>\n</table>\n<hr>
		<p style=\"color:#483D8B\"><big>Target bugs</big></p>
		<p>Ldv-tools found $num_of_found_bugs of $num_of_all_bugs bugs;<br>Total number of bugs: $num_of_all_bugs;</p>\n");
	
	print($html_results "<hr><p style=\"color:#483D8B\"><big>Comparison with old verdicts</big></p><br>\n<table border=\"1\">\n<tr>
		<th style=\"color:#00008B;background:#66CD00\"></th>
		<th style=\"color:#00008B;background:#66CD00\">Old->New verdict</th>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">safe->safe:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_safe_safe</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">unsafe->unsafe:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_unsafe_unsafe</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">safe->unsafe:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_safe_unsafe</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">safe->unknown:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_safe_unknown</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">unsafe->safe:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_unsafe_safe</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">unsafe->unknown:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_unsafe_unknown</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">unknown->safe:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_unknown_safe</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">unknown->unsafe:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_unknown_unsafe</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">unknown->unknown:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num_unknown_unknown</td>\n</tr>\n</table>");
	my $cnt2 = 0;
	print($html_results "<hr><p style=\"color:#483D8B\"><big>Modules with unknown mains:</big></p>\n<table border=\"1\">\n<tr>
		<th style=\"background:#00C5CD;color:#191970\">№</th>
		<th style=\"background:#00C5CD;color:#191970\">Rule</th>
		<th style=\"background:#00C5CD;color:#191970\">Kernel</th>
		<th style=\"background:#00C5CD;color:#191970\">Commit</th>
		<th style=\"background:#00C5CD;color:#191970\">Module</th>
		<th style=\"background:#00C5CD;color:#191970\">Ideal verdict</th>
		<th style=\"background:#00C5CD;color:#191970\">Comment</th>\n</tr>");
	for(my $i = 1; $i <= $num_of_tasks; $i++)
	{
		if(($results_map{$i}{'main'} eq 'n/a') and ($results_map{$i}{'rule'} ne 'n/a'))
		{
			$cnt2++;
			print($html_results "<tr>
			<td style=\"background:#87CEFF;color:#551A8B\">$cnt2</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'rule'}</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'kernel'}</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'commit'}</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'driver'}</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'ideal_verdict'}</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'comment'}</td>\n</tr>");
		}
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
	for(my $i = 1; $i <= $num_of_tasks; $i++)
	{
		if($results_map{$i}{'rule'} eq 'n/a')
		{
			$cnt3++;
			print($html_results "<tr>
			<td style=\"background:#FFC1C1;color:#363636\">$cnt3</td>
			<td style=\"background:#FFC1C1;color:#363636\">$results_map{$i}{'kernel'}</td>
			<td style=\"background:#FFC1C1;color:#363636\">$results_map{$i}{'commit'}</td>
			<td style=\"background:#FFC1C1;color:#363636\">$results_map{$i}{'driver'}</td>
			<td style=\"background:#FFC1C1;color:#363636\">$results_map{$i}{'ideal_verdict'}</td>
			<td style=\"background:#FFC1C1;color:#363636\">$results_map{$i}{'comment'}</td>\n</tr>");
		}
	}
	print($html_results "\n</table>\n</body>\n</html>");
	close($html_results);
	print_debug_normal "Report '$report_file' was successfully generated";
}

sub create_double_report($$)
{
	my $file1_txt = shift;
	my $file2_txt = shift;
	my $file_in;
	my $name1 = 'first';
	my $name2 = 'second';
	my $link1;
	my $link2;
	my $tmp_name1;
	print_debug_normal "Report would be generated from two results: '$file1_txt' and '$file2_txt'";
	
	my $num_of_tasks = 0;
	my %results_map;
	print_debug_trace "Reading results..";
	open($file_in, '<', $file1_txt) or die "Couldn't open file '$file1_txt' for read: $ERRNO!";
	while(<$file_in>)
	{
		chomp($_);
		if($_ =~ /^commit=(.*);rule=(.*);kernel=(.*);driver=(.*);main=(.*);verdict=(.*);ideal_verdict=(.*);old_verdict=.*?;#(.*)<@>(.*)$/)
		{
			$num_of_tasks++;
			$results_map{$num_of_tasks} = {
					'commit' => $1,
					'rule' => $2,
					'kernel' => $3,
					'driver' => $4,
					'main' => $5,
					'first_verdict' => $6,
					'second_verdict' => 'n/a',
					'ideal_verdict' => $7,
					'comment' => $8,
					'problems' => $9,
					'verdict_type' => 0
			};
			if($results_map{$num_of_tasks}{'comment'} =~ /^#/)
			{
				$results_map{$num_of_tasks}{'comment'} = $POSTMATCH;
				$results_map{$num_of_tasks}{'verdict_type'} = 1;
			}
			$results_map{$num_of_tasks}{'problems'} = '-'
				if($results_map{$num_of_tasks}{'problems'} eq '');
		}
		elsif($_ =~ /^link_to_results=(.*)/)
		{
			$link1 = $1;
		}
		elsif($_ =~ /^verifier=(.*)/)
		{
			$tmp_name1 = $1;
		}
	}
	close($file_in);
	
	if($num_of_tasks == 0)
	{
		print_debug_warning "Entry file '$file1_txt' hasn't results!\n";
		exit(1);
	}
	open($file_in, '<', $file2_txt) or die "Couldn't open file '$file2_txt' for read: $ERRNO!";
	while(<$file_in>)
	{
		chomp($_);
		if($_ =~ /^commit=(.*);rule=(.*);kernel=(.*);driver=(.*);main=(.*);verdict=(.*);ideal_verdict=(.*);old_verdict=.*?;#(.*)<@>(.*)$/)
		{
			my %tmp_results_map;
			$tmp_results_map{1} = {
					'commit' => $1,
					'rule' => $2,
					'kernel' => $3,
					'driver' => $4,
					'main' => $5,
					'second_verdict' => $6,
					'ideal_verdict' => $7,
					'comment' => $8,
					'problems' => $9,
					'verdict_type' => 0,
					'is_found' => 0
			};
			if($tmp_results_map{1}{'comment'} =~ /^#/)
			{
				$tmp_results_map{1}{'comment'} = $POSTMATCH;
				$tmp_results_map{1}{'verdict_type'} = 1;
			}
			$tmp_results_map{1}{'problems'} = '-'
				if($tmp_results_map{1}{'problems'} eq '');
			foreach my $key (keys %results_map)
			{
				if(($tmp_results_map{1}{'commit'} eq $results_map{$key}{'commit'})
					and ($tmp_results_map{1}{'driver'} eq $results_map{$key}{'driver'})
					and ($tmp_results_map{1}{'main'} eq $results_map{$key}{'main'})
					and ($tmp_results_map{1}{'rule'} eq $results_map{$key}{'rule'})
					and ($tmp_results_map{1}{'kernel'} eq $results_map{$key}{'kernel'}))
				{
					$tmp_results_map{1}{'is_found'} = 1;
					$results_map{$key}{'second_verdict'} = $tmp_results_map{1}{'second_verdict'};
					$results_map{$key}{'problems'} = "$name1: " . $results_map{$key}{'problems'} . "<br>$name2: " . $tmp_results_map{1}{'problems'}
						if(($results_map{$key}{'first_verdict'} eq 'unknown') or ($tmp_results_map{1}{'second_verdict'} eq 'unknown'));
				}
			}
			if($tmp_results_map{1}{'is_found'} == 0)
			{
				print_debug_debug "New task in the second file was found: commit='$tmp_results_map{1}{'commit'}'";
				$num_of_tasks++;
				$results_map{$num_of_tasks} = {
					'commit' => $tmp_results_map{1}{'commit'},
					'rule' => $tmp_results_map{1}{'rule'},
					'kernel' => $tmp_results_map{1}{'kernel'},
					'driver' => $tmp_results_map{1}{'driver'},
					'main' => $tmp_results_map{1}{'main'},
					'first_verdict' => 'n/a',
					'second_verdict' => $tmp_results_map{1}{'second_verdict'},
					'ideal_verdict' => $tmp_results_map{1}{'ideal_verdict'},
					'comment' => $tmp_results_map{1}{'comment'},
					'problems' => $tmp_results_map{1}{'problems'},
					'verdict_type' => $tmp_results_map{1}{'verdict_type'}
				};
			}
		}
		elsif($_ =~ /^link_to_results=(.*)/)
		{
			$link2 = $1;
		}
		elsif($_ =~ /^verifier=(.*)/)
		{
			my $tmp_name2 = $1;
			if($tmp_name2 ne $tmp_name1)
			{
				$name1 = $tmp_name1;
				$name2 = $tmp_name2;
			}
		}
	}
	close($file_in);
	print_debug_trace "Results were read. Number of found tasks: $num_of_tasks";
	print_debug_trace "Starting generation of html report..";
	my $html_results;
	my $num1_safe_safe = 0;
	my $num1_safe_unsafe = 0;
	my $num1_safe_unknown = 0;
	my $num1_unsafe_safe = 0;
	my $num1_unsafe_unsafe = 0;
	my $num1_unsafe_unknown = 0;
	my $num2_safe_safe = 0;
	my $num2_safe_unsafe = 0;
	my $num2_safe_unknown = 0;
	my $num2_unsafe_safe = 0;
	my $num2_unsafe_unsafe = 0;
	my $num2_unsafe_unknown = 0;
	my $num_of_found_bugs = 0;
	my $num_of_unknown_mains = 0;
	my $num_of_undev_rules = 0;
	my $num_of_all_bugs = 0;
	
	open($html_results, '>', $report_file) or die "Couldn't open file '$html_results' for write: $ERRNO!";
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

<h1 align=center style=\"color:#FF4500\"><u>Commit tests double results</u></h1>

<p style=\"color:#483D8B\"><big>Result table:</big></p>

<table border=\"2\">\n<tr>
	<th>№</th>
	<th>Rule</th>
	<th>Kernel</th>
	<th>Commit</th>
	<th>Module</th>
	<th>Main</th>
	<th><small>$name1<br>Ideal->New verdict</small></th>
	<th><small>$name2<br>Ideal->New verdict</small></th>
	<th>Comment</th>
	<th>Problems</th>\n</tr>");
	my $cnt = 0;
	for(my $i = 1; $i <= $num_of_tasks; $i++)
	{
		if(($results_map{$i}{'main'} ne 'n/a')
			and ($results_map{$i}{'rule'} ne 'n/a'))
		{
			$cnt++;
			$num_of_found_bugs++ if((($results_map{$i}{'first_verdict'} eq 'unsafe')
										or ($results_map{$i}{'second_verdict'} eq 'unsafe'))
										and ($results_map{$i}{'verdict_type'} == 0)
										and ($results_map{$i}{'ideal_verdict'} eq 'unsafe'));
			$num_of_all_bugs++ if($results_map{$i}{'ideal_verdict'} eq 'unsafe');
			$num1_safe_unsafe++ if(($results_map{$i}{'ideal_verdict'} eq 'safe')
									  and ($results_map{$i}{'first_verdict'} eq 'unsafe'));
			$num1_safe_unknown++ if(($results_map{$i}{'ideal_verdict'} eq 'safe')
									  and ($results_map{$i}{'first_verdict'} eq 'unknown'));
			$num1_unsafe_safe++ if(($results_map{$i}{'ideal_verdict'} eq 'unsafe')
									  and ($results_map{$i}{'first_verdict'} eq 'safe'));
  			$num1_safe_safe++ if(($results_map{$i}{'ideal_verdict'} eq 'safe')
									and ($results_map{$i}{'first_verdict'} eq 'safe'));
  			$num1_unsafe_unsafe++ if(($results_map{$i}{'ideal_verdict'} eq 'unsafe')
										and ($results_map{$i}{'first_verdict'} eq 'unsafe'));
			$num1_unsafe_unknown++ if(($results_map{$i}{'ideal_verdict'} eq 'unsafe')
										 and ($results_map{$i}{'first_verdict'} eq 'unknown'));
			$num2_safe_unsafe++ if(($results_map{$i}{'ideal_verdict'} eq 'safe')
									  and ($results_map{$i}{'second_verdict'} eq 'unsafe'));
			$num2_safe_unknown++ if(($results_map{$i}{'ideal_verdict'} eq 'safe')
									  and ($results_map{$i}{'second_verdict'} eq 'unknown'));
			$num2_unsafe_safe++ if(($results_map{$i}{'ideal_verdict'} eq 'unsafe')
									  and ($results_map{$i}{'second_verdict'} eq 'safe'));
  			$num2_safe_safe++ if(($results_map{$i}{'ideal_verdict'} eq 'safe')
									and ($results_map{$i}{'second_verdict'} eq 'safe'));
  			$num2_unsafe_unsafe++ if(($results_map{$i}{'ideal_verdict'} eq 'unsafe')
										and ($results_map{$i}{'second_verdict'} eq 'unsafe'));
			$num2_unsafe_unknown++ if(($results_map{$i}{'ideal_verdict'} eq 'unsafe')
										 and ($results_map{$i}{'second_verdict'} eq 'unknown'));

			print($html_results "\n<tr>
				<td>$cnt</td>
				<td>$results_map{$i}{'rule'}</td>
				<td>$results_map{$i}{'kernel'}</td>
				<td>$results_map{$i}{'commit'}</td>
				<td><small>$results_map{$i}{'driver'}</small></td>
				<td><small>$results_map{$i}{'main'}</small></td>
				<td style=\"color:#");
			if($results_map{$i}{'ideal_verdict'} ne $results_map{$i}{'first_verdict'})
			{
				print($html_results "CD2626");
			}
			else
			{
				print($html_results "191970");
			}
			print($html_results ";background:#9F79EE")
				if(($results_map{$i}{'verdict_type'} == 1)
					and ($results_map{$i}{'ideal_verdict'} eq 'unsafe'));
			print($html_results "\">");
			print($html_results "$results_map{$i}{'ideal_verdict'}->$results_map{$i}{'first_verdict'}") if($results_map{$i}{'first_verdict'} ne 'n/a');
			print($html_results "Not found!") if($results_map{$i}{'first_verdict'} eq 'n/a');
			print($html_results "</td>
				<td style=\"color:#");
			if($results_map{$i}{'ideal_verdict'} ne $results_map{$i}{'second_verdict'})
			{
				print($html_results "CD2626");
			}
			else
			{
				print($html_results "191970");
			}
			print($html_results ";background:#9F79EE")
				if(($results_map{$i}{'verdict_type'} == 1)
					and ($results_map{$i}{'ideal_verdict'} eq 'unsafe'));

			print($html_results "\">");
			print($html_results "$results_map{$i}{'ideal_verdict'}->$results_map{$i}{'second_verdict'}") if($results_map{$i}{'second_verdict'} ne 'n/a');
			print($html_results "Not found!") if($results_map{$i}{'second_verdict'} eq 'n/a');
			print($html_results "</td>
				<td><small>$results_map{$i}{'comment'}</small></td>
				<td><small>$results_map{$i}{'problems'}</small></td>\n</tr>\n");
		}
		$num_of_unknown_mains++ if(($results_map{$i}{'main'} eq 'n/a')
										and ($results_map{$i}{'rule'} ne 'n/a'));
		$num_of_undev_rules++ if($results_map{$i}{'rule'} eq 'n/a');
	}
	print($html_results "<\/table>\n<br><br>");
	print($html_results "<hr>\n<a href=\"$link1\">Link to visualizer with your $name1 results.</a><br>\n");
	print($html_results "<a href=\"$link2\">Link to visualizer with your $name2 results.</a>");
	print($html_results "<hr><p style=\"color:#483D8B\"><big>Summary</big></p>\n<table border=\"1\">\n<tr>
		<th style=\"color:#00008B;background:#66CD00\"></th>
		<th style=\"color:#00008B;background:#66CD00\">$name1<br>Ideal->New</th>
		<th style=\"color:#00008B;background:#66CD00\">$name2<br>Ideal->New</th>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">unsafe->unsafe:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num1_unsafe_unsafe</td>
		<td style=\"color:#00008B;background:#CAFF70\">$num2_unsafe_unsafe</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">unsafe->safe:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num1_unsafe_safe</td>
		<td style=\"color:#00008B;background:#CAFF70\">$num2_unsafe_safe</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">unsafe->unknown:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num1_unsafe_unknown</td>
		<td style=\"color:#00008B;background:#CAFF70\">$num2_unsafe_unknown</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">safe->safe:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num1_safe_safe</td>
		<td style=\"color:#00008B;background:#CAFF70\">$num2_safe_safe</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">safe->unsafe:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num1_safe_unsafe</td>
		<td style=\"color:#00008B;background:#CAFF70\">$num2_safe_unsafe</td>\n</tr>\n<tr>
		<th style=\"color:#00008B;background:#66CD00\">safe->unknown:</th>
		<td style=\"color:#00008B;background:#CAFF70\">$num1_safe_unknown</td>
		<td style=\"color:#00008B;background:#CAFF70\">$num2_safe_unknown</td>\n</tr>\n</table>\n<hr>
		<p style=\"color:#483D8B\"><big>Target bugs</big></p>
		<p> Ldv-tools found $num_of_found_bugs of $num_of_all_bugs bugs;<br> Total number of bugs: $num_of_all_bugs;</p>
		<br><p> No main: $num_of_unknown_mains;<br> No rule: $num_of_undev_rules</p><br>");
	my $cnt2 = 0;
	print($html_results "<hr><p style=\"color:#483D8B\"><big>Modules with unknown mains:</big></p>\n<table border=\"1\">\n<tr>
		<th style=\"background:#00C5CD;color:#191970\">№</th>
		<th style=\"background:#00C5CD;color:#191970\">Rule</th>
		<th style=\"background:#00C5CD;color:#191970\">Kernel</th>
		<th style=\"background:#00C5CD;color:#191970\">Commit</th>
		<th style=\"background:#00C5CD;color:#191970\">Module</th>
		<th style=\"background:#00C5CD;color:#191970\">Ideal verdict</th>
		<th style=\"background:#00C5CD;color:#191970\">Comment</th>\n</tr>");
	for(my $i = 1; $i <= $num_of_tasks; $i++)
	{
		if(($results_map{$i}{'main'} eq 'n/a') and ($results_map{$i}{'rule'} ne 'n/a'))
		{
			$cnt2++;
			print($html_results "<tr>
			<td style=\"background:#87CEFF;color:#551A8B\">$cnt2</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'rule'}</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'kernel'}</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'commit'}</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'driver'}</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'ideal_verdict'}</td>
			<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'comment'}</td>\n</tr>");
		}
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
	for(my $i = 1; $i <= $num_of_tasks; $i++)
	{
		if($results_map{$i}{'rule'} eq 'n/a')
		{
			$cnt3++;
			print($html_results "<tr>
			<td style=\"background:#FFC1C1;color:#363636\">$cnt3</td>
			<td style=\"background:#FFC1C1;color:#363636\">$results_map{$i}{'kernel'}</td>
			<td style=\"background:#FFC1C1;color:#363636\">$results_map{$i}{'commit'}</td>
			<td style=\"background:#FFC1C1;color:#363636\">$results_map{$i}{'driver'}</td>
			<td style=\"background:#FFC1C1;color:#363636\">$results_map{$i}{'ideal_verdict'}</td>
			<td style=\"background:#FFC1C1;color:#363636\">$results_map{$i}{'comment'}</td>\n</tr>");
		}
	}
	print($html_results "\n</table>\n</body>\n</html>");
	close($html_results);
	print_debug_normal "Report '$report_file' was successfully generated";
}

sub create_several_report(@)
{
	my @files = @_;
	my $i;
	for($i = 0; $i < $num_of_files; $i++)
	{
		print "file-$i: '$files[$i]';\n";
	}
	print "End of function 'several_report'\n";
	#my $file_in;
	#my $name1 = 'first';
	#my $name2 = 'second';
	#my $link1;
	#my $link2;
	#my $tmp_name1;
	#print_debug_normal "Report would be generated from two results: '$file1_txt' and '$file2_txt'";
	
	#my $num_of_tasks = 0;
	#my %results_map;
	#print_debug_trace "Reading results..";
	#open($file_in, '<', $file1_txt) or die "Couldn't open file '$file1_txt' for read: $ERRNO!";
	#while(<$file_in>)
	#{
		#chomp($_);
		#if($_ =~ /^commit=(.*);rule=(.*);kernel=(.*);driver=(.*);main=(.*);verdict=(.*);ideal_verdict=(.*);old_verdict=.*?;#(.*)<@>(.*)$/)
		#{
			#$num_of_tasks++;
			#$results_map{$num_of_tasks} = {
					#'commit' => $1,
					#'rule' => $2,
					#'kernel' => $3,
					#'driver' => $4,
					#'main' => $5,
					#'first_verdict' => $6,
					#'second_verdict' => 'n/a',
					#'ideal_verdict' => $7,
					#'comment' => $8,
					#'problems' => $9,
					#'verdict_type' => 0
			#};
			#if($results_map{$num_of_tasks}{'comment'} =~ /^#/)
			#{
				#$results_map{$num_of_tasks}{'comment'} = $POSTMATCH;
				#$results_map{$num_of_tasks}{'verdict_type'} = 1;
			#}
			#$results_map{$num_of_tasks}{'problems'} = '-'
				#if($results_map{$num_of_tasks}{'problems'} eq '');
		#}
		#elsif($_ =~ /^link_to_results=(.*)/)
		#{
			#$link1 = $1;
		#}
		#elsif($_ =~ /^verifier=(.*)/)
		#{
			#$tmp_name1 = $1;
		#}
	#}
	#close($file_in);
	
	#if($num_of_tasks == 0)
	#{
		#print_debug_warning "Entry file '$file1_txt' hasn't results!\n";
		#exit(1);
	#}
	#open($file_in, '<', $file2_txt) or die "Couldn't open file '$file2_txt' for read: $ERRNO!";
	#while(<$file_in>)
	#{
		#chomp($_);
		#if($_ =~ /^commit=(.*);rule=(.*);kernel=(.*);driver=(.*);main=(.*);verdict=(.*);ideal_verdict=(.*);old_verdict=.*?;#(.*)<@>(.*)$/)
		#{
			#my %tmp_results_map;
			#$tmp_results_map{1} = {
					#'commit' => $1,
					#'rule' => $2,
					#'kernel' => $3,
					#'driver' => $4,
					#'main' => $5,
					#'second_verdict' => $6,
					#'ideal_verdict' => $7,
					#'comment' => $8,
					#'problems' => $9,
					#'verdict_type' => 0,
					#'is_found' => 0
			#};
			#if($tmp_results_map{1}{'comment'} =~ /^#/)
			#{
				#$tmp_results_map{1}{'comment'} = $POSTMATCH;
				#$tmp_results_map{1}{'verdict_type'} = 1;
			#}
			#$tmp_results_map{1}{'problems'} = '-'
				#if($tmp_results_map{1}{'problems'} eq '');
			#foreach my $key (keys %results_map)
			#{
				#if(($tmp_results_map{1}{'commit'} eq $results_map{$key}{'commit'})
					#and ($tmp_results_map{1}{'driver'} eq $results_map{$key}{'driver'})
					#and ($tmp_results_map{1}{'main'} eq $results_map{$key}{'main'})
					#and ($tmp_results_map{1}{'rule'} eq $results_map{$key}{'rule'})
					#and ($tmp_results_map{1}{'kernel'} eq $results_map{$key}{'kernel'}))
				#{
					#$tmp_results_map{1}{'is_found'} = 1;
					#$results_map{$key}{'second_verdict'} = $tmp_results_map{1}{'second_verdict'};
					#$results_map{$key}{'problems'} = "$name1: " . $results_map{$key}{'problems'} . "<br>$name2: " . $tmp_results_map{1}{'problems'}
						#if(($results_map{$key}{'first_verdict'} eq 'unknown') or ($tmp_results_map{1}{'second_verdict'} eq 'unknown'));
				#}
			#}
			#if($tmp_results_map{1}{'is_found'} == 0)
			#{
				#print_debug_debug "New task in the second file was found: commit='$tmp_results_map{1}{'commit'}'";
				#$num_of_tasks++;
				#$results_map{$num_of_tasks} = {
					#'commit' => $tmp_results_map{1}{'commit'},
					#'rule' => $tmp_results_map{1}{'rule'},
					#'kernel' => $tmp_results_map{1}{'kernel'},
					#'driver' => $tmp_results_map{1}{'driver'},
					#'main' => $tmp_results_map{1}{'main'},
					#'first_verdict' => 'n/a',
					#'second_verdict' => $tmp_results_map{1}{'second_verdict'},
					#'ideal_verdict' => $tmp_results_map{1}{'ideal_verdict'},
					#'comment' => $tmp_results_map{1}{'comment'},
					#'problems' => $tmp_results_map{1}{'problems'},
					#'verdict_type' => $tmp_results_map{1}{'verdict_type'}
				#};
			#}
		#}
		#elsif($_ =~ /^link_to_results=(.*)/)
		#{
			#$link2 = $1;
		#}
		#elsif($_ =~ /^verifier=(.*)/)
		#{
			#my $tmp_name2 = $1;
			#if($tmp_name2 ne $tmp_name1)
			#{
				#$name1 = $tmp_name1;
				#$name2 = $tmp_name2;
			#}
		#}
	#}
	#close($file_in);
	#print_debug_trace "Results were read. Number of found tasks: $num_of_tasks";
	#print_debug_trace "Starting generation of html report..";
	#my $html_results;
	#my $num1_safe_safe = 0;
	#my $num1_safe_unsafe = 0;
	#my $num1_safe_unknown = 0;
	#my $num1_unsafe_safe = 0;
	#my $num1_unsafe_unsafe = 0;
	#my $num1_unsafe_unknown = 0;
	#my $num2_safe_safe = 0;
	#my $num2_safe_unsafe = 0;
	#my $num2_safe_unknown = 0;
	#my $num2_unsafe_safe = 0;
	#my $num2_unsafe_unsafe = 0;
	#my $num2_unsafe_unknown = 0;
	#my $num_of_found_bugs = 0;
	#my $num_of_unknown_mains = 0;
	#my $num_of_undev_rules = 0;
	#my $num_of_all_bugs = 0;
	
	#open($html_results, '>', $report_file) or die "Couldn't open file '$html_results' for write: $ERRNO!";
	#print($html_results "<!DOCTYPE html>
#<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">\n<html>
	#<head>
		#<style type=\"text\/css\">
		#body {background-color:#FFEBCD}
		#p {color:#2F4F4F}
		#th {color:#FFA500}
		#td {background:#98FB98}
		#td {color:#191970}
		#th {background:#3CB371}
		#</style>
	#</head>
#<body>

#<h1 align=center style=\"color:#FF4500\"><u>Commit tests double results</u></h1>

#<p style=\"color:#483D8B\"><big>Result table:</big></p>

#<table border=\"2\">\n<tr>
	#<th>№</th>
	#<th>Rule</th>
	#<th>Kernel</th>
	#<th>Commit</th>
	#<th>Module</th>
	#<th>Main</th>
	#<th><small>$name1<br>Ideal->New verdict</small></th>
	#<th><small>$name2<br>Ideal->New verdict</small></th>
	#<th>Comment</th>
	#<th>Problems</th>\n</tr>");
	#my $cnt = 0;
	#for(my $i = 1; $i <= $num_of_tasks; $i++)
	#{
		#if(($results_map{$i}{'main'} ne 'n/a')
			#and ($results_map{$i}{'rule'} ne 'n/a'))
		#{
			#$cnt++;
			#$num_of_found_bugs++ if((($results_map{$i}{'first_verdict'} eq 'unsafe')
										#or ($results_map{$i}{'second_verdict'} eq 'unsafe'))
										#and ($results_map{$i}{'verdict_type'} == 0)
										#and ($results_map{$i}{'ideal_verdict'} eq 'unsafe'));
			#$num_of_all_bugs++ if($results_map{$i}{'ideal_verdict'} eq 'unsafe');
			#$num1_safe_unsafe++ if(($results_map{$i}{'ideal_verdict'} eq 'safe')
									  #and ($results_map{$i}{'first_verdict'} eq 'unsafe'));
			#$num1_safe_unknown++ if(($results_map{$i}{'ideal_verdict'} eq 'safe')
									  #and ($results_map{$i}{'first_verdict'} eq 'unknown'));
			#$num1_unsafe_safe++ if(($results_map{$i}{'ideal_verdict'} eq 'unsafe')
									  #and ($results_map{$i}{'first_verdict'} eq 'safe'));
  			#$num1_safe_safe++ if(($results_map{$i}{'ideal_verdict'} eq 'safe')
									#and ($results_map{$i}{'first_verdict'} eq 'safe'));
  			#$num1_unsafe_unsafe++ if(($results_map{$i}{'ideal_verdict'} eq 'unsafe')
										#and ($results_map{$i}{'first_verdict'} eq 'unsafe'));
			#$num1_unsafe_unknown++ if(($results_map{$i}{'ideal_verdict'} eq 'unsafe')
										 #and ($results_map{$i}{'first_verdict'} eq 'unknown'));
			#$num2_safe_unsafe++ if(($results_map{$i}{'ideal_verdict'} eq 'safe')
									  #and ($results_map{$i}{'second_verdict'} eq 'unsafe'));
			#$num2_safe_unknown++ if(($results_map{$i}{'ideal_verdict'} eq 'safe')
									  #and ($results_map{$i}{'second_verdict'} eq 'unknown'));
			#$num2_unsafe_safe++ if(($results_map{$i}{'ideal_verdict'} eq 'unsafe')
									  #and ($results_map{$i}{'second_verdict'} eq 'safe'));
  			#$num2_safe_safe++ if(($results_map{$i}{'ideal_verdict'} eq 'safe')
									#and ($results_map{$i}{'second_verdict'} eq 'safe'));
  			#$num2_unsafe_unsafe++ if(($results_map{$i}{'ideal_verdict'} eq 'unsafe')
										#and ($results_map{$i}{'second_verdict'} eq 'unsafe'));
			#$num2_unsafe_unknown++ if(($results_map{$i}{'ideal_verdict'} eq 'unsafe')
										 #and ($results_map{$i}{'second_verdict'} eq 'unknown'));

			#print($html_results "\n<tr>
				#<td>$cnt</td>
				#<td>$results_map{$i}{'rule'}</td>
				#<td>$results_map{$i}{'kernel'}</td>
				#<td>$results_map{$i}{'commit'}</td>
				#<td><small>$results_map{$i}{'driver'}</small></td>
				#<td><small>$results_map{$i}{'main'}</small></td>
				#<td style=\"color:#");
			#if($results_map{$i}{'ideal_verdict'} ne $results_map{$i}{'first_verdict'})
			#{
				#print($html_results "CD2626");
			#}
			#else
			#{
				#print($html_results "191970");
			#}
			#print($html_results ";background:#9F79EE")
				#if(($results_map{$i}{'verdict_type'} == 1)
					#and ($results_map{$i}{'ideal_verdict'} eq 'unsafe'));
			#print($html_results "\">");
			#print($html_results "$results_map{$i}{'ideal_verdict'}->$results_map{$i}{'first_verdict'}") if($results_map{$i}{'first_verdict'} ne 'n/a');
			#print($html_results "Not found!") if($results_map{$i}{'first_verdict'} eq 'n/a');
			#print($html_results "</td>
				#<td style=\"color:#");
			#if($results_map{$i}{'ideal_verdict'} ne $results_map{$i}{'second_verdict'})
			#{
				#print($html_results "CD2626");
			#}
			#else
			#{
				#print($html_results "191970");
			#}
			#print($html_results ";background:#9F79EE")
				#if(($results_map{$i}{'verdict_type'} == 1)
					#and ($results_map{$i}{'ideal_verdict'} eq 'unsafe'));

			#print($html_results "\">");
			#print($html_results "$results_map{$i}{'ideal_verdict'}->$results_map{$i}{'second_verdict'}") if($results_map{$i}{'second_verdict'} ne 'n/a');
			#print($html_results "Not found!") if($results_map{$i}{'second_verdict'} eq 'n/a');
			#print($html_results "</td>
				#<td><small>$results_map{$i}{'comment'}</small></td>
				#<td><small>$results_map{$i}{'problems'}</small></td>\n</tr>\n");
		#}
		#$num_of_unknown_mains++ if(($results_map{$i}{'main'} eq 'n/a')
										#and ($results_map{$i}{'rule'} ne 'n/a'));
		#$num_of_undev_rules++ if($results_map{$i}{'rule'} eq 'n/a');
	#}
	#print($html_results "<\/table>\n<br><br>");
	#print($html_results "<hr>\n<a href=\"$link1\">Link to visualizer with your $name1 results.</a><br>\n");
	#print($html_results "<a href=\"$link2\">Link to visualizer with your $name2 results.</a>");
	#print($html_results "<hr><p style=\"color:#483D8B\"><big>Summary</big></p>\n<table border=\"1\">\n<tr>
		#<th style=\"color:#00008B;background:#66CD00\"></th>
		#<th style=\"color:#00008B;background:#66CD00\">$name1<br>Ideal->New</th>
		#<th style=\"color:#00008B;background:#66CD00\">$name2<br>Ideal->New</th>\n</tr>\n<tr>
		#<th style=\"color:#00008B;background:#66CD00\">unsafe->unsafe:</th>
		#<td style=\"color:#00008B;background:#CAFF70\">$num1_unsafe_unsafe</td>
		#<td style=\"color:#00008B;background:#CAFF70\">$num2_unsafe_unsafe</td>\n</tr>\n<tr>
		#<th style=\"color:#00008B;background:#66CD00\">unsafe->safe:</th>
		#<td style=\"color:#00008B;background:#CAFF70\">$num1_unsafe_safe</td>
		#<td style=\"color:#00008B;background:#CAFF70\">$num2_unsafe_safe</td>\n</tr>\n<tr>
		#<th style=\"color:#00008B;background:#66CD00\">unsafe->unknown:</th>
		#<td style=\"color:#00008B;background:#CAFF70\">$num1_unsafe_unknown</td>
		#<td style=\"color:#00008B;background:#CAFF70\">$num2_unsafe_unknown</td>\n</tr>\n<tr>
		#<th style=\"color:#00008B;background:#66CD00\">safe->safe:</th>
		#<td style=\"color:#00008B;background:#CAFF70\">$num1_safe_safe</td>
		#<td style=\"color:#00008B;background:#CAFF70\">$num2_safe_safe</td>\n</tr>\n<tr>
		#<th style=\"color:#00008B;background:#66CD00\">safe->unsafe:</th>
		#<td style=\"color:#00008B;background:#CAFF70\">$num1_safe_unsafe</td>
		#<td style=\"color:#00008B;background:#CAFF70\">$num2_safe_unsafe</td>\n</tr>\n<tr>
		#<th style=\"color:#00008B;background:#66CD00\">safe->unknown:</th>
		#<td style=\"color:#00008B;background:#CAFF70\">$num1_safe_unknown</td>
		#<td style=\"color:#00008B;background:#CAFF70\">$num2_safe_unknown</td>\n</tr>\n</table>\n<hr>
		#<p style=\"color:#483D8B\"><big>Target bugs</big></p>
		#<p> Ldv-tools found $num_of_found_bugs of $num_of_all_bugs bugs;<br> Total number of bugs: $num_of_all_bugs;</p>
		#<br><p> No main: $num_of_unknown_mains;<br> No rule: $num_of_undev_rules</p><br>");
	#my $cnt2 = 0;
	#print($html_results "<hr><p style=\"color:#483D8B\"><big>Modules with unknown mains:</big></p>\n<table border=\"1\">\n<tr>
		#<th style=\"background:#00C5CD;color:#191970\">№</th>
		#<th style=\"background:#00C5CD;color:#191970\">Rule</th>
		#<th style=\"background:#00C5CD;color:#191970\">Kernel</th>
		#<th style=\"background:#00C5CD;color:#191970\">Commit</th>
		#<th style=\"background:#00C5CD;color:#191970\">Module</th>
		#<th style=\"background:#00C5CD;color:#191970\">Ideal verdict</th>
		#<th style=\"background:#00C5CD;color:#191970\">Comment</th>\n</tr>");
	#for(my $i = 1; $i <= $num_of_tasks; $i++)
	#{
		#if(($results_map{$i}{'main'} eq 'n/a') and ($results_map{$i}{'rule'} ne 'n/a'))
		#{
			#$cnt2++;
			#print($html_results "<tr>
			#<td style=\"background:#87CEFF;color:#551A8B\">$cnt2</td>
			#<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'rule'}</td>
			#<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'kernel'}</td>
			#<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'commit'}</td>
			#<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'driver'}</td>
			#<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'ideal_verdict'}</td>
			#<td style=\"background:#87CEFF;color:#551A8B\">$results_map{$i}{'comment'}</td>\n</tr>");
		#}
	#}
	#print($html_results "</table>\n<br>");
	#my $cnt3 = 0;
	#print($html_results "<hr><p style=\"color:#483D8B\"><big>Undeveloped rules:</big></p><table border=\"1\">\n<tr>
			#<th style=\"background:#CD5555;color:#363636\">№</th>
			#<th style=\"background:#CD5555;color:#363636\">Kernel</th>
			#<th style=\"background:#CD5555;color:#363636\">Commit</th>
			#<th style=\"background:#CD5555;color:#363636\">Module</th>
			#<th style=\"background:#CD5555;color:#363636\">Ideal verdict</th>
			#<th style=\"background:#CD5555;color:#363636\">Comment</th>
			#</tr>");
	#for(my $i = 1; $i <= $num_of_tasks; $i++)
	#{
		#if($results_map{$i}{'rule'} eq 'n/a')
		#{
			#$cnt3++;
			#print($html_results "<tr>
			#<td style=\"background:#FFC1C1;color:#363636\">$cnt3</td>
			#<td style=\"background:#FFC1C1;color:#363636\">$results_map{$i}{'kernel'}</td>
			#<td style=\"background:#FFC1C1;color:#363636\">$results_map{$i}{'commit'}</td>
			#<td style=\"background:#FFC1C1;color:#363636\">$results_map{$i}{'driver'}</td>
			#<td style=\"background:#FFC1C1;color:#363636\">$results_map{$i}{'ideal_verdict'}</td>
			#<td style=\"background:#FFC1C1;color:#363636\">$results_map{$i}{'comment'}</td>\n</tr>");
		#}
	#}
	#print($html_results "\n</table>\n</body>\n</html>");
	#close($html_results);
	#print_debug_normal "Report '$report_file' was successfully generated";
}
