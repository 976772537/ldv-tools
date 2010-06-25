#! /usr/bin/perl -w


use English;
use Env qw(LDV_DEBUG LDV_REGR_TEST_UPLOADER_DEBUG LDVDBHOSTTEST LDVDBTEST LDVUSERTEST LDVDBPASSWDTEST);
use FindBin;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../../shared/perl");

# Add some nonstandard local Perl packages.
use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info print_debug_debug print_debug_trace print_debug_all get_debug_level);


################################################################################
# Subroutine prototypes.
################################################################################

# Process command-line options. To see detailed description of these options 
# run script with --help option.
# args: no.
# retn: nothing.
sub get_opt();

# Print help message on the screen and exit.
# args: no.
# retn: nothing.
sub help();

# Obtain needed files and dirs and check their presence.
# args: no.
# retn: nothing.
sub prepare_files_and_dirs();

# Upload the launcher results to the database.
# args: no.
# retn: nothing.
sub upload_results();


################################################################################
# Global variables.
################################################################################

# An absolute path to the current working directory.
my $current_working_dir;

# Prefix for all debug messages.
my $debug_name = 'regr-test-uploader';

# The ldv-manager results are identified by their suffix.
my $ldv_manager_result_suffix = '.pax';
# The sql script that contains cleaning and creating of the test database.
my $ldv_results_sql = "$FindBin::RealBin/../../ldv-manager/results_schema.sql";
# Path to the binary of the ldv-upload.
my $ldv_uploader_bin = "$FindBin::RealBin/../../bin/ldv-upload";
# Environments variables that specify the database connection for the ldv-upload.
my $ldv_uploader_host = 'LDVDBHOST';
my $ldv_uploader_database = 'LDVDB';
my $ldv_uploader_user = 'LDVUSER';
my $ldv_uploader_password = 'LDVDBPASSWD';

# The system mysql binary. 
my $mysql_bin = 'mysql';

# Command-line options. Use --help option to see detailed description of them.
my $opt_help;
my $opt_in;

# The directory where results (ldv-manager archives) are.
my $result_dir;


################################################################################
# Main section.
################################################################################

# Obtain the debug level.
get_debug_level($debug_name, $LDV_DEBUG, $LDV_REGR_TEST_UPLOADER_DEBUG);

print_debug_normal("Process the command-line options");
get_opt();

print_debug_normal("Check presence of needed files, executables and directories. Copy needed files and directories");
prepare_files_and_dirs();

print_debug_normal("Upload the launcher results to the database");
upload_results();

print_debug_normal("Make all successfully");


################################################################################
# Subroutines.
################################################################################

sub get_opt()
{
  unless (GetOptions(
    'help|h' => \$opt_help,
    'results|c=s' => \$opt_in))
  {
    warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
    help();
  }

  help() if ($opt_help);

  if ($opt_in)
  {
    die("The directory '$opt_in' specified through the option --results|c doesn't exist: $ERRNO")
      unless (-d $opt_in);
    print_debug_debug("The launcher results will be searched for in the '$opt_in' directory");
  }
  
  print_debug_debug("The command-line options are processed successfully");
}

sub help()
{
    print(STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to load the ldv-manager results to the
    test database.

SYNOPSIS
  $PROGRAM_NAME [option...]

OPTIONS

  -h, --help
    Print this help and exit with a error.

  -c, --results <dir>
    <dir> is a path to a directory where may be launches results. It's optional. 
    If it isn't specified then results are searched for in the current directory.

ENVIRONMENT VARIABLES

  LDV_DEBUG
    It's an optional environment variable that specifies a debug 
    level. It uses the standard designatures to distinguish different
    debug information printings. Each next level includes all previous
    levels and its own messages.

  LDV_REGR_TEST_UPLOADER_DEBUG
    Like LDV_DEBUG but it has more priority. It specifies a debug 
    level just for this instrument.
    
  LDVDBHOSTTEST, LDVDBTEST, LDVUSERTEST, LDVDBPASSWDTEST  
    Keeps settings (host, database, user and password) for connection 
    to the database. Note that LDVDBTEST and LDVUSERTEST must always be 
    presented!
        
EOM

  exit(1);
}

sub prepare_files_and_dirs()
{
  $current_working_dir = Cwd::cwd() 
    or die("Can't obtain the current working directory");
  print_debug_debug("The current working directory is '$current_working_dir'");
  	
  print_debug_trace("Check that database connection is setup");
  die("You don't setup connection to your testing database. See --help for details")
    unless ($LDVDBTEST and $LDVUSERTEST);
    
  print_debug_trace("Obtain the directory where results will be searched for");  
  if ($opt_in)
  {
	$result_dir = $opt_in;
  }
  else
  {
	$result_dir = $current_working_dir;  
  }
  print_debug_debug("The launcher results directory is '$result_dir'");  
}

sub upload_results()
{
  print_debug_trace("Setup the test database");
  my $cmd = "$mysql_bin --user=$LDVUSERTEST $LDVDBTEST";
  $cmd .= " --host=$LDVDBHOSTTEST" if ($LDVDBHOSTTEST);
  $cmd .= " --password=$LDVDBPASSWDTEST" if ($LDVDBPASSWDTEST);
  $cmd .= " <$ldv_results_sql";
  print_debug_info("Execute the command '$cmd'");
  `$cmd`;
  die("The mysql returns '" . ($? >> 8) . "'") if ($? >> 8);

  foreach my $file (<$result_dir/*>) 
  {
	if (-f $file and $file =~ /$ldv_manager_result_suffix$/)
	{  
	  print_debug_trace("Begin to upload the result '$file'");	
      my @args = ($ldv_uploader_bin, $file);		
      print_debug_trace("Specify the database connection environment variables for the ldv-upload");
      $ENV{$ldv_uploader_database} = $LDVDBTEST;
      $ENV{$ldv_uploader_user} = $LDVUSERTEST;
      print_debug_debug("The database '$LDVDBTEST' and the user '$LDVUSERTEST' is setup for the ldv-upload");
      # The 'localhost' is used by the ldv-upload by default.
      if ($LDVDBHOSTTEST)
      {
        $ENV{$ldv_uploader_host} = $LDVDBHOSTTEST;
        print_debug_debug("The host '$LDVDBHOSTTEST' is setup for the ldv-upload");		
	  }
	  # The password is completely optional.
	  if ($LDVDBPASSWDTEST)
      {
        $ENV{$ldv_uploader_password} = $LDVDBPASSWDTEST;
        print_debug_debug("The password '$LDVDBPASSWDTEST' is setup for the ldv-upload");		
	  }
      print_debug_info("Execute the command '@args'");
      my $status = system(@args);
      print_debug_debug("The ldv-upload returns '$status'");  
      # Unset special environments variables.
      delete($ENV{$ldv_uploader_database});
      delete($ENV{$ldv_uploader_user});
      delete($ENV{$ldv_uploader_host});
      delete($ENV{$ldv_uploader_password});
    }
  }
}
