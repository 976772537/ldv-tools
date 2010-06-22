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
