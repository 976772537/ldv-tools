#! /usr/bin/perl -w

use English;
use strict;
use Switch;

use Cwd qw(cwd abs_path);
use File::Path qw(mkpath rmtree);
use File::Copy qw(copy);

use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use FindBin;

my $current_dir = Cwd::cwd() or die("Can't obtain current directory!");

my $ct_result = "$current_dir/commit-tester-results.txt";
open(MYFILE, '>', "cpachecker-report_commit-tester.xml") or die "ERROR 0.";
print(MYFILE "<?xml version=\"1.0\" ?>
<result benchmarkname=\"predicateAnalysis_simple\" date=\"");
my ($local_time_min, $local_time_hour, $local_time_day, $local_time_mon, $local_time_year) = (localtime)[1,2,3,4,5];
printf(MYFILE "%02d.%02d.%04d %02d:%02d", $local_time_day, $local_time_mon,
	$local_time_year + 1900, $local_time_hour, $local_time_min);
my $memlimit = '1Gb';
my $timelimit = '900';
my $verifier = 'BLAST';
$memlimit = $ENV{'RCV_MEMLIMIT'} if(defined($ENV{'RCV_MEMLIMIT'}));
$timelimit = $ENV{'RCV_TIMELIMIT'} if(defined($ENV{'RCV_TIMELIMIT'}));
$verifier = $ENV{'RCV_VERIFIER'} if(defined($ENV{'RCV_VERIFIER'}));
print(MYFILE "\" memlimit=\"$memlimit\" options=\"-\" timelimit=\"$timelimit\" tool=\"$verifier\" version=\"--\">
  <systeminfo hostname=\"hb\">
    <os name=\"linux-stable\"/>
    <cpu cores=\"x\" frequency=\"y\" model=\"Unknown\"/>
    <ram size=\"16Gb\"/>
  </systeminfo>
  <columns>
    <column title=\"status\"/>
    <column title=\"time\"/>
    <column title=\"memory\"/>
  </columns>");

open(CT_FILE, '<', $ct_result) or die "ERROR 1.";
while(<CT_FILE>)
{
	chomp($_);
	if($_ =~ /^commit=(.*);memory=(.*);time=(.*);rule=(.*);kernel=.*;driver=(.*);main=(.*);verdict=(\w+);/)
	{
		my $commit = $1;
		my $memory = $2;
		my $time = $3;
		my $rule = $4;
		my $main = $6;
		my $driver = $5;
		my $verdict = $7;
		$verdict = 'UNKNOWN' if($verdict eq 'unknown');
		$verdict = 'SAFE' if($verdict eq 'safe');
		$verdict = 'UNSAFE' if($verdict eq 'unsafe');
		if($main ne 'n/a' and $rule ne 'n/a')
		{
			print(MYFILE "<sourcefile name=\"commit=$commit;rule=$rule;$driver;\" options=\"-\">
							<column title=\"status\" value=\"$verdict\"/>
							<column title=\"time\" value=\"$time\"/>
							<column title=\"memory\" value=\"$memory\"/>
						   </sourcefile>");
		}
	}
}
close(CT_FILE);
print(MYFILE "</result>");
close(MYFILE);
