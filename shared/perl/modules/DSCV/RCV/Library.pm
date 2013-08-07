################################################################################
# Copyright (C) 2011-2012
# Institute for System Programming, Russian Academy of Sciences (ISPRAS).
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################
package DSCV::RCV::Library;

use DSCV::RCV::Utils;

# Interface for the user-defined wrappers

# You should set context first (will alter global reference), and then the functions will access and alter the context.

use strict;
use vars qw(@ISA @EXPORT_OK @EXPORT);
# List here the functions available to the user (don't forget the & in front of them)
@EXPORT=qw(&preprocess_all_files &set_tool_name &add_time_watch &run &add_automaton &result &tail_automaton &set_limits &set_cil_options);
use base qw(Exporter);

use LDV::Utils;
use StreamAutomaton;
use Utils;

use IO::Compress::Gzip qw($GzipError);
use IO::Select;
use IPC::Open3;
use File::Basename;
use File::Path qw(mkpath);
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
	# You can't do CIL-merge without preprocessing!
sub preprocess_all_files
{
	my @prep_seq = @_;

	vsay ("INFO",sprintf("Will use preprocessors: %s",join(", ",@prep_seq)));

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
		'cil-merge' => \&preprocess_cil_merge,
	);

	# You can't do CIL-merge without preprocessing individual files!
	my $cpp_ed = '';

	my $basedir = $context->{basedir};

	while (@prep_seq) {
		# Get preprocessor
		my $prep = shift @prep_seq;

		vsay ("NORMAL",sprintf("Preprocessing %d files with %s",(scalar @$c_file_list),$prep));

		# Check sanity
		die "Before you CIL-merge, you should preprocess inidividual files with CIL or CPP" if ((($prep eq 'cil_merge') || ($prep eq 'cil-merge')) && !$cpp_ed);
		$cpp_ed = 1;

		# Set the output directory
		my $out_dir = catfile(get_tmp_dir(),"preprocess","$prep_step-$prep");
		mkpath($out_dir);

		# Apply the preprocessor.  Get the new list of files and their options (which may be redundant).
		die(sprintf("Unknown preprocessor '$prep'.  You should specify one of: %s!",join(", ",keys %preps))) unless exists $preps{$prep};
		($c_file_list,$c_file_opt) = $preps{$prep}->($c_file_list,$c_file_opt,$out_dir,$basedir);

		# Adjust basedir, since on the next step we will have to strip the new path prefixes
		$basedir = $out_dir;

		$prep_step += 1;
	}

	# Now, as all the preprocessing is finished, the resultant file list is what the user wanted.
	return @$c_file_list;
}

# Check if the exception thrown is a preprocessing error
sub is_preprocess_error
{
	my $excn = shift;
	return $excn =~ /^PREPROCESS ERROR|^CIL ERROR/;
}

sub preprocess_cpp
{
	my ($c_file_list,$c_file_opt,$out_dir,$base) = @_;

	my $result_list = [];
	my $result_opts = {};

	for my $c_file (@$c_file_list){
		my $local = Utils::unbase($base,$c_file);
		vsay ('TRACE',"Preprocessing the driver's file: ".$local."\n");

		# Get the resultant file name
		my $i_file = $local;
		# Replace suffix (or add it)
		$i_file =~ s/\.c$/.i/ or $i_file.='.i';
		# Replace directories with dashes
		# Do not do this since a file name can exceed a maximum length
		# (see issue #3198)
		# $i_file =~ s/\//-/g;
		# Put it into the proper folder
		$i_file = catfile($out_dir,$i_file);
		mkpath(dirname($i_file));

		# Get and adjust preprocessing options
		my %opts = %{$c_file_opt->{$c_file}};

		my ($errcode, @answer) = cpp_one_file(%opts, c_file => $c_file, i_file => $i_file);
		if ($errcode != 0) {
			vsay("WARNING", "PREPROCESS ERROR!  Terminating checker.\n");
			# Add the discriminator that it's a preprocess error trace to the description
			unshift @answer,"PREPROCESS ERROR!\n";
			$context->{preproces_error_log} = [@answer];
			die "PREPROCESS ERROR!";
		};

		# Adjust result
		push @$result_list, $i_file;
		$result_opts->{$i_file} = $c_file_opt->{$c_file};
	}

	return ($result_list, $result_opts);
} 

sub preprocess_cil
{
	my ($c_file_list,$c_file_opt,$out_dir,$base) = @_;

	my $result_list = [];
	my $result_opts = {};

	for my $c_file (@$c_file_list){
		my $local = Utils::unbase($base,$c_file);
		vsay ('TRACE',"Preprocessing with CIL the driver's file: ".$local."\n");

		# Get the resultant file name
		my $i_file = $local;
		# Replace suffix (or add it)
		$i_file =~ s/\.c$/.cil.i/ or $i_file.='.cil.i';
		# Replace directories with dashes
		# Do not do this since a file name can exceed a maximum length
		# (see issue #3198)
		# $i_file =~ s/\//-/g;
		# Put it into the proper folder
		$i_file = catfile($out_dir,$i_file);
		mkpath(dirname($i_file));

		# NOTE that in this script the preprocessing is ignored!  The options are replaced with the user-specified options!
		# Get and adjust preprocessing options
		my %opts = %{$c_file_opt->{$c_file}};
		# Add common CIL options set up by user
		$opts{opts} = $context->{cil_options};

		my $cil_temps = "$i_file-tmpdir";
		mkpath($cil_temps);

		my ($errcode, @answer) = cil_one_file(%opts, cil_script => $context->{cil_script}, temps=>$cil_temps, c_file => $c_file, i_file => $i_file);
		if ($errcode != 0) {
			vsay("WARNING", "CIL ERROR!  Terminating checker.\n");
			# Add the discriminator that it's a preprocess error trace to the description
			unshift @answer,"CIL ERROR!\n(Didn't you forget to turn CPP before CIL?)";
			$context->{preproces_error_log} = [@answer];
			die "CIL ERROR!";
		};

		# Adjust result
		push @$result_list, $i_file;
		$result_opts->{$i_file} = $c_file_opt->{$c_file};
	}

	return ($result_list, $result_opts);
}

sub preprocess_cil_merge
{
	my ($c_file_list,$c_file_opt,$out_dir,$base) = @_;

	my $result_list = [];
	my $result_opts = {};

	# Make an extrafile-list from the input files.
	my $cil_efl = "$out_dir/cil_extrafiles.list";
	my $cil_out = "$out_dir/cil.out.i";
	my $cil_temps = "$out_dir/cil_extrafiles.list-tmpdir";

	mkpath(dirname($cil_efl));
	mkpath($cil_temps);

	open FILE,">",$cil_efl or die "Can' open new cillist file '$cil_efl': $!";
	print FILE $_."\n" for @$c_file_list;
	close FILE or die "Can't close cillist file '$cil_efl': $!";
	
	vsay ('DEBUG',`cat $cil_efl`);
	vsay ('DEBUG',"Will merge all files with CIL into $cil_out\n");
	# Note the is_list setting that means we're preprocessing a list instead of one file
	my ($errcode, @answer) = cil_one_file(cwd=>$out_dir, cil_script => $context->{cil_script}, temps=>$cil_temps, c_file => $cil_efl, i_file => $cil_out, is_list => 1, opts=>$context->{cil_options});
	if ($errcode != 0) {
		vsay("WARNING", "CIL ERROR!  Terminating checker.\n");
		# Add the discriminator that it's a preprocess error trace to the description
		unshift @answer,"CIL ERROR!\n";
		$context->{preproces_error_log} = [@answer];
		die "CIL ERROR!";
	};

	return ([$cil_out], {$cil_out => { cwd => $out_dir, opts => []}});
}

sub set_cil
{
	$context->{cil_script} = shift or Carp::confess;
}

sub set_cil_options
{
	$context->{cil_options} = [@_] or Carp::confess;
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
	my $time_pattern = join(';',map{ sprintf("%s,%s",$context->{timewatches}->{$_},$_) } keys %{$context->{timewatches}});
	@args = DSCV::RCV::Utils::set_up_timeout({
		timelimit => $context->{limits}->{timelimit},
		memlimit => $context->{limits}->{memlimit},
		#pattern => $time_pattern,
		output => $context->{timestats_file},
		id_str => $timeout_idstr,
		kill_at_once => $context->{limits}->{kill_at_once},
		ldvdir => 'ldv'
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

	# Discard "undef" results and merge hashes
	my %out_atmt_results = %{$out_atmt->result()};
	do {delete $out_atmt_results{$_} unless defined $out_atmt_results{$_}} for keys %out_atmt_results;
	my %err_atmt_results = %{$err_atmt->result()};
	do {delete $err_atmt_results{$_} unless defined $err_atmt_results{$_}} for keys %err_atmt_results;

	my $atmt_results = { %out_atmt_results, %err_atmt_results};

	# Adjust result
	my $result = 'OK';
	my $mes = "";
	my $timestats_fname = $context->{timestats_file};
	my %timestats;
	if ( -f $timestats_fname && ! -z $timestats_fname) {
		
		%timestats = parse_outputfile(outputfile => $timestats_fname);
		$errcode = $timestats{"exit_script"};
		if ($timestats{"memory_exhausted"} == "1")
		{
			$result = 'LIMITS';
			$mes = "Memory exhausted";
		}
		if ($timestats{"time_exhausted"} == "1")
		{
			$result = 'LIMITS';
			$mes = "Time exhausted";
		}
		if ($timestats{"signal_script"} > 0)
		{
			$result = 'SIGNAL';
		}
	}
	# Check if the signal interrupt was found, and adjust the retcode for it to have a single value
	#$result = 'SIGNAL' if $errcode && 127;
	#$errcode >>= 8;
	# Check if limits were violated
	#$result = 'LIMITS' if $atmt_results->{'LIMITS'};

	# Just say something to the user
	vsay('NORMAL',sprintf("Finished with code %d term by %s. %s",$errcode,$result,$mes));

	# Prepare a description boilerplate
	# NOTE that we _rewrite_ the description if it's not the first run!  Motivation: if the first run has failed due to an artificially set up time limit, we do not want this time limit message to get into the final report.
	
	my @out = get_result_from_file(outputfile => $timestats_fname);
	my $descr = sprintf (<<EOR , $out[0], $out[1], $out[2], $out[3], $out[4], $out[5], $out[6] || "");
===============================================
%s
%s
%s
%s
%s
%s
%s
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

sub get_result_from_file
{
	my $info = {@_};
	my $timestats_fname = $info->{outputfile};
	local $_;
	open(STATS_FILE, '<', $timestats_fname) or die "Can't open file with time statistics: $timestats_fname, $!";
	my $command_type = "0";
	my @result_string;
	my $i = 0;
	while(<STATS_FILE>) {
		chomp;
		next unless $_;
		my @words = split(' ', $_);
		if ($words[1] eq "manager" && $words[2] eq "execution")
		{
			$command_type = "1";
		}
		if ($words[0] eq "Command" && $words[1] eq "execution")
		{
			$command_type = "2";
		}
		if ($words[0] eq "Time" && $words[1] eq "usage")
		{
			$command_type = "3";
		}
		if ($command_type eq "0")
		{
			if ($words[0] ne "command:" && $words[0] ne "cgroup" && $words[0] ne "outputfile:")
			{
				$result_string[$i++] = $_;
			}
		}
		if ($command_type eq "2")
		{
			$result_string[$i++] = $_;
		}
	}
	close STATS_FILE;
	return @result_string;
}

#function for parse output file from res_manager
sub parse_outputfile
{
	my $info = {@_};
	my $outputfile = $info->{outputfile};
	my %statistics;
	local $_;
	open(STATS_FILE, '<', $outputfile) or die "Can't open file with time statistics: $outputfile, $!";
	my $return_code_section = "0"; # 0 - don't parse section; 1 - for res_manager; 2 - for command
	my $signal_section = "0"; # 0 - don't parse section; 1 - for res_manager; 2 - for command
	while(<STATS_FILE>) {
		chomp;
		next unless $_;
		my @words = split(" ", $_);
		
		if ($words[1] eq "manager" && $words[2] eq "execution")
		{
			$return_code_section = "1";
			$signal_section = "1";
		}
		if ($words[0] eq "Command" && $words[1] eq "execution")
		{
			$return_code_section = "2";
			$signal_section = "2";
		}
		if ($words[0] eq "exit" && $return_code_section eq "1")
		{
			$statistics{"exit_code_script"} += $words[2];
		}
		if ($words[0] eq "exit" && $return_code_section eq "1")
		{
			$statistics{"exit_code"} += $words[2];
		}
		if ($words[0] eq "killed" && $signal_section eq "2")
		{
			$statistics{"signal_script"} += $words[3];
		}
		if ($words[0] eq "killed" && $signal_section eq "2")
		{
			$statistics{"signal"} += $words[3];
		}
		if ($words[0] eq "memory" && $words[1] eq "exhausted")
		{
			$statistics{"memory_exhausted"} += "1";
		}
		if ($words[0] eq "time" && $words[1] eq "exhausted")
		{
			$statistics{"time_exhausted"} += "1";
		}
		if ($words[1] eq "time:")
		{
			if ($words[0] eq "cpu")
			{
				$statistics{"ALL"} += int($words[2]);
			}
			else
			{
				$statistics{$words[0]} += int($words[2]);
			}
		}
		if ($words[0] eq "peak")
		{
			$statistics{$words[1]} += int($words[3] / 1000);
		}
	}
	close STATS_FILE;
	return %statistics;
}


# Send the result to the outer world
sub result
{
	my %results = @_;

	my $verdict = undef;
	my $description = undef;

	# Handle preprocessing error
	if (delete $results{_preprocess_failure}){
		$verdict = 'unknown';
		# Log comes here unchomped; do not insert linebreaks
		$description = join("",@{$context->{preproces_error_log}});
	}elsif( my $excn = delete $results{_user_exception}){
		$verdict = 'unknown';
		# NOTE: this should match the problem description in ldv-manager/problems/rcv/generic
		$description = "VERIFIER SCRIPT ERROR\n".$excn."\n";
	}

	$verdict ||= delete $results{verdict};
	defined $verdict or Carp::confess;
	$description ||= delete $results{description};
	my $trace_file = delete $results{error_trace};

	# The rest of the results hash are the files to send to the parent (see below)

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
		
		my %timestats = parse_outputfile(outputfile => $timestats_fname);
		
		for my $pat (keys %timestats) 
		{
			if ($pat eq "ALL" || $pat eq "wall" || $pat eq "system" || $pat eq "user")
			{
				XML::Twig::Elt->new('time',{name => $pat}, $timestats{$pat})->paste($rcvResultT);
			}
			if ($pat eq "memory")
			{
				XML::Twig::Elt->new('time',{name => $pat}, $timestats{$pat})->paste($rcvResultT);
			}
		}
	} else {
		XML::Twig::Elt->new('time',{name => 'ALL'},0)->paste($rcvResultT);
	};

	# Add files to the parent (if there are any)
	$context->{files_to_send} ||= [];
	local $_;
	for my $file_id (keys %results){
		my $files_for_id = (ref $results{$file_id} eq 'ARRAY') ? $results{$file_id} : [$results{$file_id}];
		# Add the files to the report
		my @existing_files = grep {-f $_} @$files_for_id;
		XML::Twig::Elt->new('file',{'tag' => $file_id},$_)->paste(last_child => $cmdInstT) for @existing_files;
		# Register files in the context
		push @{$context->{files_to_send}},@existing_files;
	}
	# We should send the trace file as well
	if (-f $trace_file){
		push @{$context->{files_to_send}},$trace_file;
		# Also, check what files are needed by the ETV to visualize the trace, and send them as well
		push @{$context->{files_to_send}},add_files_for_trace($trace_file);
	}

	$rcvResultT->paste(last_child =>$cmdInstT);
	$cmdInstT->paste($repT);

	$repT->set_pretty_print('indented');

	# We produce one report for each main file, because RCVs may be invoked concurrently
	open my $REPORT, ">", $context->{expect_report_at} or die "Can't open file $context->{expect_report_at}: $!";
	vsay('DEBUG',"Writing report to '$context->{expect_report_at}'\n");
	$repT->print($REPORT);
	close $REPORT;

	# Send the report file as well
	push @{$context->{files_to_send}},$context->{expect_report_at};

}


#======================================================================
# COMMON SUBROUTINES
#======================================================================

# Given a list of arguments to invoke child process, and limits specification, return a list of arguments t ocall timeout program shipped with LDV that watches for the resources.  As a side effect, modifies DSCV_TIMEOUT.

my $timeout = "$ENV{'DSCV_HOME'}/bin/res-manager";

sub set_up_timeout
{
	my ($resource_spec, @cmdline) = @_;
	ref $resource_spec eq 'HASH' or Carp::confess;
	my $timelimit = $resource_spec->{timelimit};
	my $memlimit = $resource_spec->{memlimit};
	#my $pattern = $resource_spec->{pattern};
	my $output = $resource_spec->{output};
	my $idstr = $resource_spec->{id_str};

	unshift @cmdline,"-t",$timelimit if $timelimit;
	unshift @cmdline,"-m",$memlimit if $memlimit;
	#unshift @cmdline,"-p",$pattern if $pattern;
	unshift @cmdline,"-o",$output if $output;
	unshift @cmdline,"-k" if $resource_spec->{kill_at_once};
	unshift @cmdline,"-l", 'ldv';
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

	LDV::Utils::push_instrument("cpp");

	# We add "-x c" here to make GCC preprocess the input file even if it ends with ".i" suffix.  By default, GCC doesn't preprocess such files.  Moreover, we can't use the bare "cpp" here, as the options are for gcc compiler, and the bare preprocessor will report errors.
	my @cpp_args = ("gcc","-E","-x","c",
		"-o","$info->{i_file}",	#Output file
		"$info->{c_file}",	#Input file
		@{$info->{opts}},	#Options
	);

	# Measure time of CPP as well.  Add it to the common timestat file.
	@cpp_args = DSCV::RCV::Utils::set_up_timeout({
		pattern => '.*,CPP',
		output => $context->{timestats_file},
		},@cpp_args
	);
	vsay ('DEBUG',"Preprocessor: ",@cpp_args,"\n");
	local $"=' ';
	my @prep_err;
	my %child = Utils::open3_callbacks({
		# Stdout callback
		out => sub{},
		# Stderr callback
		'err' => sub{ my $line = shift;
			push @prep_err,$line;
			vsay("DEBUG",$line);
		},
		close_out=>sub{ vsay ('TRACE',"CPP's stdout stream closed.\n");},
		close_err=>sub{ vsay ('TRACE',"CPP's stderr stream closed.\n");},
		},
		# Instrument call string
		@cpp_args
	);

	my $result = $?;

	LDV::Utils::pop_instrument();
	chdir $current_dir;
	return ($result,@prep_err);
}

# Makes file through CIL in the directory given with the options given.  Returns what call to C<system> returned.
# Usage:
# 	cilly_file(cil_script="toolset_dir/cil/obj/x86_LINUX/cilly.asm.exe", cwd=>'working/dir', cil_file => 'output.i', i_file => 'input.c', opts=> ['-D','SOMETHING'] )
use LDV::Utils;
sub cil_one_file
{
	my $info = {@_};
	my $cil_script = $info->{cil_script} or Carp::confess;
	my $cil_temps = $info->{temps};
	mkpath($cil_temps) if $cil_temps;
	# Change dir to cwd; then change back
	my $current_dir = getcwd();
	chdir $info->{cwd} or Carp::confess;
	LDV::Utils::push_instrument("CIL");

	# Filter out "-c" from options -- we need just preprocessing from CIL
	my @opts = ();
	if($info->{opts}) {
		@opts = @{$info->{opts}};
		@opts = grep {!/^-c$/} @opts;
	}

	my @extra_args = (
		"$info->{c_file}",	#Input file
		"--out", "$info->{i_file}",	#Output file
		# User-supplied options
		@opts,
	);

	my @cil_args = ($cil_script);
	defined $info->{is_list} and push @cil_args,'--extrafiles';
	push @cil_args,@extra_args;

	# Add extra arguments
	push @cil_args,(split /\s+/,$ENV{'CIL_OPTIONS'});

	# Measure time of CIL as well.  Add it to the common timestat file.
	@cil_args = DSCV::RCV::Utils::set_up_timeout({
		pattern => '.*,CIL',
		output => $context->{timestats_file},
		},@cil_args
	);

	vsay ('DEBUG',"Invoke: ",@cil_args,"\n");
	local $"=' ';

	my @prep_err = ();
	my %child = Utils::open3_callbacks({
		# Stdout callback
		out => sub{my $line = shift;
			vsay("TRACE",$line);
		},
		# Stderr callback
		'err' => sub{ my $line = shift;
			push @prep_err,$line;
			vsay("DEBUG",$line);
		},
		close_out=>sub{ vsay ('TRACE',"CIL's stdout stream closed.\n");},
		close_err=>sub{ vsay ('TRACE',"CIL's stderr stream closed.\n");},
		},
		# Instrument call string
		@cil_args
	);

	my $result = $?;

	LDV::Utils::pop_instrument();
	chdir $current_dir;
	return ($result, @prep_err);
}

# tail_automaton(N) creates an automaton that dumps the last N lines
sub tail_automaton
{
	my $count = shift || 50;
	my @buffer = ();
	return sub{
		my $l = shift;
		if (defined $l){
			# It's a real line
			chomp $l;
			push @buffer, $l;
			shift @buffer if scalar @buffer > $count;
			# Show that this automaton is still working
			return undef;
		}else{
			# It's a past-the-end line
			return {'TAIL' => \@buffer};
		}
	};
}


# Returns the list of files a user supplied
sub get_files
{
	return @{$context->{files_to_send}};
}

# Get files for trace.
# Warning!  This is not reentrant (bad usage of $temp_file)!
sub add_files_for_trace
{
	# Check all the traces we have, and add the relevant source code files to the package for our parents
	# I would like to add only the files that are generated by DSCV, but the code for path fixups is a mess, see ldv/ldv-task-reporter.  So I'll just add all the files here, and just notify you with FIXME. :-)
	my $trace_fname = shift or die;
	vsay('INFO', "Getting files for trace $trace_fname with ETV for parent package.\n");
	my $temp_file = "$context->{tmpdir}/etv.tmp";
	my @etv = ("$ENV{'DSCV_HOME'}/bin/etv",
		"--report=$trace_fname",
		"--reqs-out=$temp_file"
	);
	local $"=" ";
	vsay('DEBUG', "Calling error-trace-visualizer: @etv\n");
	system(@etv) and die("Error trace visualizer (@etv) failed\n");

	my @result;

	# add all the files printed to reqs-out file to the package for parent
	my $TRACE_READ; open $TRACE_READ, "<", $temp_file or die;
	local $_;
	while (<$TRACE_READ>){
		chomp;
		vsay('DEBUG', "ETV returns file: $_\n");
		push @result, $_ if -f $_;
	}
	close $TRACE_READ;

	return @result;
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
		'cil_script' => undef,
		'cil_options' => [],
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

