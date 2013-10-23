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

my $ct_result;
my $comment;
my $xml_out = "cpachecker-report_commit-tester.xml";
unless (GetOptions('file|f=s' => \$ct_result,'out|o=s' => \$xml_out, 'comment|c=s' => \$comment))
{
	warn("Incorrect options!");
	exit(1);
}
die "Couldn't find file $ct_result! Set it in option --file" unless(-f $ct_result);
$ct_result = abs_path($ct_result);
my $memlimit;
my $timelimit;
my $verifier;
my $date_time;
open(CT_FILE, '<', $ct_result) or die "Couldn't open file '$ct_result' for read: $ERRNO";
while(<CT_FILE>)
{
	chomp($_);
	if($_ =~ /name_of_runtask=(.*);<br>timelimit=(.*);<br>memlimit=(.*?);<br>(.*?)<br>/)
	{
		$memlimit = $3;
		$timelimit = $2;
		$verifier = $1;
		$date_time = $4;
		last;
	}
}
close(CT_FILE);
$verifier .= "-$comment" if(defined($comment));
$comment = 'Commit tester' unless($comment);
open(MYFILE, '>', $xml_out) or die "Couldn't open file '$xml_out' for write: $ERRNO";
print(MYFILE "<?xml version=\"1.0\" ?>
<result benchmarkname=\"$comment\" date=\"$date_time\" memlimit=\"$memlimit\" options=\"\" timelimit=\"$timelimit\" tool=\"$verifier\" version=\"\">
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

open(CT_FILE, '<', $ct_result) or die "Couldn't open file '$ct_result' for read: $ERRNO";
while(<CT_FILE>)
{
	chomp($_);
	if($_ =~ /^commit=(.*);memory=(.*);time=(.*);rule=(.*);kernel=.*;driver=(.*);main=(.*);verdict=(.*);ideal_verdict=(\w+);/)
	{
		my $commit = $1;
		my $memory = $2;
		my $time = $3;
		my $rule = $4;
		my $main = $6;
		my $driver = $5;
		my $verdict = $7;
		my $ideal = $8;
		$verdict = 'UNKNOWN' if($verdict eq 'unknown');
		$verdict = 'SAFE' if($verdict eq 'safe');
		$verdict = 'UNSAFE' if($verdict eq 'unsafe');
		if($main ne 'n/a' and $rule ne 'n/a')
		{
			print(MYFILE "<sourcefile name=\"commit=$commit;rule=$rule;$driver;main=$main;ideal_$ideal\" options=\"-\">
							<column title=\"status\" value=\"$verdict\"/>
							<column title=\"Time\" value=\"$time\"/>
							<column title=\"Memory\" value=\"$memory\"/>
						   </sourcefile>");
		}
	}
}
close(CT_FILE);
print(MYFILE "</result>");
close(MYFILE);
print "Report '$xml_out' was successfully written!\n";
