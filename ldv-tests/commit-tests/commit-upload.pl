#! /usr/bin/perl -w

use English;
use strict;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use Env qw(LDV_DEBUG LDV_COMMIT_TEST_UPLOADER_DEBUG LDVDBCTEST LDVDBHOSTCTEST LDVUSERCTEST LDVDBPASSWDCTEST);
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

# Obtain needed files and dirs and check their presence.
# args: no.
# retn: nothing.
sub prepare_files_and_dirs();

# Clear database befor uploading and call upload_right_results()
# for all pax archives.
# args: no.
# retn: nothing.
sub run_ldv_upload();

# Run ldv-upload for one pax archive that is single in dir 'task-*--dir'.
sub upload_right_results($);
#######################################################################
# Global variables
#######################################################################

# Name of this tool
my $debug_name = 'commit-uploader';

# Path to the binary that tells a path to sql script that contains cleaning and
# creating of the test database. It must be found in the PATH.
my $ldv_path_to_results_sql_bin = "path-to-results-schema-sql";

# The system mysql binary.
my $mysql_bin = 'mysql';

# Directory with archives
my $opt_result_dir;

# Number of found archives
my $num_of_task_dirs = 0;

# The sql script that contains cleaning and creating of the test database.
my $ldv_results_sql;

# Tasks for ldv-upload
my %uptask_map;

# Path to the binary of the ldv-upload. It must be found in the PATH.
my $ldv_uploader_bin = "ldv-upload";

# Environments variables that specify the database connection for the ldv-upload.
my $ldv_uploader_host = 'LDVDBHOST';
my $ldv_uploader_database = 'LDVDB';
my $ldv_uploader_user = 'LDVUSER';
my $ldv_uploader_password = 'LDVDBPASSWD';
#######################################################################
# Main section
#######################################################################
get_debug_level($debug_name, $LDV_DEBUG, $LDV_COMMIT_TEST_UPLOADER_DEBUG);
print_debug_normal("Process the command-line options");
get_test_opt();
print_debug_normal("Check presence of needed files, executables and directories. Copy needed files and directories");
prepare_files_and_dirs();
print_debug_normal("Upload the launcher results to the database");
run_ldv_upload();
#######################################################################
# Subroutines
#######################################################################
sub get_test_opt()
{
	my $opt_help;
	unless (GetOptions(
		'results=s' => \$opt_result_dir,
		'help' => \$opt_help))
	{
		warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
	}
	help() if ($opt_help);
	print_debug_debug("The command-line options in uploader script are processed successfully");
}
sub help()
{
	print(STDERR << "EOM");
NAME
	$PROGRAM_NAME: The programm uploads pax results to specified database.
SYNOPSIS
	[DATABASE SET] $PROGRAM_NAME [option...]
OPTIONS
	--results=<dir>
	   <dir> is a directory where are results.
	   You should always use this option.
	   This program uploads only pax archives from <dir> where
	   are directories that have format 'task-<num>--<commit>--dir'.
	   Each directory should have only one pax archive.
	-h, --help
	   Print this help and exit with a error.
DATABASE SET
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

EOM
	exit(1);
}

sub prepare_files_and_dirs()
{
	unless ($LDVDBCTEST and $LDVUSERCTEST)
	{
		print_debug_warning("You don't setup connection to your testing database. See --help for details");
		help();
	}
	unless (-d "$opt_result_dir")
	{
		print_debug_warning("Results directory wasn't found!");
		exit(1);
	}

	foreach my $dir (<$opt_result_dir/*>)
	{
		if (-d $dir and $dir =~ /.*task-\d+--.*--dir/)
		{
			$num_of_task_dirs++;
			my $i = 0;
			foreach my $file (<$dir/*.pax>)
			{
				$i++;
				$uptask_map{$num_of_task_dirs} = {
					'isgood' => 'yes'
				};
				$uptask_map{$num_of_task_dirs} {'file'} = $file if(-f $file);
			}
			if($i == 0)
			{
				print_debug_warning("There is no pax archives in '$dir'");
				$uptask_map{$num_of_task_dirs} {'isgood'} = 'no';
			}
			elsif($i > 1)
			{
				print_debug_warning("There is too many pax archives in '$dir'!");
				$uptask_map{$num_of_task_dirs} {'isgood'} = 'no';
			}
		}
		else
		{
			print_debug_warning("There is incorrect directory in results: $dir");
		}
	}
	my @lines = `$ldv_path_to_results_sql_bin`;
	die("There is no the script that says the path to results schema sql executable in your PATH!")
		if (check_system_call() == -1);
	die("The script that says the path to results schema sql returns '" . ($CHILD_ERROR >> 8) . "'")
		if ($CHILD_ERROR >> 8);
	die("The script doesn't say the path to results schema sql in the first line")
		unless (defined($lines[0]));
	chomp($lines[0]);
	$ldv_results_sql = $lines[0];
	print_debug_debug("The results schema sql scipt is '$ldv_results_sql'");
}

sub run_ldv_upload()
{
	print_debug_normal("Setup the test database");
	my $cmd = "$mysql_bin --user=$LDVUSERCTEST $LDVDBCTEST";
	$cmd .= " --host=$LDVDBHOSTCTEST" if ($LDVDBHOSTCTEST);
	$cmd .= " --password=$LDVDBPASSWDCTEST" if ($LDVDBPASSWDCTEST);
	$cmd .= " < $ldv_results_sql";
	`$cmd`;
	die("There is no the mysql executable in your PATH!")
		if (check_system_call() == -1);
	die("The mysql returns '" . ($CHILD_ERROR >> 8) . "'")
		if ($CHILD_ERROR >> 8);
	# I used this cycle to upload pax archives in right order
	my $i = 1;
	while($i <= $num_of_task_dirs)
	{
			upload_right_results($uptask_map{$i}{'file'})
				if($uptask_map{$i}{'isgood'} eq 'yes');
		$i++;
	}
	print_debug_normal("Uploader successfully finished");
}

sub upload_right_results($)
{
	my $file = shift;
	print_debug_normal("Begin to upload the result '$file'");
	
	$ENV{$ldv_uploader_database} = $LDVDBCTEST;
	$ENV{$ldv_uploader_user} = $LDVUSERCTEST;
	print_debug_debug("The database '$LDVDBCTEST' and the user '$LDVUSERCTEST' is setup for the ldv-upload");
	if ($LDVDBHOSTCTEST)
	{
		$ENV{$ldv_uploader_host} = $LDVDBHOSTCTEST;
		print_debug_debug("The host '$LDVDBHOSTCTEST' is setup for the ldv-upload");
	}
	
	if ($LDVDBPASSWDCTEST)
	{
		$ENV{$ldv_uploader_password} = $LDVDBPASSWDCTEST;
		print_debug_debug("The password '$LDVDBPASSWDCTEST' is setup for the ldv-upload");
	}
	my @upload_command = ($ldv_uploader_bin, "$file");
	print_debug_debug("Execute the command '@upload_command'");
	system(@upload_command);
	die("There is no the ldv-upload executable in your PATH!")
		if (check_system_call() == -1);
	delete($ENV{$ldv_uploader_database});
	delete($ENV{$ldv_uploader_user});
	delete($ENV{$ldv_uploader_host});
	delete($ENV{$ldv_uploader_password});
	print_debug_trace("'$file' was seccussfully uploaded");
}
