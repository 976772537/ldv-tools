#! /usr/bin/perl -w

use warnings;
use English qw( -no_match_vars );
use Carp;
use Readonly;
use strict;
use Getopt::Long qw(GetOptions);
use IPC::Open3 'open3';
Getopt::Long::Configure qw(posix_default no_ignore_case);
use Env
  qw(LDV_DEBUG LDV_COMMIT_TEST_UPLOADER_DEBUG LDVDBCTEST LDVDBHOSTCTEST LDVUSERCTEST LDVDBPASSWDCTEST);
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
sub get_test_opt;

# Print help message on the screen and exit.
# args: no.
# retn: nothing.
sub help;

# Obtain needed files and dirs and check their presence.
# args: no.
# retn: nothing.
sub prepare_files_and_dirs;

# Clear database befor uploading and call upload_right_results()
# for all pax archives.
# args: no.
# retn: nothing.
sub run_ldv_upload;

# Run ldv-upload for one pax archive that is single in dir 'task-*--dir'.
sub upload_right_results;
#######################################################################
# Global variables
#######################################################################

Readonly my $EIGHT      => 8;
Readonly my $ERROR_CODE => -1;

# Name of this tool
my $debug_name = 'commit-uploader';

# Path to the binary that tells a path to sql script that contains cleaning and
# creating of the test database. It must be found in the PATH.
my $ldv_path_to_results_sql_bin = 'path-to-results-schema-sql';

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
my $ldv_uploader_bin = 'ldv-upload';

# Environments variables that specify the database connection for the ldv-upload.
my $ldv_uploader_host     = 'LDVDBHOST';
my $ldv_uploader_database = 'LDVDB';
my $ldv_uploader_user     = 'LDVUSER';
my $ldv_uploader_password = 'LDVDBPASSWD';
#######################################################################
# Main section
#######################################################################
get_debug_level( $debug_name, $LDV_DEBUG, $LDV_COMMIT_TEST_UPLOADER_DEBUG );
print_debug_normal('Process the command-line options');
get_test_opt();
print_debug_normal(
'Check presence of needed files, executables and directories. Copy needed files and directories'
);
prepare_files_and_dirs();
print_debug_normal('Upload the launcher results to the database');
run_ldv_upload();
#######################################################################
# Subroutines
#######################################################################
sub get_test_opt {
    my $opt_help;
    if (
        !GetOptions(
            'results=s' => \$opt_result_dir,
            'help'      => \$opt_help
        )
      )
    {
        carp 'Incorrect options! Run script with --help option.';
    }
    if ($opt_help) {
        help();
    }
    print_debug_debug 'The command-line options are processed successfully';
    return;
}

sub help {
    print << "EOM" or croak "Couldn't print to 'STDOUT': $ERRNO";
NAME
	$PROGRAM_NAME: The program uploads pax results to the specified database.
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
	   Print this help and exit with error.
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
    exit 1;
}

sub prepare_files_and_dirs {
    if ( not $LDVDBCTEST or not $LDVUSERCTEST ) {
        print_debug_warning(
'You don\'t setup connection to your testing database. See --help for details'
        );
        help();
    }
    if ( not -d $opt_result_dir ) {
        print_debug_warning 'Results directory wasn\'t found!';
        exit 1;
    }
    my $dir_pattern = "$opt_result_dir/*";
    foreach my $dir ( glob $dir_pattern ) {
        if ( -d $dir and $dir =~ /.*task-\d+--.*--dir/xms ) {
            $num_of_task_dirs++;
            my $num_of_files = 0;
            my $file_pattern = "$dir/*.pax";
            $uptask_map{$num_of_task_dirs}{'isgood'} = 'yes';
            foreach my $file ( glob $file_pattern ) {
                $num_of_files++;
                if ( -f $file ) {
                    $uptask_map{$num_of_task_dirs}{'file'} = $file;
                }
            }
            if ( $num_of_files == 0 ) {
                print_debug_warning 'There is no pax archives in ' . $dir;
                $uptask_map{$num_of_task_dirs}{'isgood'} = 'no';
            }
            elsif ( $num_of_files > 1 ) {
                print_debug_warning 'There is too many pax archives in ' . $dir;
                $uptask_map{$num_of_task_dirs}{'isgood'} = 'no';
            }
        }
    }
    my ( $writer, $reader, $err );
    open3( $writer, $reader, $err, $ldv_path_to_results_sql_bin );
    my @lines = <$reader>;
    if ( check_system_call() == $ERROR_CODE ) {
        croak
'There is no script that says the path to results schema sql executable in your PATH!';
    }
    if ( $CHILD_ERROR >> $EIGHT ) {
        croak 'The script that says the path to results schema sql returns \''
          . ( $CHILD_ERROR >> $EIGHT ) . q{'};
    }
    if ( not defined $lines[0] ) {
        croak
'The script doesn\'t say the path to results schema sql in the first line';
    }
    chomp $lines[0];
    $ldv_results_sql = $lines[0];
    print_debug_debug 'The results schema sql scipt is ' . $ldv_results_sql;
    return;
}

sub run_ldv_upload {
    print_debug_normal 'Setup the test database';
    my $cmd = "$mysql_bin --user=$LDVUSERCTEST $LDVDBCTEST";
    if ($LDVDBHOSTCTEST) {
        $cmd .= " --host=$LDVDBHOSTCTEST";
    }
    if ($LDVDBPASSWDCTEST) {
        $cmd .= " --password=$LDVDBPASSWDCTEST";
    }
    $cmd .= " < $ldv_results_sql";
    system $cmd;
    if ( check_system_call() == $ERROR_CODE ) {
        croak 'There is no the mysql executable in your PATH!';
    }
    if ( $CHILD_ERROR >> $EIGHT ) {
        croak 'The mysql returns \'' . ( $CHILD_ERROR >> $EIGHT ) . q{'};
    }

    # I used this cycle to upload pax archives in right order
    my $i = 1;
    while ( $i <= $num_of_task_dirs ) {
        if ( $uptask_map{$i}{'isgood'} eq 'yes' ) {
            upload_right_results $uptask_map{$i}{'file'};
        }
        $i++;
    }
    print_debug_normal 'Uploader successfully finished';
    return;
}

sub upload_right_results {
    my $file = shift;
    print_debug_trace 'Uploading the results: ' . $file;
    local $ENV{$ldv_uploader_database} = $LDVDBCTEST;
    local $ENV{$ldv_uploader_user}     = $LDVUSERCTEST;
    print_debug_debug
"The database '$LDVDBCTEST' and the user '$LDVUSERCTEST' is setup for the ldv-upload";
    if ($LDVDBHOSTCTEST) {
        local $ENV{$ldv_uploader_host} = $LDVDBHOSTCTEST;
        print_debug_debug
          "The host '$LDVDBHOSTCTEST' is setup for the ldv-upload";
    }

    if ($LDVDBPASSWDCTEST) {
        local $ENV{$ldv_uploader_password} = $LDVDBPASSWDCTEST;
        print_debug_debug
          "The password '$LDVDBPASSWDCTEST' is setup for the ldv-upload";
    }
    my @upload_command = ( $ldv_uploader_bin, $file );
    print_debug_debug "Execute the command '@upload_command'";
    system @upload_command;
    if ( check_system_call() == $ERROR_CODE ) {
        croak 'There is no the ldv-upload executable in your PATH!';
    }
    delete $ENV{$ldv_uploader_database};
    delete $ENV{$ldv_uploader_user};
    delete $ENV{$ldv_uploader_host};
    delete $ENV{$ldv_uploader_password};
    print_debug_trace "'$file' was successfully uploaded";
    return;
}
