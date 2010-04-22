package DSCV::RCV::Utils;

# Utils for RCV backends: preprocess files, CIL-ize files, etc.

use strict;
use vars qw(@ISA @EXPORT_OK @EXPORT);
@EXPORT=qw();
use base qw(Exporter);

# For warnings
use LDV::Utils;

use Cwd;
# Preprocesses file in the directory given with the options given.  Returns what call to C<system> returned.
# Usage:
# 	preprocess_file( cwd=>'working/dir', i_file => 'output.i', c_file => 'input.c', opts=> ['-D','SOMETHING'] )
sub preprocess_file
{
	my $info = {@_};
	# Change dir to cwd; then change back
	my $current_dir = getcwd();
	chdir $info->{cwd} or die;

	my @cpp_args = ("gcc","-E",
		"-o","$info->{i_file}",	#Output file
		"$info->{c_file}",	#Input file
		@{$info->{opts}},	#Options
	);
	vsay ('DEBUG',"Preprocessor: ",@cpp_args);
	local $"=' ';
	my $result = system @cpp_args; 

	chdir $current_dir;
	return $result;
}

1;



