#!/usr/bin/perl -w

use SOAP::Lite;

my $csd = SOAP::Lite -> service($ENV{'WSDLADDR'}.'?wsdl');
$csd->isEmpty() eq 'false' and exit 1;
exit 0;

