package DSCV::RCV::Utils;

# Utils for RCV backends: preprocess files, CIL-ize files, etc.

use strict;
use vars qw(@ISA @EXPORT_OK @EXPORT);
@EXPORT=qw();
use base qw(Exporter);

# For warnings
use LDV::Utils;
use Utils;

#======================================================================
# SHARED INFORMATION
#======================================================================

# Get folder that contains reports, based on wokring directory supplied to RCV
sub reports_dir
{
	my $workdir = shift or Carp::confess;
	return "$workdir/reports";
}

use File::Find;
# Execute callback for each report file found
sub foreach_report
{
	my ($work_dir, $callback) = @_;
	find({no_chdir=>1, wanted=>sub{ /\.report$/ and $callback->($File::Find::name);}},reports_dir($work_dir));
}

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
# 	preprocess_file( cwd=>'working/dir', i_file => 'output.i', c_file => 'input.c', opts=> ['-D','SOMETHING'] )
sub preprocess_file
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
	my ($basedir,$unbasedir,$fname,$sub) = @_;
	vsay ('TRACE',"based: $basedir\n");
	vsay ('TRACE',"fname: $fname\n");
	my ($base,$rel) = $fname =~ /^(\Q$basedir\E)\/(.*)/;
	vsay ('TRACE',"base: $base\n");
	vsay ('TRACE',"rel : $rel\n");
	unless (defined $base){
		$rel = $unbasedir->($fname);
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
					my $cilly_dir = "$workdir/cilly";
					mkpath($cilly_dir);
					#my $cil_file = $new_record->{i_file}; $cil_file =~ s/\.[^.]*$/.cilf.c/; $cil_file =~ s/\//-/g; $cil_file = "$cilly_dir/$cil_file";
					if($do_cilly_once) {
						my $cil_extra_files_list = "$cilly_dir/cil_extrafiles.list";
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
	$new_args{$_} = sprintf ($args{$_},$main) for qw(debug trace main timestats report);
	return %new_args;
}

1;



