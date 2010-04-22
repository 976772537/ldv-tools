package Utils;

# Common utils, wrappers around perl library functions etc.

use strict;
use vars qw(@ISA @EXPORT_OK @EXPORT);
@EXPORT=qw();
#@EXPORT_OK=qw(set_verbosity);
use base qw(Exporter);

# Just like waitpid, but wait until a child REALLY exits.
sub hard_wait
{
	my $wpres = 0;
	while ($wpres == 0){
		$wpres = waitpid $_[0],$_[1];
	}
	return $wpres;
}


1;

