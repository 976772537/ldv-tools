#! /usr/bin/perl -w

use strict;
use English;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use Cwd qw(abs_path cwd);
use File::Copy qw(copy);

my $files;
my $tmp_file = "cross_tempfile.o.i";
warn("Incorrect options!") unless (GetOptions('files|f=s' => \$files));
my $working_dir = Cwd::cwd() or die("Can't obtain current directory!");
$tmp_file = "$working_dir/$tmp_file";
my @all_files = split(' ', $files);
print "TEST: all files: '@all_files'\n";
foreach my $file(@all_files)
{
	open(INFILE, '<', $file) or die "Error1";
	open(TMPFILE, '>', $tmp_file) or die "Error2";
	while(<INFILE>)
	{
		if($_ =~ /^typedef __va_list __gnuc_va_list;/)
		{
			print(TMPFILE "typedef __builtin_va_list __gnuc_va_list;\n");
		}
		else
		{
		print(TMPFILE $_);
		}
	}
	close(TMPFILE);
	close(INFILE);
	copy($tmp_file, $file);
}

unlink($tmp_file);
