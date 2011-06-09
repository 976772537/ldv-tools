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
		($wpres, $status, $utime, $stime) = wait3(1); # 1 means that the call is blocking
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

# Opens command, connects to its stdout and stderr via pipes, and invokes a callback for each line read from there.  You may supply either generic callback, or a separate callback for both streams, or more callbacks.  If you specify no callbacks, it mimics system() call.
# Usage:
# 	open3_callbacks("ls","-l")
# 	open3_callbacks(sub{ both streams },"ls","-l")
# 	open3_callbacks({ out=>sub{ stdout }, err=>sub { stderr }}, "ls","-l")
# Available callbacks:
# 	out => linewise stdout capture
# 	err => linewise stderr capture
# 	close_out => when stdout EOF is encountered
# 	close_err => when stderr EOF is encountered
# 	in_text => text to print to stdin before closing it
use IPC::Open3;
use IO::Select;
sub open3_callbacks
{
	my $callbacks = shift;
	my ($out_callback,$err_callback,$close_out_callback,$close_err_callback) = (sub{print STDOUT $_[0];},sub{print STDERR $_[0];},sub{},sub{});
	my $in_text = '';
	# Variable arguments: determine callbacks
	if (ref $callbacks eq 'CODE') {
		$out_callback = $callbacks;
		$err_callback = $callbacks;
	}elsif (ref $callbacks eq 'HASH'){
		$err_callback = $callbacks->{'err'} || $callbacks->{'out'} || sub{print STDERR $_[0];};
		$out_callback = $callbacks->{'out'} || sub{print STDOUT $_[0];};
		$close_out_callback = $callbacks->{'close_out'} || sub{};
		$close_err_callback = $callbacks->{'close_err'} || sub{};
		$in_text = $callbacks->{'in_text'} || '';
	}else{
		# It was a (part of a) command we're to run.
		unshift @_,$callbacks;
	}

	# Chunk to read from pipe in one nonblocking read operation
	my $chunk_size = 4000;

	# Spawn child process
	local (*SUB_IN,*SUB_OUT,*SUB_ERR);
	local $"=" ";
	local $_;
	my $fpid = open3(*SUB_IN,*SUB_OUT,*SUB_ERR,@_) or die "Can't open3. PATH=".$ENV{'PATH'}." Cmdline: @_";

	my $select = IO::Select->new();
	$select->add(\*SUB_OUT);
	$select->add(\*SUB_ERR);

	my $select_write = IO::Select->new();
	if ($in_text ne ''){
		$select_write->add(\*SUB_IN);
	}else{
		close SUB_IN;
	}
	# Buffers to perform a non-block read and split it into lines
	my ($err_buf,$out_buf);
	my @ready_fhs = ();
	my @write_fhs = ();
	while (($select->count() + $select_write->count()) && (@ready_fhs = IO::Select->select($select,$select_write))){ for my $fh (@{$ready_fhs[0]},@{$ready_fhs[1]}){
		if ($in_text && $fh == \*SUB_IN){
			# Print a chunk
			my $written = syswrite SUB_IN,$in_text,length($in_text);
			$in_text = substr $in_text, $written,(length($in_text)-$written);

			# If we've written everything, then close the filehandle
			if ($in_text eq ''){
				$select_write->remove(\*SUB_IN);
				# First remove, then close
				close SUB_IN;
			}
		}elsif ($fh == \*SUB_OUT) {
			# Non-blocking read and add to buffer
			my $buf;
			my $read = sysread SUB_OUT,$buf,$chunk_size;
			$out_buf.=$buf;
			# Split buffer into lines and push to result calculator
			while ($out_buf =~ /(.*?\n)(.*)/s) {
				my $line = $1;
				$out_buf=$2;
				# Process the line fetched
				$out_callback->($line);
			}
			# Read of zero indicates an EOF, and read of undef indicates an error (which may be a closed pipe)
			unless ($read){
				# chew what's left in the buffer
				$out_callback->($out_buf);
				$select->remove(\*SUB_OUT);
				$close_out_callback->();
			}
		}elsif ($fh == \*SUB_ERR) {
			# Non-blocking read and add to buffer
			my $buf;
			my $read = sysread SUB_ERR,$buf,$chunk_size;
			$err_buf.=$buf;
			# Split buffer into lines and push to result calculator
			while ($err_buf =~ /(.*?\n)(.*)/s) {
				my $line = $1;
				$err_buf=$2;
				# Process the line fetched
				$err_callback->($line);
			}
			# Read of zero indicates an EOF, and read of undef indicates an error (which may be a closed pipe)
			unless ($read){
				# chew what's left in the buffer
				$err_callback->($err_buf);
				$select->remove(\*SUB_ERR);
				$close_err_callback->();
			}
		}
	}}

	return Utils::hard_wait($fpid,0);
}

1;

