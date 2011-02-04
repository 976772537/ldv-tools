#!/usr/bin/perl -w
#

use Cwd 'abs_path';
use FindBin;
use File::Path qw(make_path remove_tree);
use File::Basename;
use File::Copy;

sub init_config;

my $instrumnet = 'patchmod.pl';

BEGIN {
        $ENV{'LDV_SCRIPTS_HOME'} ||= "$FindBin::Bin";
}


sub usage{ print STDERR<<usage_ends;

Usage:
        $instrumnet TBD

usage_ends
        die;
}


#
#  BCE will be called with patch mode!
#

use Getopt::Long qw(:config require_order);

my $config = {
};

GetOptions(
        'patch|p=s'=>\$config->{patch},
        'kernel|k=s'=>\$config->{kernel},
        'out|o=s'=>\$config->{out},
) or usage;

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
	print "\n************ Find targets, config options and etc ************\n";
	foreach $file (keys %{$config->{files}}) {
		print "----> Find targets and config options in patch $file\n";
		foreach $backup_file (keys %{$config->{files}->{$file}->{files}}) {
			my @fcontent = split  /\n/,$config->{files}->{$file}->{files}->{$backup_file}->{content};
			$backup_file =~ /.*Makefile$/ or next;
			print "      Parse targets in Makefile: $backup_file\n";
			foreach (@fcontent) {
				/^(.*)-\$\(CONFIG_(.*)\)\s+\+?= (.*)\.o/ or next;
				
				# get file dirname 
				my $dir = dirname($backup_file)."\n";
				chomp $dir;
				my $target = "$dir\/$3\.ko";
				print "      TARGET: $target\n";
				push @targets, $target;
			}
		}
	}	
}

sub write_outfile {
	my ($config) = @_;
	my $content = "<?xml version=\"1.0\"?>\n";
	$content .= "<patchmod>\n";

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
	#print "\n$content\n";
	open FILE, ">", $config->{out} or die"Can't open out file $config->{out}: $!";
	print FILE $content;
	close FILE or die"Can't close out file!";
}


sub apply_patches {
	my ($config) = @_;
	print "\n************ staring apply patches ************\n";
	foreach $file (keys %{$config->{files}}) {
		print "----> Apply patch: $file\n";
		my $patch_args="cd $config->{kernel} && patch -p1 < $file";
		print "$patch_args\n";
		system("cd $config->{kernel} && patch -p1 < $file");
	}
}


sub create_backup {
	my ($config) = @_;
	print "\n************ create backup copies  ************\n";
	foreach $file (keys %{$config->{files}}) {
		print "----> Starting backup files in patch $file\n";
		foreach $backup_file (keys %{$config->{files}->{$file}->{files}}) {
			my $orig = "$config->{kernel}/$backup_file";
			! -f $orig and next;
			my $backup = "$config->{backup}/$backup_file";
			print  "      backup file: $orig\n";
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
	$config->{files}->{$_}->{files} = read_patch_file($_) foreach keys %{$config->{files}};
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
	foreach (@lines) {
		/^--$/ and last;
		if(/diff --git (.*) (.*)/) {
			$bfile = $2;
			$vector = $1;
			$vector =~ s/a\/(.*)/$1/;
			$files->{$vector}->{content} = "";
		} elsif (defined $vector) {
			/^\+\+\+ $bfile/ and next;
			s/^\+(.*)/$1/ or next;
			$files->{$vector}->{content} = "$files->{$vector}->{content}$_";
		}
	}
	return $files;
}

sub init_config {
	my ($config) = @_;

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
		print "Unknown patch type \"$config->{patch}\". It must be file or dir";
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
	$config->{backup} = "$config->{kernel}/ldv_backup/backup_before_patch";
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



