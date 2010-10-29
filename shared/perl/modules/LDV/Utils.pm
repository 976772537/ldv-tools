package LDV::Utils;

# The debug printing package for all ldv perl tools.

use strict;
use vars qw(@ISA @EXPORT_OK @EXPORT);
@EXPORT=qw(&vsay print_debug_warning print_debug_normal print_debug_info print_debug_debug print_debug_trace print_debug_all get_debug_level check_system_call);
#@EXPORT_OK=qw(set_verbosity);
use base qw(Exporter);

# Stream where debug messages will be printed.
my $debug_stream = \*STDOUT;

my $verbosity = 10;

# "English" debug levels
my %levels = (
  "QUIET"    => 0,
  "WARNING"  => 4,
  "NORMAL"   => 10,
  "INFO"     => 20,
  "DEBUG"    => 30,
  "TRACE"    => 40,
  "ALL"      => 100,
);

my %backlev = reverse %levels;

sub from_eng
{
  my $lvl = uc shift;
  return $levels{$lvl} if exists $levels{$lvl};
  Carp::confess "Incorrect debug level: $lvl" unless $lvl =~ /^[0-9]*$/;
  return $lvl;
}

# Check whether a user specified verbosity level is greater then the package
# standard one.
sub check_verbosity
{
    my $level = shift || $ENV{'LDV_DEBUG'};
    $level = from_eng($level);
    return ($level <= $verbosity);
}

# Set verbosity level according to the value supplied or evironment variable
sub set_verbosity
{
  my $level = shift || $ENV{'LDV_DEBUG'};
  $level = from_eng($level);
  $verbosity = $level;
}

my @instrument = ($0);
sub push_instrument
{
  push @instrument,@_;
}
sub pop_instrument
{
  pop @instrument;
}

# Say something only if the number supplied is not less than current verbosity
sub vsay
{
  my $v = from_eng shift;
  local $,=' ';
  if ($v <= $verbosity) {
    my $instrument = $instrument[-1];
    my $level_string = $backlev{$v};
    print $debug_stream "$instrument: " if defined $instrument;
    print $debug_stream "$level_string: ";
    print $debug_stream @_;
  }
}

# Debug printing functions output some information in depend on the debug level.
# args: the only string to be printed with a small formatting.
# retn: nothing.
sub print_debug_warning
{
  vsay('WARNING', "$_[0].\n");
}
sub print_debug_normal
{
  vsay('NORMAL', "$_[0].\n");
}
sub print_debug_info
{
  vsay('INFO', "$_[0].\n");
}
sub print_debug_debug
{
  vsay('DEBUG', "$_[0].\n");
}
sub print_debug_trace
{
  vsay('TRACE', "$_[0].\n");
}
sub print_debug_all
{
  vsay('ALL', "$_[0].\n");
}

# Determine the debug level in depend on the passed arguments.
# args: (the tool to be debugged name; the LDV_DEBUG value; the tool debug value).
# retn: nothing.
sub get_debug_level
{
  my $tool_debug_name = shift;

  return 0 unless ($tool_debug_name);

  push_instrument($tool_debug_name);

  # By default (in case when neither the LDV_DEBUG nor the tool debug
  # environment variables aren't specified) or when they are both 0 just
  # information on critical errors is printed.
  # Otherwise the tool debug environment variable is preferable.
  my $ldv_debug = shift;
  my $tool_debug = shift;

  if ($tool_debug)
  {
    set_verbosity($tool_debug);
    print_debug_debug("The debug level is set correspondingly to the tool debug environment variable value '$tool_debug'");
  }
  elsif ($ldv_debug)
  {
    set_verbosity($ldv_debug);
    print_debug_debug("The debug level is set correspondingly to the general LDV_DEBUG environment variable value '$ldv_debug'.");
  }
}

sub check_system_call
{
  # This is got almost directly from the Perl manual:
  # http://perldoc.perl.org/functions/system.html
  if ($? == -1)
  {
    print("Failed to execute: $!\n");
    return -1;
  }
  elsif ($? & 127)
  {
    printf("Child died with signal %d, %s coredump\n", ($? & 127), ($? & 128) ? 'with' : 'without');

    die("The process was interrupted with CTRL+C") if (($? & 127) == 2);

    return ($? & 127);
  }
  elsif ($? >> 8)
  {
    printf("Child exited with value %d\n", ($? >> 8));
    return ($? >> 8);
  }

  return 0;
}

1;



