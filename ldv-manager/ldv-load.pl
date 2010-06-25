#! /usr/bin/perl -w


use English;
use Env qw(LDV_DEBUG LDV_REGR_TEST_DEBUG);
use FindBin;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../../shared/perl");

# Add some nonstandard local Perl packages.
use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info 
  print_debug_debug print_debug_trace print_debug_all get_debug_level 
  check_system_call);
  

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


################################################################################
# Global variables.
################################################################################

# An absolute path to the current working directory.
my $current_working_dir;

# Prefix for all debug messages.
my $debug_name = '';

# Command-line options. Use --help option to see detailed description of them.
my $opt_help;


################################################################################
# Main section.
################################################################################

# Obtain the debug level.
get_debug_level($debug_name, $LDV_DEBUG, $LDV_REGR_TEST_DEBUG);

print_debug_normal("Process the command-line options");
get_opt();

print_debug_normal("Check presence of needed files, executables and directories. Copy needed files and directories");
prepare_files_and_dirs();

print_debug_normal("Make all successfully");


################################################################################
# Subroutines.
################################################################################

sub get_opt()
{
  unless (GetOptions(
    'help|h' => \$opt_help,
    'test-set=s' => \$opt_test_set))
  {
    warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
    help();
  }

  help() if ($opt_help);
  
  print_debug_debug("The command-line options are processed successfully");
}

sub help()
{
    print(STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to perform the regression test.

SYNOPSIS
  $PROGRAM_NAME [option...]

OPTIONS

  -h, --help
    Print this help and exit with a error.

  --test-set <name>
    <name> may be one of the predefined test set names or may be absolute
    path to the regression test task file. It's optional. If this option isn't 
    specified, then current folder is scanned for the first regression test 
    task. Note then regression test task is a file beginning with the 
    '$regr_task_prefix' prefix.

ENVIRONMENT VARIABLES

  LDV_DEBUG
    It's an optional environment variable that specifies a debug 
    level. It uses the standard designatures to distinguish different
    debug information printings. Each next level includes all previous
    levels and its own messages.

  LDV_REGR_TEST_DEBUG
    Like LDV_DEBUG but it has more priority. It specifies a debug 
    level just for this instrument.
    
EOM

  exit(1);
}

sub prepare_files_and_dirs()
{
  $current_working_dir = Cwd::cwd() 
    or die("Can't obtain the current working directory");
  print_debug_debug("The current working directory is '$current_working_dir'");
}
