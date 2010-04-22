package DSCV::Sanity;

# Sanity checker for DSCV/RCV intrinsics

use strict;
use vars qw(@ISA @EXPORT_OK @EXPORT);
@EXPORT=qw();
use base qw(Exporter);
#use Carp;

use XML::Twig;
use Fcntl qw(:flock SEEK_SET);

my $debug_me = '';

sub new
{
	my $class = shift;
	my $dscv_dir = shift || Carp::confess;
	my $this = {
		_filename => "$dscv_dir/sanity.xml",
		_filename_toread => "$dscv_dir/.sanity_toread.xml",
		F => undef,
	};
	# Create dummy XML unless it exists
	`echo "<sanity></sanity>" >\Q$this->{_filename}\E` unless (-f $this->{_filename});
	bless ($this,$class);
	return $this;
}


sub copyfwd
{
	my $this = shift;
	# Copy file, to be able to set directly to the locked one
	copy($this->{_filename},$this->{_filename_toread}) or Carp::confess;
}
sub copyback
{
	my $this = shift;
	# Copy file, to be able to set directly to the locked one
	copy($this->{_filename_toread},$this->{_filename}) or Carp::confess;
}

# Lock info file
sub info_lock
{
	my $this = shift;

	die "This is already locked!" if defined $this->{F};

	open($this->{F}, "+>>", $this->{_filename}) or Carp::confess "Can't open $this->{_filename}: $!";

	flock($this->{F}, LOCK_EX) or confess "Locking file failed";

	$this->copyfwd();

	seek($this->{F}, 0, 0) or confess "seek failed";
	truncate($this->{F}, 0) or confess "truncate failed";

}

# Unlock info file
sub info_unlock
{
	my $this = shift;

	die "What is not locked cannot be unlocked!" unless defined $this->{F};

	close($this->{F});

	$this->{F} = undef;
}

use File::Copy;
sub raw_get
{
	my $this = shift;
	my $var = shift or Carp::confess;

	my $value = undef;
	sub readvar
	{
		my ($twig, $varT) = @_;
		$value = $varT->text;
	}
	XML::Twig->new(twig_handlers => { "sanity/$var" => \&readvar })->parsefile($this->{_filename_toread});
	print "RAW_GET $@: first ".`cat $this->{_filename}`." second ".`cat $this->{_filename_toread}` if $debug_me;
	return $value;
}

# Get value from sanity file.  DO NOT USE if already lock'ed.
sub get
{
	my $this = shift;
	my $result = undef;

	$this->info_lock();
	eval {
		$result = $this->raw_get(@_);
		$this->copyback();
		print "GET after cpy $@: first ".`cat $this->{_filename}`." second ".`cat $this->{_filename_toread}` if $debug_me;
	};
	my $err = $@;
	$this->info_unlock();
	Carp::confess $err if $err;
	print "GET $@: first ".`cat $this->{_filename}`." second ".`cat $this->{_filename_toread}` if $debug_me;
	return $result;
}

# Assume file's locked.  Set its contents.
sub raw_set
{
	my $this = shift;
	my $var = shift or Carp::confess;

	defined $this->{F} or die "File's not loaded, but you wanna set $var";

	sub var_writer
	{
		my ($var,$val) = @_;
		return sub {
			my ($twig, $sanT) = @_;
			my $childT = $sanT->first_child($var);
			if ($childT) {
				$childT->set_text($val);
			}else{
				XML::Twig::Elt->new($var,{},$val)->paste(last_child => $sanT);
			}
			$sanT->print($this->{F});
		};
	}
	print "RAW_SET BEFP $@: first ".`cat $this->{_filename}`." second ".`cat $this->{_filename_toread}` if $debug_me;
	XML::Twig->new(
		twig_roots => { "sanity" => var_writer($var,@_) },
		twig_print_outside_roots => $this->{F},
	)->parsefile($this->{_filename_toread});
	print "RAW_SET $@: first ".`cat $this->{_filename}`." second ".`cat $this->{_filename_toread}` if $debug_me;
}

sub blast_called
{
	my $this = shift;
	my $num = undef;

	$this->info_lock();
	eval {
		$num = $this->raw_get('blast_calls') || 0;
		$num++;
		$this->raw_set('blast_calls',$num);
	};
	my $err = $@;
	$this->info_unlock();
	Carp::confess $err if $err;
	print "BLAST_CALLED $@: first ".`cat $this->{_filename}`." second ".`cat $this->{_filename_toread}` if $debug_me;
}

1;


