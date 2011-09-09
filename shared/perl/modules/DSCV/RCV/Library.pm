package DSCV::RCV::Library;

use DSCV::RCV::Utils;

# Interface for the user-defined wrappers

# You should set context first (will alter global reference), and then the functions will access and alter the context.

use strict;
use vars qw(@ISA @EXPORT_OK @EXPORT);
# List here the functions available to the user (don't forget the & in front of them)
@EXPORT=qw(&preprocess_all_files &set_tool_name &add_time_watch &run &add_automaton &result);
use base qw(Exporter);

use LDV::Utils;
use StreamAutomaton;
use Utils;

use IO::Compress::Gzip qw($GzipError);
use IO::Select;
use IPC::Open3;
use File::Spec::Functions;

# Global context; altered by the user from the env
my $context = undef;

#======================================================================
# USER INTERFACE
#======================================================================

# Get temporary directory, specific to this launch.  It may not be visible by the other RCV launches, even of this very same driver with the other main!
sub get_tmp_dir 
{
	return $context->{tmpdir};
}

# Get a local name of an input file
sub local_name
{
	my ($name) = @_;
	return $context->{unbase}->($name);
}

sub get_all_c_files_with_options
{
	return [@{$context->{c_file_opt_list}}];
}

# Input: sequence of preprocessors.  Returns the list of files that exist on disk with the preprocessed code according to the options.  If a preprocessor error has occured, it throws an exception (so, no user code is executed), and places the error into the report.
# Available preprocessors: cpp (standard C preprocessor found on your system), cil (CIL preprocessor found on your system or in the LDV tools (see set_cil))
sub preprocess_all_files
{
	my @prep_seq = @_;

	local $_;

	# Load files and their options (list of small array refs)
	my $c_file_opt_list = get_all_c_files_with_options();
	# c_file_opt_list preserves the order of files; make a hash for faster access
	my $c_file_opt = {map {$_->[0] => $_->[1]} @$c_file_opt_list};
	# Make the list itself
	my $c_file_list = [map {$_->[0]} @$c_file_opt_list];

	# Preprocessing step (we don't want them to clash);
	my $prep_step = 1;

	# Preprocessing hash
	my %preps = (
		cpp => \&preprocess_cpp,
		cil => \&preprocess_cil,
		cil_merge => \&preprocess_cil_merge,
	);

	while (@prep_seq) {
		# Get preprocessor
		my $prep = shift @prep_seq;

		# Set the output directory
		my $out_dir = catfile(get_tmp_dir(),"preprocess","$prep_step-$prep");
		mkpath($out_dir);

		# Apply the preprocessor.  Get the new list of files and their options (which may be redundant).
		($c_file_list,$c_file_opt) = $preps{$prep}->($c_file_list,$c_file_opt,$out_dir);

		$prep_step += 1;
	}

	# Now, as all the preprocessing is finished, the resultant file list is what the user wanted.
	return @$c_file_list;
}

sub preprocess_cpp
{
	my ($c_file_list,$c_file_opt,$out_dir) = @_;

	my $result_list = [];
	my $result_opts = {};

	for my $c_file (@$c_file_list){
		my $local = local_name($c_file);
		vsay ('TRACE',"Preprocessing the driver's file: ".$local."\n");

		# Get the resultant file name
		my $i_file = $local;
		# Replace suffix (or add it)
		$i_file =~ s/\.c$/.i/ or $i_file.='.i';
		# Replace directories with dashes
		$i_file =~ s/\//-/g;
		# Put it into the proper folder
		$i_file = catfile($out_dir,$i_file);
		mkpath(dirname($i_file));

		# Get and adjust preprocessing options
		my %opts = %{$c_file_opt->{$c_file}};

		cpp_one_file(%opts, c_file => $c_file, i_file => $i_file) and do {
			vsay("WARNING", "PREPROCESS ERROR!  Terminating checker.\n");
			die "PREPROCESSING ERROR!";
		};

		# Adjust result
		push @$result_list, $i_file;
		$result_opts->{$i_file} = $c_file_opt->{$c_file};
	}

	return ($result_list, $result_opts);
}

sub set_cil
{
	Carp::confess "TODO";
}

sub set_limits
{
	my %limits = @_;
	$context->{limits} ||= {};
	local $_;
	$context->{limits}->{$_} = $limits{$_} for keys %limits;
}

sub add_time_watch
{
	my %timewatches = @_;
	$context->{timewatches} ||= {};
	local $_;
	$context->{timewatches}->{$_} = $timewatches{$_} for keys %timewatches;
}

sub set_tool_name
{
	my $name = shift;
	$context->{name} = $name;

	# Pop the previous instrument (a user might want to set it up several times!)
	LDV::Utils::pop_instrument();
	LDV::Utils::push_instrument($name);
}

my $automata_discarded = '';
my $automata_added = '';
# Runs the verifier, packaging the trace into the indexed trace file.
# May be called multiple times
sub run
{
	my @args = @_;
	local $_;

	my $timeout_idstr = "DSCV_TIMEOUT ";
	# Guard the command line with the timeout script
	my $time_pattern = join(',',map{ sprintf("%s,%s",$context->{timewatches}->{$_},$_) } keys %{$context->{timewatches}});
	@args = DSCV::RCV::Utils::set_up_timeout({
		timelimit => $context->{limits}->{timelimit},
		memlimit => $context->{limits}->{memlimit},
		pattern => $time_pattern,
		output => $context->{timestats_file},
		id_str => $timeout_idstr,
		},@args
	);
	# NOTE that the timestats file is common for several runs! This is done to get the statistics on all the runs in one place.

	vsay ('NORMAL',sprintf ("Running %s for %s, entry %s...",$context->{name},$context->{dbg_target}, join(", ",@{$context->{entries}})));
	vsay ('INFO',(map {($_ eq '')? '""' : $_} @args),"\n");

	# Determine the id of the current run.  We'll need it if we need several runs in one verification task.
	my $run_id = $context->{next_run_id}++;
	# Adjust the reports to have this number in them 
	my $target = $context->{dbg_target};
	my $debug_trace = catfile($context->{tmpdir},"runs","$target.$run_id.gz");


	# Open a pipe to the debug trace archiver.  It will run in a separate thread, and won't interfere with our automatons
	mkpath(dirname($debug_trace));
	open (my $DEBUG_TRACE, "| /bin/gzip -c >\Q$debug_trace") or die "Can't start gzip archiver: $!";

	vsay ('INFO',"The debug trace will be written to ".$debug_trace);

	# Add the default automata that check for time limits
	my $limit_automaton = StreamAutomaton::limits_check($timeout_idstr);
	# Prepare automatons for trace reading
	my $out_atmt = StreamAutomaton->new([],[],[@{$context->{stdout_automata}}]);
	my $err_atmt = StreamAutomaton->new([$limit_automaton],[],[@{$context->{stderr_automata}}]);

	# Warn user if he forgot to set up his automata
	vsay('WARNING',"\nNo user-supplied automatons present!  Didn't you forget that you should add_automaton() before each run()?\n\n") if ($automata_discarded and not $automata_added);

	# Prepare tail buffer
	$context->{tailbuf} = [];

	# Now open3 the commandline we have, and get the result
	my %child = Utils::open3_callbacks({
		# Stdout callback
		out => sub{ my $line = shift;
			$out_atmt->chew_line($line);
			print $DEBUG_TRACE $line;
		},
		# Stderr callback
		'err' => sub{ my $line = shift;
			$err_atmt->chew_line($line);
			print $DEBUG_TRACE $line;
		},
		close_out=>sub{ vsay ('TRACE',"Child's stdout stream closed.\n");},
		close_err=>sub{ vsay ('TRACE',"Child's stderr stream closed.\n");},
		},
		# Instrument call string
		@args
	);

	my $errcode = $?;
	vsay ('TRACE',"wait3 return value: $errcode\n");

	# Close gzipped trace
	close $DEBUG_TRACE;

	my $atmt_results = { %{$out_atmt->result()}, %{$err_atmt->result()}};

	# Adjust re
	my $result = 'OK';
	# Check if the signal interrupt was found, and adjust the retcode for it to have a single value
	$result = 'SIGNAL' if $errcode && 127;
	$errcode >>= 8;
	# Check if limits were violated
	$result = 'LIMITS' if $atmt_results->{'LIMITS'};

	# Prepare a description boilerplate
	my $descr = sprintf (<<EOR , ($atmt_results->{'LIMITS'} || "The verifier has completed in time"), $context->{limits}->{timelimit}, $context->{limits}->{memlimit});
=========== Launch information ===========
%s
Time Limit: %s
Memory Limit: %s
EOR

	# Prepare the result
	$context->{auto_description} = $descr;
	$context->{auto_result} = ($result eq 'OK')? 'OK' : 'FAILED';

	# Discard all the automatons, since they are now in final states.
	$context->{automata} = {};
	$automata_discarded = 1;

	return ($result, $errcode, $atmt_results, $debug_trace);

}

# Add stream automaton to the next run.  After the automata, you should specify one or more of strings 'stdout', 'stderr'.  The automata will be used to parse the streams you've specified for each of them.
# You HAVE TO create new automata and add them before EACH run!
sub add_automaton
{
	my ($atmt,@streams) = @_;

	# By default, just add to the both streams
	@streams = qw(stderr stdout) unless @streams;

	while (@streams){
		my $stream = shift @streams;
		if ($stream eq 'stderr'){
			push @{$context->{stderr_automata}}, [undef,$atmt];
		}elsif ($stream eq 'stdout'){
			push @{$context->{stdout_automata}}, [undef,$atmt];
		}
	}
}

# Send the result to the outer world
sub result
{
	my %results = @_;

	my $verdict = delete $results{verdict} or Carp::confess;
	my $trace_file = delete $results{error_trace};
	my $description = delete $results{description};

	# The rest of the results hash are the files to send to the parent

	# Postprocessing and checks
	$verdict = uc $verdict;
	if ($verdict eq 'UNSAFE' && !(-f $trace_file)){
		# TODO: maybe, we should not do this?..
		#die "INTEGRATION ERROR: no trace specified with an unsafe verdict!"
	}
	# Set status according to the verdict
	my $status = ($verdict eq 'UNKNOWN') ? 'FAILED' : 'OK';
	# Merge the automatically calculated description
	$description .= "\n".$context->{auto_description};

	# We only support one main!
	my $main = $context->{entries}->[0];

	# Get some standard results
	my $repT = XML::Twig::Elt->new('reports');

	my $cmdInstT = XML::Twig::Elt->new('ld',{'ref'=>$context->{cmd_id}, main=>$main});
	XML::Twig::Elt->new('trace',{},$trace_file)->paste($cmdInstT) if -f $trace_file;
	XML::Twig::Elt->new('verdict',{},$verdict)->paste($cmdInstT);
	# Confess who is responsible for that mess
	XML::Twig::Elt->new('verifier',{},$context->{engine})->paste($cmdInstT);

	my $rcvResultT = XML::Twig::Elt->new('rcv',{'verifier'=>$context->{engine}});
	XML::Twig::Elt->new('status',{},$status)->paste($rcvResultT);
	# Cleanup description a bit before pasting
	$description =~ s/^\s*//;
	$description =~ s/\s*$//;
	XML::Twig::Elt->new('desc',{},$description)->paste($rcvResultT);

	# Calculate and output time elapsed
	# Read file with time statistics
	# TODO: this is the hack for name generation.  A more generic mechanism should superseed it later.
	my $timestats_fname = $context->{timestats_file};
	if ( -f $timestats_fname && ! -z $timestats_fname) {
		my %timestats;

		# NOTE that we do not need the proper XML parsing here for the whole file, since it's not a valis XML (no single root).  However, we might benefit from XML-parsing the each string.

		local $_;
		open(STATS_FILE, '<', $timestats_fname) or die "Can't open file with time statistics: $timestats_fname, $!";
		while(<STATS_FILE>) {
			chomp;
			next unless $_;
			# Parse the string
			my $timeT = XML::Twig->parse($_)->root;

			/^\s*<time\s+name="(.*)"\s*>\s*([0-9\.]*)\s*<\/time>/ or next;
			
			$timestats{$timeT->att("name")} ||= 0;
			$timestats{$timeT->att("name")} += $timeT->text();
		}
		close STATS_FILE;
		for my $pat (keys %timestats) {
			XML::Twig::Elt->new('time',{name => $pat}, $timestats{$pat})->paste($rcvResultT);
		}
	} else {
		XML::Twig::Elt->new('time',{name => 'ALL'},0)->paste($rcvResultT);
	};

	# Add files to the parent (if there are any)
	local $_;
	for my $file_id (keys %results){
		my $files_for_id = (ref $results{$file_id} eq 'ARRAY') ? $results{$file_id} : [$results{$file_id}];
		# Add the files to the report
		my @existing_files = grep {-f $_} @$files_for_id;
		XML::Twig::Elt->new('file',{'tag' => $file_id},$_)->paste(last_child => $cmdInstT) for @existing_files;
		# Register files in the context
		$context->{files_to_send} ||= [];
		push @{$context->{files_to_send}},@existing_files;
	}

	# We should send the trace file as well
	push @{$context->{files_to_send}},$trace_file if -f $trace_file;

	$rcvResultT->paste(last_child =>$cmdInstT);
	$cmdInstT->paste($repT);

	$repT->set_pretty_print('indented');

	# We produce one report for each main file, because RCVs may be invoked concurrently
	open my $REPORT, ">", $context->{expect_report_at} or die "Can't open file $context->{expect_report_at}: $!";
	vsay('DEBUG',"Writing report to '$context->{expect_report_at}'\n");
	$repT->print($REPORT);
	close $REPORT;


}


#======================================================================
# BLAST-SPECIFIC ROUTINES
#======================================================================

#sub verify_blast
#{
	#my %args = @_;
	#$args{report} or die;
	## Since arguments alter depending on main, we should save them to temporary.
	#my %args_template = (%args);

	#for my $main (@{$args{mains}}){
		#%args = DSCV::RCV::Utils::args_for_main($main, %args_template);
		#if ($args{already_failed}){
			## Print at once, without spawning task through watcher
			#mkpath(dirname($args{report}));
			#open my $BLAST_REPORT, ">", $args{report} or die "Can't open file $args{report}: $!";
			#my $repT = XML::Twig::Elt->new('reports');

			## Prepare a failure command
			#my $cmdInstT = XML::Twig::Elt->new('ld',{'ref'=>$args{cmd_id}, main=>$main});
			#XML::Twig::Elt->new('trace',{},"")->paste($cmdInstT);
			#XML::Twig::Elt->new('verdict',{},'UNKNOWN')->paste($cmdInstT);

			## HACK: fix failure description, so that BLAST's parse errors and CPAchecker errors are not mingled
			#my $failmsg = $args{already_failed};

			#my $rcvResultT = XML::Twig::Elt->new('rcv',{'verifier'=>'blast'});
			#XML::Twig::Elt->new('status',{},'FAILED')->paste($rcvResultT);
			#XML::Twig::Elt->new('desc',{},$failmsg)->paste($rcvResultT);

			## Calculate and output time elapsed
			#XML::Twig::Elt->new('time',{'name'=>'ALL'},0)->paste($rcvResultT);

			#$rcvResultT->paste(last_child =>$cmdInstT);
			#$cmdInstT->paste($repT);

			## Commit the report
			#$repT->set_pretty_print('indented');
			#$repT->print($BLAST_REPORT);
			#close $BLAST_REPORT;

			## Report failure to the watcher
			## We should first allocate key (to keep the allocate/free balance)
			#my ($key_str,undef) = LDV::Utils::watcher_cmd('key','rcv');
			##vsay ('DEBUG',"Got key string $key_str.\n");
			##my @watcher_key = split /,/,$key_str;
			## But then we ignore this string, and use the watcher_key allocated by the parent DSCV for immediate success reporting
			#for_parent($args{report},$args{trace},$args{debug});
			#LDV::Utils::watcher_cmd('success','rcv',@{$config->{watcher_key}},'rcv',$args{cmd_id},$main,'@@',files_for_parent());


#======================================================================
# COMMON SUBROUTINES
#======================================================================

# Given a list of arguments to invoke child process, and limits specification, return a list of arguments t ocall timeout program shipped with LDV that watches for the resources.  As a side effect, modifies DSCV_TIMEOUT.

my $timeout = "$ENV{'DSCV_HOME'}/shared/sh/timeout";
-x $timeout or die "Executable timeout script needed but $timeout given!";

sub set_up_timeout
{
	my ($resource_spec, @cmdline) = @_;
	ref $resource_spec eq 'HASH' or Carp::confess;
	my $timelimit = $resource_spec->{timelimit};
	my $memlimit = $resource_spec->{memlimit};
	my $pattern = $resource_spec->{pattern};
	my $output = $resource_spec->{output};
	my $idstr = $resource_spec->{id_str};

	unshift @cmdline,"-t",$timelimit if $timelimit;
	unshift @cmdline,"-m",$memlimit if $memlimit;
	unshift @cmdline,"-p",$pattern if $pattern;
	unshift @cmdline,"-o",$output if $output;
	unshift @cmdline,"--just-kill" if $resource_spec->{kill_at_once};
	unshift @cmdline,$timeout if $timelimit || $memlimit;

	$ENV{'TIMEOUT_IDSTR'} = $idstr;

	return @cmdline;
}

use Cwd;
# Preprocesses file in the directory given with the options given.  Returns what call to C<system> returned.
# Usage:
# 	cpp_one_file( cwd=>'working/dir', i_file => 'output.i', c_file => 'input.c', opts=> ['-D','SOMETHING'] )
sub cpp_one_file
{
	my $info = {@_};
	# Change dir to cwd; then change back
	my $current_dir = getcwd();
	chdir $info->{cwd} or die;

	my @cpp_args = ("gcc","-E",
		"-o","$info->{i_file}",	#Output file
		"$info->{c_file}",	#Input file
		@{$info->{opts}},	#Options
	);
	vsay ('DEBUG',"Preprocessor: ",@cpp_args,"\n");
	local $"=' ';
	my $result = system @cpp_args; 

	chdir $current_dir;
	return $result;
}

# Makes file through CIL in the directory given with the options given.  Returns what call to C<system> returned.
# Usage:
# 	cilly_file(cil_path="toolset_dir/cil", cwd=>'working/dir', cil_file => 'output.i', i_file => 'input.c', opts=> ['-D','SOMETHING'] )
use LDV::Utils;
use IPC::Open3;
sub cilly_file
{
	my $info = {@_};
	my $cil_path = $info->{cil_path} or Carp::confess;
	#my $cil_script = "$cil_path/bin/cilly";
	my $cil_script = "$cil_path/obj/x86_LINUX/cilly.asm.exe";
	my $cil_temps = $info->{temps};
	mkpath($cil_temps) if $cil_temps;
	# Change dir to cwd; then change back
	my $current_dir = getcwd();
	chdir $info->{cwd} or Carp::confess;

	# Filter out "-c" from options -- we need just preprocessing from CIL
	my @opts = undef;
	if($info->{opts}) {
		@opts = @{$info->{opts}};
		@opts = grep {!/^-c$/} @opts;
	}

	my @extra_args = (#"-c",
		"$info->{i_file}",	#Input file
		"--out", "$info->{cil_file}",	#Output file
		# However, for cill to REALLY output the file, GCC's preprocessr at some stage should print it.  We need the following line:
		#"-o",$info->{cil_file},
		# Default CIL options
		# The option --dosimplify is doing annoying thing. It make pointers from explicit calls. So comment it
		#"--dosimplify",
		"--printCilAsIs",
		"--domakeCFG",
		#($info->{temps}?("--save-temps=$info->{temps}"):()),
		# User-supplied options
		# @opts,
		#"-U","__LP64__"
	);

	my @cil_args = ($cil_script);
	defined $info->{is_list} and push @cil_args,'--extrafiles';
	push @cil_args,@extra_args;

	# Add extra arguments
	push @cil_args,(split /\s+/,$ENV{'CIL_OPTIONS'});

	vsay ('DEBUG',"CIL: ",@cil_args,"\n");
	local $"=' ';
	my ($CIL_IN,$CIL_OUT,$CIL_ERR);
	my $fpid = open3($CIL_IN,$CIL_OUT,$CIL_ERR,@cil_args) or die "INTEGRATION ERROR.	Can't open3. PATH=".$ENV{'PATH'}." Cmdline: @cil_args";
	LDV::Utils::push_instrument("CIL");
	my $errors = '';
	while (<$CIL_OUT>) {
		vsay ("DEBUG",$_);
		# Cil prints errors to STDOUT as well :-(
		$errors.=$_;
	}
	while (<$CIL_ERR>) {
		print ("DEBUG",$_);
		$errors.=$_;
	}
	my $result = Utils::hard_wait($fpid,0);
	close $CIL_IN;
	close $CIL_OUT;
	LDV::Utils::pop_instrument();

	chdir $current_dir;
	return ($result, $errors);
}

#======================================================================
# GENERIC CC/LD COMMANDS
#======================================================================
# CC/LD in RCV backends represent information flow instead of actual commands.  The aim of "executing" CC and LD commands in multiple RCV calls is to determine what C files (from <in> tags of <cc> commands) constitute a linked shared object.  These and only these C files should be analyzed when an LD command is encountered.
#
# In this section we introduce the subroutines that provide this functionality.  The tool-specific functionality is supplied as a hook (Subroutine) given as an argument.  Some other options are available as well.

# Functor that returns a Twig handler, that, upon encountering a <basedir> sets up the proper basedir value and unbasedir subroutine
sub get_base_dir_maker
{
	my ($basedir_ref, $unbasedir_ref) = @_;
	return sub {
		my ($twig, $cmdT) = @_;
		$$basedir_ref = $cmdT->text();
		$$unbasedir_ref = Utils::unbasedir_maker($$basedir_ref);
	};
}

# Functor that returns a Twig handler for CC command.
# The handler flushes cmdfile related to CC to a <out> of CC command.  This file will be picked by LD handler.
# The functor takes ref to $unbasedir and $workdir, relative to which unbased o-file will be created.
use File::Basename;
use File::Path qw(mkpath);
sub cc_maker
{
	my ($unbasedir_ref,$workdir) = @_;
	return sub{
		my ($twig, $cmdT) = @_;
		# NOTE why ref is needed here,  The thing is that all Twig handlers are created via one XML::Twig->new call.  But at this point $unbasedir is empty, because it's fetched by another twig handler.  That's why we pass the reference to the maker.
		my $unbasedir = $$unbasedir_ref;
		# Flush the list of all .c files to the .o file being checked
		local $_;
		my @c_files_raw = $unbasedir->($cmdT->children_text('in'));
		my $o_file_raw = $unbasedir->($cmdT->first_child_text('out'));
		my $o_file = "$workdir/$o_file_raw";

		# Write the list to o-file
		mkpath(dirname($o_file));

		vsay ('DEBUG', "Saving cc command to '$o_file'\n");
		my $children_FH; open $children_FH,">",$o_file or die "Dead while trying to open $o_file for writing";
		$cmdT->print($children_FH);
		close $children_FH;
	};
}

# Repack file names...  Don't ask for correct specs -- it's too hacky.
sub fnamerepack
{
	my ($basedir,$rel,$fname,$sub) = @_;
	vsay ('TRACE',"based: $basedir\n");
	vsay ('TRACE',"fname: $fname\n");
	my ($base,$rel) = $fname =~ /^(\Q$basedir\E)\/(.*)/;
	vsay ('TRACE',"base: $base\n");
	vsay ('TRACE',"rel : $rel\n");
	unless (defined $base){
		vsay ('TRACE',"unbased: $rel\n");
		my ($base) = $fname =~ /^(.*?)\/*(\Q$rel\E)$/;
		vsay ('TRACE',"base_xx: $base\n");
		die unless defined $base;
	}
	vsay ('TRACE',"rel_pr: $rel\n");
	$rel = $sub->($rel);
	vsay ('TRACE',"rel_xx: $rel\n");
	return "$basedir/$rel";
}

# Functor that returns a Twig handler for LD command.
# The handler flushes cmdfile related to CC to a <out> of CC command.  This file will be picked by LD handler.
# The functor takes ref to $unbasedir and $workdir, relative to which unbased o-file will be created.
# The sub returned may die if it encounters a critical error or critical sanity check violation
sub ld_maker
{
	my %args = @_;

#	foreach (keys %args) { print "DEBUG_FILES_2: $_\n"; }

	my $do_preprocess = $args{preprocess};
	$do_preprocess = 1 unless exists $args{preprocess};
	my $do_cilly = $args{cilly} || '';
	my $do_cilly_once = $args{cilly_once} || '';
	my $cil_temps = $args{cil_temps} || '';
	my $cil_path = $args{cil_path} || '';
	my $unbasedir_ref = $args{unbasedir_ref};
	my $workdir = $args{workdir};
	my $verify = $args{verifier};
	my $archivated = $args{archivated} || '';
	# Flag that CIL file list from the previous run was removed (or not found)
	my $old_cil_file_list_checked = 0;

	return sub{
		my ($twig, $cmdT) = @_;

		# Get file names
		my $unbasedir = $$unbasedir_ref;
		# Get the list of c files for current linked file
		# We assume that each c-file is included into any executable file only once (otherwise there would have been undefined references).
		local $_;
		my @o_files_raw = map {$unbasedir->($_)} $cmdT->children_text('in');
		my $target = $unbasedir->($cmdT->first_child_text('out'));
		
		# First we set up all options for running verification command

		# If preprocessing or CIL-ling fails, we should report it in a sane way.  This variable is passed to the $verify command given
		my $fail = undef;
		# See cc_maker for reasons why a ref is required here
		# Get hints tag first 
		my $hintsT = $cmdT->first_child('hints');
		# Get entry points
		my @mains = $cmdT->children_text('main');
		@mains or vsay("WARNING", "No mains specified for file ".$cmdT->first_child_text('out')."\n");
		# List of error locations
		my @errlocs = $cmdT->children_text('error');
		# Report file (%s will be replaced with main name)
		my $report = reports_dir($workdir)."/$target.%s.report";
		# Tool debug file (to dump the trace of the tool)
		my $debug = reports_dir($workdir)."/$target.%s.debug";
		$debug.=".gz" if $archivated;
		# Trace file (to dump the error trace)
		my $trace = reports_dir($workdir)."/$target.%s.trace";
		# Time stats file
		my $timestats = reports_dir($workdir)."/$target.%s.timestats.xml";

		# Common arguments for the verifier command
		my %common_vercmd_args = (cmd_id=>$cmdT->att('id'), hints=>$hintsT, mains=>\@mains, errlocs=>\@errlocs, report=>$report, trace=>$trace, debug=>$debug, dbg_target=>$target, workdir=>$workdir, timestats=>$timestats);

		# Informaiton about C files should be a reference, for it to be accessible from within subs
		my $c_files_info = [];
		# List of c files that were processed.  Used in tracking the assersion that each c file is processed only once.  Value is an o-file, in which the c file was first encountered.
		my %c_files_Sanity = ();
		for my $o_file_raw (@o_files_raw){
			# From each o-file local copy, which contains list of c-files in that object one, get these files
			my $o_file = Utils::relpath($workdir,$o_file_raw);

			# Get information about this object file
			my $c_files = [];
			# Compiler options to build this particular o-file.  We *know* that there's only *one* command in this file, so there's no need to distpatch this level as well.
			my $aux_opts = [];
			my $cwd = undef;
			my $obj_file = undef;
			XML::Twig->new( twig_handlers=> {
				'opt' => sub { push @$aux_opts,$_[1]->text(); },
				# Input files are taking without change
				'in' => sub { push @$c_files,$_[1]->text(); },
				# Output files are tuned to be in-rcv
				'out' => sub { $$obj_file = Utils::relpath($workdir,$unbasedir->($_[1]->text())); },
				'cwd' => sub { $$cwd = $_[1]->text(); },
			})->parsefile($o_file);

			# Clear some temporary files that might be left from the previous run
			my $cilly_dir = "$workdir/cilly";
			my $cil_extra_files_list = "$cilly_dir/cil_extrafiles.list";
			if (-f $cil_extra_files_list && !$old_cil_file_list_checked){
				vsay 'DEBUG', "CIL file list found from previous run in '$cil_extra_files_list'; removing.";
				unlink $cil_extra_files_list;
			}
			# we've dealt with a residue of an old file list (if it was there) already, set the flag.
			$old_cil_file_list_checked = 1;
			# Propagate the information gathered to c_files_info arrays
			local $_;
			for my $c_file (@$c_files){
				# Sanity check
				my $c_file_already_encountered = $c_files_Sanity{$c_file};
				defined $c_file_already_encountered and die "C file $c_file is used twice, when linking $target: in $c_file_already_encountered and $$obj_file"; 
				$c_files_Sanity{$c_file} = $$obj_file; 

				# Prepare record
				my $new_record = {c_file=>$c_file, opts=>$aux_opts, cwd=>$$cwd};

				# Preprocess file if necessary
				# record->{i_file} holds "the file after preprocessing", not just a "prepricessed file".
				if ($do_preprocess){
					my $preprocess_dir = "$workdir/preprocessed";
					mkpath($preprocess_dir);
					#my $i_file = $c_file; #$i_file =~ s/\.c$/.i/; $i_file =~ s/\//-/g; $i_file = "$preprocess_dir/$i_file";
					vsay (100,"ubsd: ".$unbasedir->($c_file)."\n");
					my $i_file = fnamerepack($workdir,$unbasedir,$c_file,
						sub{ $_[0] =~ s/\.c$/.i/; $_[0] =~ s/\//-/g; $_[0] = "preprocessed/$_[0]"; return $_[0]; }
					);
					mkpath(dirname($i_file));
					$new_record->{i_file} = $i_file;
					preprocess_file(%$new_record) and do { vsay("WARNING", "PREPROCESS ERROR!  Terminating checker.\n"); $fail = "PREPROCESS ERROR."; return $verify->(%common_vercmd_args, already_failed=>$fail);  };
				}else{
					$new_record->{i_file} = $new_record->{c_file};
				}

				# Make file through CIL if necessary
				# record->{i_file} holds "the file after preprocessing", so use it as input.  Output to {cil_fil}, but copy it back to {i_file}.
				if ($do_cilly){
					mkpath($cilly_dir);
					#my $cil_file = $new_record->{i_file}; $cil_file =~ s/\.[^.]*$/.cilf.c/; $cil_file =~ s/\//-/g; $cil_file = "$cilly_dir/$cil_file";
					if($do_cilly_once) {
						vsay 'DEBUG', "Add new file to \"$cilly_dir/cil_extrafiles.list\"\n";
						open FILE,">>",$cil_extra_files_list or die "Can' open new cillist file: $!";
						print FILE $new_record->{'i_file'}."\n";
						close FILE or die "Can't close cillist file: $!";
					} else {
						my $cil_file = fnamerepack($workdir,$unbasedir,$new_record->{i_file},
							sub { my $cil_file = $_[0]; $cil_file =~ s/\.[^.]*$/.cilf.c/; $cil_file =~ s/\//-/g; $cil_file = "cilly/$cil_file"; return $cil_file}
						);
						mkpath(dirname($cil_file));
						$new_record->{cil_file} = $cil_file;
						my (undef, $error) = cilly_file(%$new_record, cil_path=>$cil_path, temps=>$cil_temps);
						my $cil_result = $? >> 8;
						vsay ("DEBUG","CIL exit code is $cil_result\n");
						$? and do { vsay("WARNING", "CIL ERROR!  Terminating checker.\n"); $fail = "CIL ERROR.  Output:\n$error"; return $verify->(%common_vercmd_args, already_failed=>$fail);  };
					}
				}else{
					$new_record->{cil_file} = $new_record->{i_file};
				}

				$new_record->{i_file} = $new_record->{cil_file};
				
				$do_cilly_once or push @$c_files_info, $new_record;
			}
		}
		if($do_cilly_once) {
			my $new_record = {cil_file=>"$workdir/cilly/out.cilf.c", i_file=>"$workdir/cilly/cil_extrafiles.list", cwd=>"$workdir/cilly/"};
			my (undef, $error) = cilly_file(%$new_record, cil_path=>$cil_path, temps=>$cil_temps, is_list=>1);
			my $cil_result = $? >> 8;
			vsay ("DEBUG","CIL exit code is $cil_result\n");
			$? and do { vsay("WARNING", "CIL ERROR!  Terminating checker.\n"); $fail = "CIL ERROR.  Output:\n$error"; return $verify->(%common_vercmd_args, already_failed=>$fail);  };
			$new_record->{i_file} = $new_record->{cil_file};
			push @$c_files_info, $new_record;
		}

		# Call the verifier for all of the preprocessed c-files gotten at once, and and supply the additional arguments fetched from the tag record.

		# Get list of files to analyze:
		my @files = map {$_->{i_file}} @$c_files_info;
		$do_cilly_once and @files = "$workdir/cilly/out.cilf.c";

		ensure_args_folders(%common_vercmd_args);
		$verify->(%common_vercmd_args, files => \@files);

	};
}

sub ensure_args_folders
{
	my %args = @_;
	mkpath(dirname($args{report}));
	mkpath(dirname($args{debug}));
	mkpath(dirname($args{trace}));
	mkpath(dirname($args{timestats}));
}

# Given main name and arguments array, returns arguments unique for that name
sub args_for_main
{
	my ($main,%args) = @_;
	my %new_args = (%args);

	local $_;
	$new_args{$_} = sprintf ($args{$_},$main) for qw(debug trace timestats report);
	return %new_args;
}

#======================================================================
# WRAPPER INTERFACE
#======================================================================

# Given a task, set the context
sub set_context
{
	my %task = @_ or Carp::confess;

	my $ctx = {
		'basedir' => undef,
		'c_file_opt_list' => [],
		'tmpdir' => $task{workdir},
		'limits' => {},
		'timewatches' => {'ALL'=>'.*'},
		'name' => 'verifier',
		'dbg_target' => undef,
		'next_run_id' => 1,
		'timestats_file' => undef,
		'entry' => undef,
		'stderr_automata' => [],
		'stdout_automata' => [],
		'engine' => undef,
	};

	my $process_basedir = sub{
		my ($twig,$cmdT) = @_;
		$ctx->{basedir} = ($cmdT->text);
	};
	my $process_cc = sub{
		my ($twig,$cmdT) = @_;
		for my $c_file ($cmdT->children_text('in')){
			push @{$ctx->{c_file_opt_list}}, [$c_file,{opts => [$cmdT->children_text('opt')], cwd => $cmdT->first_child_text('cwd')}];
		}
	};

	# Get the XPath expression for the interesting <cc> and <ld> commands
	my $ld_xpath = sprintf 'ld[@id = "%d"]', $task{cmd_id};
	local $_;
	# NOTE: %s instead of %d as cc_ids are not necessarily numbers
	my $cc_xpath = 'cc['.(join(' or ',map{sprintf('@id = "%s"',$_)} @{$task{cc_ids}})).']';
	# We parse the cmdstream and gather options
	XML::Twig->new( twig_handlers => { $cc_xpath => $process_cc, basedir=>$process_basedir })->parsefile($task{cmdfile});

	# Prepare file name utils
	$ctx->{unbase} = Utils::unbasedir_maker($ctx->{basedir});

	# Ensure dirs
	mkpath($ctx->{tmpdir});
	-d $ctx->{tmpdir} or die "Can't make workdir '$ctx->{tmpdir}'";

	# Misc
	$ctx->{dbg_target} = $task{dbg_target};
	$ctx->{timestats_file} = $task{timestats};
	$ctx->{entries} = [@{$task{mains}}];
	$ctx->{expect_report_at} = $task{report};
	$ctx->{cmd_id} = $task{cmd_id};
	$ctx->{engine} = $task{engine};

	# push default instrument (see the code of set_tool_name)
	LDV::Utils::push_instrument('verifier');

	$context = $ctx;
}

1;

