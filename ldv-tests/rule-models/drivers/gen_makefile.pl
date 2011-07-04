#!/usr/bin/perl
#	Generated model test Makefile for the current directory, and prints to standard output.
#	Module name is calculated from the current dir name, but may be specified as argument.

use strict;
use Cwd;
use File::Spec;

my $module_name = shift @ARGV;
unless ($module_name){
	# Get miodule name from the current path
	my $curdir=getcwd();
	$curdir =~ s/.*\/test-//;
	$module_name = $curdir;
}

my @c_files = <*.c>;
my $mf = 'main.c';
@c_files = grep {$_ ne $mf} @c_files;
# Strip suffixes
s/\.c$// for @c_files;

for my $cfb (@c_files){
	printf '%1$s-test-objs := main.o %1$s.o'."\n", $cfb,$cfb;
}

for my $cfb (@c_files){
	printf "obj-m += %1s-test.o\n", $cfb;
}


