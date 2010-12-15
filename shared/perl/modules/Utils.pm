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
	my ($stime, $utime, $status) = undef;
	while (!defined $wpres || $wpres != $pid){
		($wpres, $status, $utime, $stime) = wait3('blocking');
	}
	$? = $status;
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

sub hash_to_xml
{
	my ($hash,$tag,$out) = @_;
	$out ||= \*STDOUT;
	local $_;

	my $e = XML::Twig::Elt->new($tag);
	for my $key (%$hash){
		my $val = $hash->{$key};
		next unless defined $val;
		if (ref $val eq 'ARRAY'){
			XML::Twig::Elt->new($key,{},$_)->paste(last_child => $e) for @$val;
		}elsif(ref $val eq 'XML::Twig::Elt'){
			$val->copy->paste(last_child => $e);
		}elsif(ref $val eq ''){
			XML::Twig::Elt->new($key,{},$val)->paste(last_child=>$e);
		}else{
			die "unsupported ref '".(ref $val)." for key $key";
		}
	}

	$e->set_pretty_print('indented');
	$e->print($out);
}

sub xml_to_hash
{
	my ($from, $opts) = @_;
	# Process options
	my @to_array = ();
	my @to_xml = ();
	if ($opts){
		@to_array = @{$opts->{to_array}};
		@to_xml = @{$opts->{to_xml}};
	}

	my %args = ();

	# Read
	# This is a small XML, load it directly
	my $twig = XML::Twig->new();
	$twig->parsefile($from);
	my $inputT = $twig->root();

	local $_;
	# Copy arguments
	$args{$_} = [$inputT->children_text($_)] for @to_array;
	$args{$_->name} = $_->copy for grep {$_} map {$inputT->first_child($_)} @to_xml;
	# Copy the rest into args
	my %read = map {$_ => 1} (@to_array, @to_xml);
	my $e;
	for ($e = $inputT->first_child(); $e ; $e = $e->next_sibling()){
		$args{$e->tag} = $e->text() unless ($read{$e->tag});
	}

	return %args;
}

1;

