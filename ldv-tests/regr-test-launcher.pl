#! /usr/bin/perl -w


use English;
use Env qw(LDV_DEBUG);
use FindBin;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../shared/perl");

# Add some nonstandard local Perl packages.
use LDV::Utils;


################################################################################
# Subroutine prototypes.
################################################################################

# Determine the debug level in depend on the environment variable value.
# args: no.
# retn: nothing.
sub get_debug_level();

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

# Debug functions. They print some information in depend on the debug level.
# args: string to be printed.
# retn: nothing.
sub print_debug_normal($);
sub print_debug_info($);
sub print_debug_debug($);
sub print_debug_trace($);
sub print_debug_all($);


################################################################################
# Global variables.
################################################################################

# Prefix for all debug messages.
my $debug_name = 'regr-test-launcher';

# Command-line options. Use --help option to see detailed description of them.
my $opt_help;
my $opt_out;
my $opt_test_set;

# This hash contains unique tasks (some keys) to be executed.
my %tasks;

# The task set to be used.
my $task_set;
# The available predefined task sets.
my %test_sets = ('small' => 1, 'medium' => 1, 'big' => 1);


################################################################################
# Main section.
################################################################################

# Obtain the debug level.
get_debug_level();

print_debug_normal("Process the command-line options.");
get_opt();

print_debug_normal("Check presence of needed files, executables and directories. Copy needed files and directories.");
prepare_files_and_dirs();




################################################################################
# Subroutines.
################################################################################

sub get_debug_level()
{
  LDV::Utils::push_instrument($debug_name);

  # By default (in case when LDV_DEBUG environment variables is't specified) or 
  # when LDV_DEBUG is 0 just information on errors is printed. Otherwise:  
  if (defined($LDV_DEBUG))
  {
    LDV::Utils::set_verbosity($LDV_DEBUG);
    print_debug_debug("The debug level is set correspondingly to the LDV_DEBUG environment variable value '$LDV_DEBUG'.");
  }
}

sub get_opt()
{
  unless (GetOptions(
    'help|h' => \$opt_help,
    'results|o=s' => \$opt_out,
    'test-set=s' => \$opt_test_set))
  {
    warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
    help();
  }

  help() if ($opt_help);

  if ($opt_out)
  {
    die("The directory specified through the option --results|o doesn't exist: $ERRNO")
      unless (-d $opt_out);
    print_debug_debug("The results will be put to the '$opt_out' directory.");
  }

  if ($opt_test_set)
  {
	unless (defined($test_sets{$opt_test_set}))
	{  
      warn("The test set specified through the option --test-set can't be processed. Please use one of the following ones:\n");
      
      foreach my $test_set (keys(%test_sets))
      {
		warn("  - '$test_set'\n");
	  }
      
      die(); 
    }
    print_debug_debug("The results will be put to the '$opt_out' directory.");
  }
  
  print_debug_debug("The command-line options are processed successfully.");
}

sub help()
{
    print(STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to launch some regression tests.

SYNOPSIS
  $PROGRAM_NAME [option...]

OPTIONS

  -h, --help
    Print this help and exit with a error.

  -o, --results <dir>
    <dir> is a path to a directory where all launches results will be 
    placed. It's optional. If it isn't specified then results are 
    placed to the current directory.

  --test-set <name>
    <name> must be one of the predefined test set names. It's optional.
    If this option isn't specified, then current folder is scanned for
    the regression test tasks.

ENVIRONMENT VARIABLES

  LDV_DEBUG
    It's an optional environment variable that specifies a debug 
    level. It uses the standard designatures to distinguish different
    debug information printings. Each next level includes all previous
    levels and its own messages.
    
  LDV_TAG 
    It's an optional environment variable that specifies a toolset tag. 
    It may be either some git tag or git commit or 'current' (the last
    is used by default). 

EOM

  exit(1);
}

sub prepare_files_and_dirs()
{
}

sub print_debug_normal($)
{
  my $message = shift;
  
  vsay('NORMAL', "$message\n");
}

sub print_debug_info($)
{
  my $message = shift;
  
  vsay('INFO', "$message\n");
}

sub print_debug_debug($)
{
  my $message = shift;
  
  vsay('DEBUG', "$message\n");
}

sub print_debug_trace($)
{
  my $message = shift;
  
  vsay('TRACE', "$message\n");
}

sub print_debug_all($)
{
  my $message = shift;
  
  vsay('ALL', "$message\n");
}

