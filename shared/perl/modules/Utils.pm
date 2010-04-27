package Utils;

# Common utils, wrappers around perl library functions etc.

use strict;
use vars qw(@ISA @EXPORT_OK @EXPORT);
@EXPORT=qw();
#@EXPORT_OK=qw(set_verbosity);
use base qw(Exporter);

# Just like waitpid, but wait until a child REALLY exits.
# It also calculates child statistics, such as running time and stuff
use Proc::Wait3;
sub hard_wait
{
	my $pid = shift;
	my $wpres = undef;
	my ($stime, $utime) = undef;
	while (!defined $wpres || $wpres != $pid){
		($wpres, undef, $utime, $stime) = wait3('blocking');
	}
	return ('utime'=>$utime, 'stime'=>$stime);
}

# Functor that creates an "unbasedir" function out of argument DIR.  The unbasedir function strips DIR prefix from its argument.
sub unbasedir_maker
{
	my $base_dir = shift;
	return sub {
		my $from = shift or die;
		my $rslt = $from;
		$rslt =~ s/^$base_dir\/*//;
		return $rslt;
	}
}

# Usage: relpath($base, $to);
# Return path that would be reached if you wrote "cd $base; cd $to" in the shell.
sub relpath
{
	my $base = shift or die;
	my $to = shift or die;
	if ($to =~ /^\//) {
		return $to;
	}else{
		return "$base/$to";
	}
}

1;

