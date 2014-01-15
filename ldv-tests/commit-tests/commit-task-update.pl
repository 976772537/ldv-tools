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
sub get_opt();
sub check_dirs();
sub read_all_tasks();
sub generate_all_tasks();
#######################################################################
# Global variables
#######################################################################
# Name of this tool
my $debug_name = 'commit-tester';
my $tasks_dir = "$FindBin::RealBin";

my $tool_workdir = 'commit-test-updater';
my $all_tasks = "$tasks_dir/all-tasks.cfg";
my $all_tasks_newdeg = "$tasks_dir/all-tasks-newdeg.cfg";
my $new_alltasks = '(new)all-tasks.cfg';
my $all_tasks_diff = 'all-tasks.diff';
my $all_tasks_newdeg_diff = 'all-tasks-newdeg.diff';
my $new_tasks = 'new-tasks.cfg';
my $opt_new_tasks;
#######################################################################
# Main section
#######################################################################
get_opt();
check_dirs();
read_all_tasks();
generate_all_tasks();
#######################################################################
# Subroutines.
#######################################################################
sub get_opt()
{
	unless (GetOptions(
		'newtasks|n=s' => \$opt_new_tasks
	{
		warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
		help();
	}
	die "You should specify --newtasks|-n <file>!" unless($opt_new_tasks);
	die "Couldn't find file '$opt_new_tasks'" unless(-f $opt_new_tasks);
}

sub check_dirs()
{
	my $current_working_dir = Cwd::cwd() or die("Can't obtain current directory!");
	die "You should delete directory '$tool_workdir' before starting!"
		if (-d "$current_working_dir/$tool_workdir");
	$tool_workdir = "$current_working_dir/$tool_workdir";
	mkpath($tool_workdir) or die "COuldn't create directory '$tool_workdir': $ERRNO";
	die("Couldn't find needed tasks files at '$tasks_dir'!")
		unless((-f $all_tasks) and (-f $all_tasks_newdeg));
	$all_tasks_diff = "$tool_workdir/$all_tasks_diff";
	$all_tasks_newdeg_diff = "$tool_workdir/$all_tasks_newdeg_diff";
	$new_tasks = "$tool_workdir/$new_tasks";
	copy($opt_new_tasks, $new_tasks)
		or die "Couldn't copy file '$opt_new_tasks' to '$new_tasks': $ERRNO";
}

sub read_all_tasks($)
{
	my $file_to_read = shift;
	open(MYFILE, '<', $file_to_read)
		or die "Couldn't open file '$file_to_read' for read: $ERRNO";
	while(<MYFILE>)
	{
		chomp($_);
		if($_ =~ /^repository=(.*)$/)
		{
		}
	}
	close(MYFILE);
}
