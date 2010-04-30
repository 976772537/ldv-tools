package LDV::Utils;

# The debug printing package for all ldv perl tools.

use strict;
use vars qw(@ISA @EXPORT_OK @EXPORT);
@EXPORT=qw(&vsay);
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

1;



