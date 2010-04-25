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
	vsay ('DEBUG',"Preprocessor: ",@cpp_args);
	local $"=' ';
	my $result = system @cpp_args; 

	chdir $current_dir;
	return $result;
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

		my $children_FH; open $children_FH,">",$o_file or die "Dead while trying to open $o_file for writing";
		$cmdT->print($children_FH);
		close $children_FH;
	};
}

# Functor that returns a Twig handler for LD command.
# The handler flushes cmdfile related to CC to a <out> of CC command.  This file will be picked by LD handler.
# The functor takes ref to $unbasedir and $workdir, relative to which unbased o-file will be created.
# The sub returned may die if it encounters a critical error or critical sanity check violation
sub ld_maker
{
	my %args = @_;
	my $do_preprocess = $args{preprocess} || 1;
	my $do_cilly = $args{cilly} || '';
	my $unbasedir_ref = $args{unbasedir_ref};
	my $workdir = $args{workdir};
	my $verify = $args{verifier};

	return sub{
		my ($twig, $cmdT) = @_;
		# See cc_maker for reasons why a ref is required here
		my $unbasedir = $$unbasedir_ref;
		# Get the list of c files for current linked file
		# We assume that each c-file is included into any executable file only once (otherwise there would have been undefined references).
		local $_;
		my @o_files_raw = map {$unbasedir->($_)} $cmdT->children_text('in');
		my $target = $unbasedir->($cmdT->first_child_text('out'));
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
					my $i_file = $c_file; $i_file =~ s/\.c$/.i/; $i_file =~ s/\//-/g; $i_file = "$preprocess_dir/$i_file";
					mkpath(dirname($i_file));
					$new_record->{i_file} = $i_file;
					preprocess_file(%$new_record) and die "PREPROCESS ERROR!  Recovery is unimplemented"; # TODO
				}else{
					$new_record->{i_file} = $new_record->{c_file};
				}

				push @$c_files_info, $new_record;
			}
		}

		# Call the verifier for all of the preprocessed c-files gotten at once, and and supply the additional arguments fetched from the tag record.

		# Get hints tag first 
		my $hintsT = $cmdT->first_child('hints');
		# Get entry points
		my @mains = $cmdT->children_text('main');
		@mains or vsay("WARNING", "No mains specified for file ".$cmdT->first_child_text('out')."\n");
		# Get list of files to analyze:
		my @files = map {$_->{i_file}} @$c_files_info;
		# List of error locations
		my @errlocs = $cmdT->children_text('error');
		# Report file
		my $report = reports_dir($workdir)."/$target.report";
		mkpath(dirname($report));
		# Tool debug file (to dump the trace of the tool)
		my $debug = reports_dir($workdir)."/$target.debug";
		mkpath(dirname($debug));
		# Trace file (to dump the error trace)
		my $trace = reports_dir($workdir)."/$target.trace";
		mkpath(dirname($trace));

		$verify->(cmd_id=>$cmdT->att('id'), files => \@files, hints=>$hintsT, mains=>\@mains, errlocs=>\@errlocs, report=>$report, trace=>$trace, debug=>$debug, dbg_target=>$target); 

	};
}

1;



