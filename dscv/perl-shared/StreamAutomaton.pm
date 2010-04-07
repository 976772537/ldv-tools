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
	my @heuristics = (bad_archive(),oom_ulimit(),time_limit(),safe_unsafe(),exception(),bad_simplify());

	# Add this heuristics if you want to dump tails of files to tails/ folder
	#unshift @heuristics, dumptail(100);

	# Add this to cat files to stdout.
	#unshift @heuristics, &cat;
	return @heuristics;
}

sub mk_headfilters
{
	my @head_filters = ();
	# Filters that apply from head.  Current implementation SLOWS DOWN PROCESS WHEN YOU USE IT!  HANDLE WITH CARE!
	#unshift @head_filters, dump_alias_stats('aliases/');

	return @head_filters;
}

sub new
{
	my $class = shift;
	my $tail_filters = shift || [mk_tailfilters()];
	my $head_filters = shift || [mk_headfilters()];
	my ($tail_filter,$tail) = main_filter(@$tail_filters);
	my ($head_filter,$head) = main_filter(@$head_filters);
	my $this = {
		tailfilter => $tail_filter,
		tail => $tail,
		headfilter => $head_filter,
		head => $head,
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

# Signs of incorerct model
sub bad_model
{
	return [1000,sub {
		my $l=shift or return undef;
		$l=~/mutex_lock_interruptible/i and return {$DEFAULT=>'MODEL: mutex_lock_interruptible'};
		return undef;
	}];
}

# Signs of incorerct model
# We try to count number of cases where FAIL happens due to IN_INTERRUPT value being unset
#    Pred(IN_INTERRUPT  !=  0)
#    __blast_assert()
#  would be the vest sign of failure
sub bad_model_IN_INTERRUPT
{
	my $assert_means_fail = '';
	return [10000,sub {
		my $l=shift or return undef;
		$l=~/Pred.*IN_INTERRUPT.*0/i and do {$assert_means_fail = 1; return {$DEFAULT=>undef}; };
		$assert_means_fail and $l=~/__blast_assert/i and do {return {$DEFAULT=>'MODEL: IN_INTERRUPT unset!'}; };
		$assert_means_fail = '';
		return undef;
	}];
}

# out of memory via ulimit
sub oom_ulimit
{
	return [100,sub {
		my $l=shift or return undef;
		$l=~/out of memory/i and return {$DEFAULT=>'LIM: memory limit', 'BLAST'=>'LIM: memory limit'};
		return undef;
	}];
}

# out of memory via ulimit
sub time_limit
{
	return [100,sub {
		my $l=shift or return undef;
		$l=~/Time limit exceeded \((.*) sec/ and return {$DEFAULT=>"LIM: time limit ($1 sec)", 'BLAST'=>'LIM: time limit'};
		return undef;
	}];
}
 
sub safe_unsafe
{
	return [100,sub {
		my $l=shift or return undef;
		$l=~/The system is safe/ and return {$DEFAULT=>'AAAA: safe', 'BLAST'=>'YES'};
		$l=~/The system is unsafe/ and return {$DEFAULT=>'AAAA: unsafe', 'BLAST'=>'YES'};
		return undef;
	}];
}

sub exception
{
	return [20,sub {
		my $l=shift or return undef;
		$l=~/Ack! The gremlins again!: (.*)/ and return {$DEFAULT=>"ZZZ: Exception: $1", 'BLAST'=>'Exception'};
		return undef;
	}];
}

sub bad_simplify
{
	return [20,sub {
		my $l=shift or return undef;
		$l=~/(Simplify raised exception.*)/ and return {$DEFAULT=>"Z SIMPLIFY: $1"};
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

# The rest of code is from collect_reports script.  Maybe I'll use it some day.  TO_DELETE anyway

#int main()

#my $outfile = undef;
#my $alltraces = '';
## User-specified filters to be ran
#my @filters = ();
## User-specified headfilters to be ran
#my @headfilters = ();
## Additional .pm modules to be sources
#my @plugins = ();
## Section to dump to outfile
#my $dump_section = $DEFAULT;;
#
#my %opts=(
#	'outfile=s' => \$outfile,
#	'all-traces' => \$alltraces,
#	'filter=s' => \@filters,
#	'headfilter=s' => \@headfilters,
#	'plugin=s' => \@plugins,
#	'dump-section=s' => \$dump_section,
#);
#
#use Getopt::Long;
#
## Let's decide what filters we run.
## Assign default values first.
#my $tailfilters = sub { return mk_tailfilters(@_); };
#my $headfilters = sub { return mk_headfilters(@_); };
## If user has specified filters on the command-line, we should make our own functions.  Otherwise, use default.
#if (@filters){
#	# Attach plugins
#	load_plugin($_) for @plugins;
#	# Process comma-separated filters
#	@filters = split /,/,(join ",",@filters);
#	@headfilters = split /,/,(join ",",@headfilters);
#	# Maker function that returns subroutines like mk_tailfilters.
#	my $mkfilters = sub { 
#		my @filters = @_;
#		return sub{
#			my @result = ();
#			local $_;
#			for (@filters){
#				unshift @result,eval;
#				die if $@;
#			}
#			return @result;
#		}
#	};
#	# Make a function with them
#	$tailfilters = $mkfilters->(@filters);
#	$headfilters = $mkfilters->(@headfilters);
#}
#
## Get input file list
#my @files = @ARGV;
## If none found, read standard input
#@files = <> unless @files;
#
##Filter debug traces for filew who have normal
#if ($alltraces){
#	# List of normal traces
#	my %normal = ();
#	for my $fname (@files) {
#		$fname =~ /rep\.(?!debug\.)/ and $normal{$fname}=1;
#	}
#	# Now fetch those debug traces that don't have corresponding normal trace
#	# Stable filter!
#	my @newfiles = ();
#	for my $f (@files) {
#		my $nondebug = $f;
#		# Make normal name out of debug file name; if it failed, then it's a normal trace and should be added to list.
#		$nondebug =~ s/\.debug(?=\.)// or do {push @newfiles, $f; next};
#		# Add to list if normal trace doesn't exist
#		push @newfiles, $f unless exists $normal{$nondebug};
#	}
#	@files = @newfiles
#}
#
##Hash that stores results
#my %results = ();
#
## Pretty-printing percentage
#my $fnum = 0;
#my $total = scalar @files;
#my $step = 10; # step in percents
#my $tier = 0; # last printed percentage
## Traverse all files supplied
#for my $fname (@files){
#	$fnum++;
#	chomp $fname;
#	unless (-f $fname){
#		$results{$fname}='Does not exist';
#		next;
#	}
#	# Process file
#	$results{$fname} = unpack_and_process($fname,main_filter($tailfilters->()),main_filter($headfilters->()));
#	# Some interactiveness
#	# Close dangling filehandle if applicable
#	close $current_fh if $current_fh;
#	$current_fh=undef;
#}continue{
#		#Some pretty characters
#		print STDERR symb_for($results{$fname}->{$DEFAULT});
#		my $percent = int ($fnum/$total*100);
#		if ($percent - $tier >= $step ){
#			$tier = $percent;
#			print STDERR " $tier% ";
#		}
#}
#
#
#BEGIN { $SIG{'INT'} = sub { stats_print(); exit 1;};}
##Function to print statistics.
#sub stats_print
#{
#	# No files given.  Maybe, called incorrectly?
#	unless (scalar keys %results){
#		print STDERR "\nYou've specified no files in command line, neither have you supplied several to stdin!\nI'll do nothing.\n$usage\n";
#		exit 1;
#	}
#	# Some files are still unprocessed.
#	unless ($fnum == $total){
#		print STDERR "\nInterrrupted!\n"
#	}
#	# print number of files processed
#	print "\n$fnum out of $total files processed!\n\n\n";
#	# Print comprehensive stats to outfile
#	open my $OUTF, ">", $outfile or die;
#	for my $fname (keys %results){
#		printf $OUTF $fname." == ".($results{$fname}->{$dump_section} || 'UNKNOWN')."\n";
#	}
#	close $OUTF;
#
#	# Let's calculate histogram
#	# To calculate it with different categories, we construct a big array of tuples:
#	# 	[file,category,verdict]
#	# ...and then re-pach it in category->verdict->count hash.
#	# We also build category->count hash.
#	my @flat = ();
#	for my $filename (keys %results){
#		for my $category (keys %{$results{$filename}}){
#			my $verdict = $results{$filename}->{$category};
#			push @flat, [$filename,$category,$verdict] if defined $verdict;
#		}
#	}
#
#	# Collect statistics from @flat array into these:
#	my $histogram = {};
#	my $counts = {};
#
#	for my $item (@flat){
#		my ($filename,$category,$verdict) = @$item;
#		$histogram->{$category}->{$verdict}++;
#		$counts   ->{$category}            ++;
#	}
#
#
#	for my $category (sort keys %$histogram){
#		# Reference for less keystrokes
#		my $errors = $histogram->{$category};
#
#		#Print group statistics
#		print "\bGroup $category: ".$counts->{$category}.sprintf (" (%.1f",( $counts->{$category} / $fnum*100))."%)"." acknowledged out of ".$fnum. " total: \n";
#
#		# If less items belong to the category, than the overall amount of files, specify them as UNKNOWN.
#		$errors->{'UNKNOWN'} = $fnum - $counts->{$category} if $counts->{$category} < $fnum;
#
#		for my $bucket (sort keys %$errors){
#			# print bucket name, amount of files in it and percentage of total files _processed_ (not of amount of files that fall into this category)
#			print "\t$bucket -> $errors->{$bucket} (".(sprintf ("%.1f",( $errors->{$bucket} / $fnum*100)))."%)\n";
#		}
#
#		print "\n\n";
#
#	}
#	print <<END;
#
#More comprehensive stats are dumped into $outfile
#
#END
#}
#stats_print();

