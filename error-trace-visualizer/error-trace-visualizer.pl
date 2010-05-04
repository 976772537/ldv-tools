#! /usr/bin/perl -w


use English;
use Env qw(LDV_DEBUG LDV_ERROR_TRACE_VISUALIZER_DEBUG);
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

# Debug functions. They print some information in depend on the debug level.
# args: string to be printed.
# retn: nothing.
sub print_debug_normal($);
sub print_debug_info($);
sub print_debug_debug($);
sub print_debug_trace($);
sub print_debug_all($);

# Process an error trace passed through options.
# args: no.
# retn: nothing.
sub process_error_trace();

# Process a blast error trace.
# args: no.
# retn: nothing.
sub process_error_trace_blast();


################################################################################
# Global variables.
################################################################################

# Prefix for all debug messages.
my $debug_name = 'error-trace-visualizer';

# Engines which reports can be parsed are keys and values are corresponding
# parsing subroutines.
my %engines = ('blast' => \&process_error_trace_blast);

# File handlers.
my $file_report_in;
my $file_report_out;
my $file_reqs_out;

# Command-line options. Use --help option to see detailed description of them.
my $opt_engine;
my $opt_help;
my $opt_report_in;
my $opt_report_out;
my $opt_reqs_out;


################################################################################
# Main section.
################################################################################

# Obtain the debug level.
get_debug_level();

print_debug_normal("Process the command-line options.");
get_opt();

print_debug_normal("Process trace.");
process_error_trace();

print_debug_trace("Close file handlers.");
close($file_report_in) 
  or die("Can't close the file '$opt_report_in': $ERRNO\n");
close($file_report_out) 
  or die("Can't close the file '$opt_report_out': $ERRNO\n");
close($file_reqs_out) 
  or die("Can't close the file '$opt_reqs_out': $ERRNO\n");
  
print_debug_normal("Make all successfully.");


################################################################################
# Subroutines.
################################################################################

sub get_debug_level()
{
  LDV::Utils::push_instrument($debug_name);

  # By default (in case when neither LDV_DEBUG nor 
  # LDV_ERROR_TRACE_VISUALIZER_DEBUG environment variables aren't specified) or 
  # when LDV_DEBUG and LDV_ERROR_TRACE_VISUALIZER_DEBUG are 0 just information 
  # on errors is printed. 
  # Otherwise:  
  if (defined($LDV_ERROR_TRACE_VISUALIZER_DEBUG))
  {
    LDV::Utils::set_verbosity($LDV_ERROR_TRACE_VISUALIZER_DEBUG);
    print_debug_debug("The debug level is set correspondingly to the LDV_ERROR_TRACE_VISUALIZER_DEBUG environment variable value '$LDV_ERROR_TRACE_VISUALIZER_DEBUG'.");
  }
  elsif (defined($LDV_DEBUG))
  {
    LDV::Utils::set_verbosity($LDV_DEBUG);
    print_debug_debug("The debug level is set correspondingly to the LDV_DEBUG environment variable value '$LDV_DEBUG'.");
  }
}

sub get_opt()
{
  if (scalar(@ARGV) == 0)
  {
    warn("No options were specified through the command-line. Please see help to understand how to use this tool");
    help();
  }
  print_debug_trace("The options '@ARGV' were passed to the instrument through the command-line.");

  unless (GetOptions(
    'engine=s' => \$opt_engine,
    'help|h' => \$opt_help,
    'report|c=s' => \$opt_report_in,
    'report-out|o=s' => \$opt_report_out,
    'reqs-out=s' => \$opt_reqs_out))
  {
    warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
    help();
  }

  help() if ($opt_help);
  
  unless ($opt_engine && $opt_report_in && $opt_report_out && $opt_reqs_out) 
  {
    warn("You must specify the options --engine, --report|c, --report-out|o, --reqs-out in the command-line");
    help();
  }

  open($file_report_out, '>', "$opt_report_out")
    or die("Can't open the file '$opt_report_out' specified through the option --report-out|o for write: $ERRNO");
  print_debug_debug("The report output file is '$opt_report_out'.");

  open($file_reqs_out, '>', "$opt_reqs_out")
    or die("Can't open the file '$opt_reqs_out' specified through the option --reqs-out for write: $ERRNO");
  print_debug_debug("The requrements output file is '$opt_reqs_out'.");

  open($file_report_in, '<', "$opt_report_in")
    or die("Can't open the file '$opt_report_in' specified through the option --report-in|c for read: $ERRNO");
  print_debug_debug("The report input file is '$opt_report_in'.");
  
  print_debug_debug("The command-line options are processed successfully.");
}

sub help()
{
    print(STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to visualize error traces 
    obtained from different static verifiers.

SYNOPSIS
  $PROGRAM_NAME [option...]

OPTIONS

  --engine <id>
    <id> is an engine identifier (like 'blast' and so on).

  -h, --help
    Print this help and exit with a error.

  -c, --report <file>
    <file> is an absolute path to a file containing error trace.

  -o, --report-out <file>
    <file> is an absolute path to a file that will contain error trace
    processed by the tool.

  --reqs-out <file>
    <file> is an absolute path to a file that will contain a list of
    required for report files.
    
ENVIRONMENT VARIABLES

  LDV_DEBUG
    It's an optional environment variable that specifies a debug 
    level. It uses the standard designatures to distinguish different
    debug information printings. Each next level includes all previous
    levels and its own messages.
    
  LDV_ERROR_TRACE_VISUALIZER_DEBUG 
    Like LDV_DEBUG but it has more priority. It specifies a debug 
    level just for this instrument.

EOM

  exit(1);
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

sub process_error_trace()
{
  print_debug_trace("Check whether specified static verifier engine is supported.");
  die("The specified static verifier engine '$opt_engine' isn't supported. Please use one of the following engines: '" . keys(%engines) . "'") unless(defined($engines{$opt_engine}));
  print_debug_debug("Process the '$opt_engine' static verifier error trace.");
  $engines{$opt_engine}->();  
  print_debug_debug("'$opt_engine' static verifier error trace is processed successfully.");
}

sub process_error_trace_blast()
{
  print("hie!!!\n");
}
