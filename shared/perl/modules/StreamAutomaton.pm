package StreamAutomaton;

# Package to support stream automata.

use strict;
use vars qw(@ISA @EXPORT_OK @EXPORT);
@EXPORT=qw();
use base qw(Exporter);
use Carp;

# Here are heuristics that detect various types of errors.  Histogram will be build based on string values.
# 
# Each heuristic returns an array [lines,subroutine].  The subroutine returns a hash ofthe following form: 
# {  group1 => value
#    group2 => value
# }
# Each `value' can be a string or undefined.  The heuristics are run until for each group at least one non-undefined string was returned (or until the file is read).
# a specia group with name
my $DEFAULT = 'BLAST-detailed';
# is used as `primary'; it's printed on the screen and to outfile.

sub mk_tailfilters
{
	# Used to contain default BLAST automatons.  They have been moved to RCV blast plugin--or deleted
	return ();
}

sub mk_headfilters
{
	# Used to contain default BLAST automatons.  They have been moved to RCV blast plugin--or deleted
	return ();
}

sub new
{
	my $class = shift;
	my $tail_filters = shift || [];
	$tail_filters = [mk_tailfilters(), @$tail_filters];
	my $head_filters = shift || [];
	$head_filters = [mk_headfilters(), @$head_filters];
	my $all_filters = shift || [];
	my ($tail_filter,$tail) = main_filter(@$tail_filters);
	my ($head_filter,$head) = main_filter(@$head_filters);
	my ($all_filter,undef) = main_filter(@$all_filters);
	my $this = {
		tailfilter => $tail_filter,
		tail => $tail,
		headfilter => $head_filter,
		head => $head,
		allfilter => $all_filter,
		accum => {},
		accum_tail_array => [],
		tail_autom => {},
		head_autom => {},
		finished => '',
	};
	bless ($this,$class);
	return $this;
}

sub clear
{
	my $this = shift or carp;
	$this->{accum} = [];
	$this->{accum_tail} = [];
}

sub chew_line
{
	my $this = shift or carp;
	my $line = shift;
	# Result we'll be gathering all through head 
	my $result = {};
	# While fetching tail, we will also process the head.
	my $heads_to_process = $this->{head};
	# Update the tail array
	push @{$this->{accum_tail}},$line;
	shift @{$this->{accum_tail}} if scalar @{$this->{accum_tail}} > $this->{tail};
	# Process head filters
	if (defined $this->{headfilter} && $heads_to_process-- > 0 ){
		$result = $this->{headfilter}->($line);
	}
	# Process "all" filters that work through the whole trace
	$result = $this->{allfilter}->($line);
	# Return result 
	$this->{accum} = add_hash($this->{accum},$result);
}

sub finish
{
	my $this = shift or carp;
	# Add last "undef" to tail unless it's already there
	push @{$this->{accum_tail}},undef if defined $this->{accum_tail}->[-1];

	# Call filters for tail
	my $tail_result = {};
	for (@{$this->{accum_tail}}){
		$tail_result = $this->{tailfilter}->($_);
	}
	$this->{accum} = add_hash($this->{accum},$tail_result);

	# Set finished flag
	$this->{finished} = 1;
}


sub result
{
	my $this = shift or carp;
	$this->finish() unless $this->{finished};
	return {%{$this->{accum}}};
}

# Limits check
sub limits_check
{
	my $idstr = shift || "";
	return [1000,sub {
		my $l=shift or return undef;
		$l=~/${idstr}TIMEOUT (\d+)/i and return {'LIMITS'=>'Time Limit Exceeded'};
		$l=~/${idstr}MEM (\d+)/i and return {'LIMITS'=>'Memory Limit Exceeded'};
		$l=~/${idstr}HANGUP (\d+)/i and return {'LIMITS'=>'Hangup Detected'};
		return undef;
	}];
}

sub bad_archive
{
	return [1,sub {
		my $l=shift or return undef;
		$l=~/gzip:.*unexpected end of file/i and return {$DEFAULT=>'BAD: bad archive'};
		$l=~/bunzip2:.*Compressed file ends unexpectedly/i and return {$DEFAULT=>'BAD: bad archive'};
		return undef;
	}];
}

sub cat
{
	return [1,sub {
		print @_,"\n";
		return undef;
	}];
}

use File::Basename;
# File handle.  Opened once per file in cat function.  Closed after each file in main loop.
my $current_fh;
sub dumptail
{
	my $lines = shift;
	return [$lines,sub {
		my ($line,$fname) = @_;
		!defined $line and return undef;
		unless ($current_fh){
			# Add tails/ prefix to fname
			$fname = "tails/$fname";
			# Strip archives names
			$fname =~ s/(.gz|.bz2)$/.tail/;
			# Create directory for it
			my (undef,$path,undef) = fileparse($fname);
			`mkdir -p \Q$path`;
			open $current_fh, ">>", $fname or die;
		}
		print $current_fh $line,"\n";
		return undef;
	}];
}


# Look for alias stats and dump them to the directory

use File::Basename;
# Hash of the files removed.  Throughout the process we do not remove the whole directory but each file.
# We should do it only once, and after we did it, append, not overwrite
my %removed_info_files = ();

sub dump_alias_stats
{
	my ($dirname) = @_;
	# We need really a lot to 
	return [20_000,sub {
		my $l=shift or return undef;
		if ($l=~/^(SKY: .*)/){
			my $info_line = $1;

			# Create proper file

			my $fname=shift;
			$fname = "$dirname/$fname";
			# Throw away report suffixes, add .info suffix
			$fname =~ s/\.rep(\.debug)?\..*$/.info/;
			# Create proper directory
			my (undef,$path,undef) = fileparse($fname);
			`mkdir -p \Q$path`;
			# Delete file if it's old
			unless (exists $removed_info_files{$fname}){
				`rm -f \Q$fname`;
				$removed_info_files{$fname} = 1;
			}

			# Dump the info obtained

			`echo "$info_line" >>\Q$fname`
		}
		# We always return undef since that's just a stat dumper, it should not interfere with the overall checking process
		return undef;
	}];
}

#Load additional filters
sub load_plugin
{
	my ($file) = @_;
	eval {
		require $file;
	};
	if ($@){ die $@; }
}

#Print one symbol for file's result.
sub symb_for
{
	my $r = shift;
	return '?' unless defined $r;
	$r =~ /ZZZ:/ and return "X";
	$r =~ /AAA.*unsafe/ and return "-";
	$r =~ /AAA.*safe/ and return "+";
	$r =~ /BAD:/ and return "x";
	$r =~ /MODEL:/ and return "m";
	$r =~ /^UNKNOWN/ and return "?";
	$r =~ /^LIM: Time/i and return "T";
	$r =~ /^LIM: Memory/i and return "M";
	return '.';
}

# Given two refs to hashes, builds the third with its elements the same as in 1st one or, if key doesn't exists or its value is not defined, as in 2nd.
sub add_hash
{
	my ($h1,$h2) = @_;
	my $r={%$h1};
	local $_;
	$r->{$_} = $h2->{$_} for grep {!defined $h1->{$_}} keys %$h2;
	return $r;
}


# Get unpacking command that prints to stdout
sub get_unpacker_string
{
	my $fname = shift;
	$fname =~ /.gz$/ and return sub { return "gunzip --to-stdout \E$_[0]";};
	$fname =~ /.bz2$/ and return sub { return "bzcat -c \E$_[0]";};
	# No compression otherwise
	return sub { return "cat \Q$_[0]";};
}
# Unpacker.  Supply a function that will process the file.
#use NumberBytesHuman qw(format_bytes);
use File::Temp;

sub unpack_and_process
{
	my $fname = shift;
	my $filter = shift;
	my $tail = shift;
	my $headfilter = shift;
	my $head = shift;
	# Output file name in order for user not to be bored
	print STDERR "(".format_bytes(-s $fname).")" if -s $fname > 1_000_000;

	# Add tail command if we need tail but don't need head.
	# Bash tail is twice faster as its simple perl implementation.
	my $use_bash_tail = defined $tail && !defined $head;
	
	my $run_str = get_unpacker_string($fname)->($fname)
		# redirect errors to out
		." 2>&1 "
		# pipe unpacked stream...
		." |"
		# Add redirection to FIFO if we also need head
		#.(defined $head?"tee $fifo_name |":'');
		.( $use_bash_tail?"tail -n $tail |":'')
	;
	my $PIPE;
	open $PIPE, $run_str; 
	local $_;

	# Result we'll be gathering all through head 
	my $result = {};

	# @tail array will contain the tail of the file.  The array will be correct even if we have already used bash tail.
	my @tail=();
	# While getting it, we will also process the head.
	my $heads_to_process = $head;
	do{
		$_ = <$PIPE>;
		chomp if defined $_;
		# Update the tail array
		push @tail,$_;
		shift @tail if @tail > $tail;
		# Process head filters
		if (defined $headfilter && $heads_to_process-- > 0 ){
			$result = $headfilter->($_,$fname);
		}
	} while (defined $_);
	# Iterate through all tail lines in the file and call out filter
	my $tail_result = {};
	# Add last "undef" to tail unless it's already there
	push @tail,undef if defined $tail[-1];
	for (@tail){
		$tail_result = $filter->($_,$fname);
	}
	close $PIPE;
	# Return result 
	return add_hash($result, $tail_result);
}

# Maker to join list of filters into one function.
# Gets: list of filters: refs to arrays [number of lines, function]
# Returns: function that returns ref to hash of form {group => result}.
# If any of the filter of the group succeesed, no more processing in this group is made.
sub main_filter
{
	my @heur = (@_);
	return unless @heur;
	# Get the number of lines to fetch from tail
	my $lines = $heur[0]->[0];
	local $_;
	do { $lines = $_->[0] if $lines<$_->[0]; } for @heur;
	# Return filter and tail.  Use closure.

	# The result gathered so far
	my $result = {$DEFAULT=>undef};
	return (
		sub{
			for my $h (@heur){
				my $filter_result = $h->[1]->(@_);
				# Tie filter_result into $result
				$result = add_hash($result,$filter_result);
			}
			return $result;
		},
		$lines
	);

}

1; 

