#!/usr/bin/perl -w
#

use Cwd 'abs_path';
use FindBin;
use File::Path qw(make_path remove_tree);
use File::Basename;
use File::Copy;
use IPC::Open3;

sub init_config;
sub read_patches;
sub parse_targets;
sub create_backup;
sub apply_patches;
sub write_outfile;
sub report_and_exit;


my $instrumnet = 'patchmod.pl';

BEGIN {
        $ENV{'LDV_HOME'} ||= "$FindBin::Bin/..";
	push @INC,"$ENV{'LDV_HOME'}/shared/perl";
}


sub usage{ print STDERR<<usage_ends;

Usage:
        $instrumnet --patch=/path/to/patch --backup=/path/to/dir/for/backup --kernel=/path/to/kernel/source/root --out=/path/to/file/for/report

usage_ends
        die;
}

use Getopt::Long qw(:config require_order);

my $config = {
	'verbosity' => $ENV{'LDV_DEBUG'} || 'NORMAL'
};

GetOptions(
        'patch|p=s'=>\$config->{patch},
        'backup|b=s'=>\$config->{backup},
        'kernel|k=s'=>\$config->{kernel},
        'out|o=s'=>\$config->{out},
) or usage;

use LDV::Utils;
LDV::Utils::set_verbosity($config->{verbosity});
LDV::Utils::push_instrument($instrumnet);

############################################################
#                   MAIN                                   #
############################################################
init_config($config);
read_patches($config);
parse_targets($config);
create_backup($config);
apply_patches($config);
write_outfile($config);



############################################################
#		SUBROUTINES                                #
############################################################

sub parse_targets {
	my ($config) = @_;
	my @targets = ();
	$config->{targets} = \@targets;
	vsay 'NORMAL', "\n************ Find targets, config options and etc ************\n";
	foreach $file (keys %{$config->{files}}) {
		vsay 'DEBUG', "----> Find targets and config options in patch $file\n";
		foreach $backup_file (keys %{$config->{files}->{$file}->{files}}) {
			my @fcontent = split  /\n/,$config->{files}->{$file}->{files}->{$backup_file}->{content};
			$backup_file =~ /.*Makefile$/ or $backup_file =~ /.*Kbuild$/ or next;
			vsay 'TRACE', "      Parse targets in Makefile or Kbuild: $backup_file\n";
			foreach (@fcontent) {
				if(/^(.+)\$\(CONFIG_(.*)\)\s*\+?=\s*(.*)\.o/ or /^(obj-)(m)\s*\+?=\s*(.*)\.o/) {
					# get file dirname 
					my $dir = dirname($backup_file)."\n";
					chomp $dir;
					my $target = "$dir\/$3\.ko";
					vsay 'TRACE', "      TARGET: $target\n";
					push @targets, $target;
				} else {
					# TODO: Kbuild
				}
			}
		}
	}	
	@targets or report_and_exit($config, "Can't find target.");
}

sub write_outfile {
	my ($config) = @_;
	my $content = "<?xml version=\"1.0\"?>\n";
	$content .= "<patchmod>\n";
	
	# create result message
	$content .= "  <result>OK</result>\n";
	$content .= "  <desc>All stages successfully finfished</desc>\n";

	# write all backup files
	$content .= "  <backup>\n";
	$content .= "    <kernel>$config->{kernel}</kernel>\n";
	$content .= "    <backup-folder>$config->{backup}</backup-folder>\n";
	$content .= "    <files>\n";
        foreach $file (keys %{$config->{files}}) {
                foreach $backup_file (keys %{$config->{files}->{$file}->{files}}) {
			$content .= "      <file>$backup_file</file>\n";
		};
	};
	$content .= "    </files>\n";
	$content .= "  </backup>\n";
	$content .= "  <target>";
	$content .= " $_" foreach @{$config->{targets}};
	$content .= "</target>\n";
	$content .= "</patchmod>\n";

	# write to file
	open FILE, ">", $config->{out} or die"Can't open out file $config->{out}: $!";
	print FILE $content;
	close FILE or die"Can't close out file!";
}


sub apply_patches {
	my ($config) = @_;
	vsay 'NORMAL', "\n************ starting apply patches ************\n";

	# apply pacthes without order and get max number
	my $max_number = 0;
	foreach $file (keys %{$config->{files}}) {
		if($config->{files}->{$file}->{number} == 0) {
			vsay 'DEBUG', "----> Apply patch: $file\n";
			#my $patch_args="cd $config->{kernel} && patch -p1 < $file";
			#vsay 'TRACE', "$patch_args\n";

			foreach (keys %{$config->{files}->{$file}->{files}}) {
				$config->{files}->{$file}->{files}->{$_}->{mode} eq 'new' and system("cd $config->{kernel} && rm -fr $_");
			}

			apply_one_patch($config, $file);
		} else {
			$max_number<$config->{files}->{$file}->{number} and $max_number = $config->{files}->{$file}->{number};
		}
	}
	$max_number == 0 and return;

	# apply patches with order
	for (my $curnum = 1; $curnum<=$max_number; $curnum++) {
		foreach $file (keys %{$config->{files}}) {
			if($config->{files}->{$file}->{number} == $curnum) {
				vsay 'DEBUG', "----> Apply patch: $file\n";
				#my $patch_args="cd $config->{kernel} && patch -p1 < $file";
				#vsay 'TRACE', "$patch_args\n";


				foreach (keys %{$config->{files}->{$file}->{files}}) {
					$config->{files}->{$file}->{files}->{$_}->{mode} eq 'new' and system("cd $config->{kernel} && rm -fr $_");
				}

				#system($patch_args) and report_and_exit($config, "Error during applying patch: \"$file\".");
				apply_one_patch($config, $file);
			}
		}
	}
}

sub create_backup {
	my ($config) = @_;
	vsay 'NORMAL', "\n************ create backup copies  ************\n";
	foreach $file (keys %{$config->{files}}) {
		vsay 'DEBUG', "----> Starting backup files in patch $file\n";
		foreach $backup_file (keys %{$config->{files}->{$file}->{files}}) {
			my $orig = "$config->{kernel}/$backup_file";
			! -f $orig and next;
			my $backup = "$config->{backup}/$backup_file";
			vsay 'TRACE', "      backup file: $orig\n";
			# first - create full path
			$bpath = dirname($backup);
			if(! -d $bpath) {
				make_path($bpath) or die"Can't create path for backup \"$bpath\"";
			} ;
			copy($orig, $backup) or die"Can't copy file from \"$orig\" to \"$backup\"";
		}
	}
}

sub read_patches {
	my ($config) = @_;
	foreach $file (keys %{$config->{files}}) {
		my ($files, $number) = read_patch_file($file);
		$config->{files}->{$file}->{files} = $files;
		$config->{files}->{$file}->{number} = $number;
	}
}

sub read_patch_file {
	my ($file) = @_;
	my $files = {};
	open FILE, $file or die"Can't open patch-file \"$file\"!";
	@lines = <FILE>;
	close FILE;

	my $vector = undef;
	my $bfile = undef;
	my $content = undef;
	my $number = 0;
	foreach (@lines) {
		/Subject:\s*\[PATCH\s+(\d+)\s*\/\s*(\d+)\s*\]/ and $number = $1 and next;
		/^--$/ and last;
		if(/^diff .*/) {
			@targets = split / /,$_;
			$bfile = $targets[@targets-1];
			$vector = $targets[@targets-2];
			$vector =~ s/a\/(.*)/$1/;
			$files->{$vector}->{content} = "";
			$files->{$vector}->{mode} = 'diff';
		} elsif (/new file mode.*/ and defined $vector) {
			$files->{$vector}->{mode} = 'new';
		} elsif (defined $vector) {
			/^\+\+\+ $bfile/ and next;
			s/^\+(.*)/$1/ or next;
			$files->{$vector}->{content} = "$files->{$vector}->{content}$_";
		}
	}
	return ($files, $number);
}

sub report_and_exit {
        my ($config, $msg) = @_;
        my $content = "<?xml version=\"1.0\"?>\n";
        $content .= "<patchmod>\n";

        # write all backup files
        $content .= "  <result>FAILED</result>\n";
        $content .= "  <desc>$msg</desc>\n";
	$content .= "</patchmod>\n";

        open FILE, ">", $config->{out} or die"Can't open out file $config->{out}: $!";
        print FILE $content;
        close FILE or die"Can't close out file!";
	exit;
}

sub init_config {
	my ($config) = @_;

	$ENV{'WORK_DIR'} || die"Please, specify WORK_DIR environment variable!";

	$config->{'workdir'} = abs_path($ENV{'WORK_DIR'});
	$config->{'patch_err'} = "$config->{'workdir'}/patch_err.log";
	$config->{'patch_out'} = "$config->{'workdir'}/patch_out.log";

	# test all options
	defined $config->{patch} or die"Please, specify path to file or dir with patch!";
	defined $config->{kernel} or die"Please, specify path to kernel!";
	defined $config->{out} or die"Please, specify output file!";

	$config->{out} = abs_path($config->{out});
	my $outdir = dirname($config->{out});

	-d $config->{kernel} or die"Path to kernel must be a really exists dir!";
	$config->{kernel} = abs_path($config->{kernel});


	if(-d $config->{patch}) {
		$config->{patch} = abs_path($config->{patch});
		my $files = findFiles($config->{patch});
		$config->{files}->{$_}->{ex} = 1 foreach @$files;

	} elsif (-f $config->{patch}) {
		$config->{patch} = abs_path($config->{patch});
		$config->{files}->{$config->{patch}}->{ex} = 1;
	} else {
		vsay 'NORMAL', "Unknown patch type \"$config->{patch}\". It must be file or dir";
	};

	if(! -d $outdir) {
		warn"Path to out file not exists!";
		make_path($outdir) or die"Can't create path to out file!";
	}
	
	if(-f $config->{out}) {
		warn"Output file already exists!";
		unlink $config->{outfile} or die"Can' remove previous outfile!";
	}

	#
	# For now, kernel must have backup folder...
	# After starting ldv-core must be:
	# 1. check if backup folder exists
	# 2. If first true - then copy all files from
	#    backup to kernel and remove backup!
	#
	$config->{backup} or $config->{backup} = "$config->{kernel}/ldv_backup/backup_before_patch";
	if(! -d $config->{backup}) {
		make_path($config->{backup}) or die"Can't create backup folder";
	} else {
		warn"Backup folder \"$config->{backup}\" already exists!";
	}
	
}

sub findFiles {
	my @files = ();
	findFilesRec($_[0], \@files);
	return \@files;
};

sub findFilesRec {
        my ($dir, $files) = @_;
        opendir DIR, $dir or die"Can't open dir!";
        my @lfiles = readdir DIR;
        foreach (@lfiles) {
                /^\.$/ and next;
                /^\.\.$/ and next;
                -d "$dir/$_" and findFilesRec("$dir/$_", $files) and next;
                push @$files, "$dir/$_";
        }
        close DIR;
	return 1;
}

sub apply_one_patch {
	my ($config, $patch) = (@_);
	my $patch_args="cd $config->{kernel} && patch -p1 < $patch";
	if(parallel_run($patch_args, $config->{'patch_err'}, $config->{'patch_out'})) {
		open FILE, $config->{'patch_err'} or die"Can't open file with patch applying error: \"$config->{'patch_err'}\":$!";
		@patch_err_msg = <FILE>;
		close FILE or warn"Can't close file with patch applying error:$!";
		report_and_exit("Error during applying patch: \"$file\"\n@patch_err_msg");
	};
	
	# parse output file and get rej's 
	if (-f $config->{'patch_out'} and -s $config->{'patch_out'} > 0) {
		open FILE, $config->{'patch_out'} or die"Can't open output patch file:$!";
		my @lines = <FILE>;
		close FILE or warn"Can't close patch out file:$!";

		my $patch_msg = "";
		my $state = 'SUCCESS';
		foreach (@lines) {
			if(/.*FAILED -- saving rejects to file (.*)/) {
				$state = 'FAILED';
				open FILE, "$config->{'kernel'}/$1" or die"Can't open reject file: \"$1\":$!";
				my @rej_lines = <FILE>;
				close FILE or warn "Can't close reject file \"$1\": $!";
				local $"='';
				$patch_msg.="$_\n******* REJ FILE $1 *******\n@rej_lines\n*******************\n";
			} else {
				$patch_msg.=$_;
			}
		}
		#my $patch_for_user = $patch;  $patch_for_user =~ s/^.*\/driver_upacked
		my $patch_for_user = $patch;
		if (-f $config->{patch}){
			$patch_for_user = basename($config->{patch});
		}else{
			$patch_for_user =~ s/$config->{patch}\/+(.*)/$1/;
		}
		$patch_msg="\n\n Couldn't apply patch $patch_for_user: see rejected chunks above.\n\n".$patch_msg;
		report_and_exit($config, $patch_msg) if $state eq 'FAILED';
	}
}

sub parallel_run {
        my ($args, $err, $out) = @_;
        vsay 'TRACE', "$args\n";
        vsay 'TRACE', "Logging stdout to file: \"$out\".\n";
        vsay 'TRACE', "Logging stderr to file: \"$err\".\n";
        open FILERR, ">$err" or die"$!";
        open FILOUT, ">$out" or die"$!";
        my $pid = open3(undef, ">&FILOUT", ">&FILERR", $args);
        waitpid $pid, 0;
        close FILERR;
        close FILOUT;
	if( -f $err and -s $err>0) {
		return 1;
	}
}
