#!/usr/bin/perl -w

=head1 NAME

final_link_patch.pl - script for patching kernel, that removes final links for drivers/built-in.o, vmlinux, vmlinux.o, bzImage

=head1 SYNOPSYS

final_link_patch.pl tested on version 2.6.31.6 - 2.6.35.7
	
Example:

	final_link_patch.pl -k /path/to/kernel

or:

	final_link_patch.pl --kernel=/path/to/kernel

=cut

use FindBin;

BEGIN {
	$ENV{'LDV_HOME'} ||= "$FindBin::Bin/../../../";
	push @INC,"$ENV{'LDV_HOME'}/shared/perl";
}

sub get_kernel_info;
sub patch_final_link;
sub patch_main_makefile;
sub patch_modpost_makefile;
sub patch_kbuild_include;
sub patch_arch_files;
sub patch_arch_files_x86;
sub patch_arch_x86_makefile;
sub patch_headers;

sub usage{ print STDERR<<usage_ends;

Usage:
	final_link_patch.pl path_to_kernel

usage_ends
	die;
}

use LDV::Utils;
LDV::Utils::set_verbosity($ENV{'LDV_DEBUG'} || 'NORMAL');
LDV::Utils::push_instrument('ldv-fix-bigobj');

use Getopt::Long qw(:config require_order);

my $path_to_kernel = undef;

GetOptions(
        'kernel|k=s'=>\$path_to_kernel,
) or usage;

$path_to_kernel or usage;
-d $path_to_kernel or die("Path to kernel must be an exisiting directory.");

my $kernel_info = get_kernel_info($path_to_kernel);
patch_final_link($kernel_info);

sub patch_kbuild_include {
	my ($kernel_info) = @_;
	open (FILE, $kernel_info->{'kbuild_include'}) or die("Can't open main Kbuild.include for reading while patching: $!");
	my @string = <FILE>;
	close FILE or die("Can't close main Kbuild.include after reading for patching: $!");
	open (FILE,">".$kernel_info->{'kbuild_include'}) or die("Can't open main Kbuild.include for patching: $!");
	my $state = 1;
	foreach (@string) {
		/^\s*if_changed = \$\(if \$\(strip \$\(any-prereq\) \$\(arg-check\)\),\s*\\\s*$/ and $state=2;
		/^(\s*\@set -e;\s*\\\s*)$/ and $state==2 and $_ = "$1\tif \[ \! \"\$\@\" = \"drivers\/built-in\.o\" \]; then\t\\\n" and $state=3;
		/^\s*\$\(echo-cmd\) \$\(cmd_\$\(1\)\);\s*\\\s*$/ and $state==3 and $state=4;
		/^(\s*echo 'cmd_\$\@ := \$\(make-cmd\)' > \$\(dot-target\)\.cmd)\)\s*$/ and $state==4 and $_="$1; \\\n\tfi)\n" and $state=1;
		print FILE;
	}
	close FILE or die("Can't close Kbuild.include after patching: $!");
}

sub patch_arch_x86_makefile {
	my ($kernel_info) = @_;
	open (FILE, $kernel_info->{'arch'}->{'x86'}->{'makefile'}) or die("Can't open main arch makefile for reading while patching: $!");
	my @string = <FILE>;
	close FILE or die("Can't close main arch makefile after reading for patching: $!");
	open (FILE,">".$kernel_info->{'arch'}->{'x86'}->{'makefile'}) or die("Can't open main arch makefile for patching: $!");
	foreach (@string) {
		/^\s*\$\(Q\)\$\(MAKE\) \$\(build\)=\$\(boot\) \$\(KBUILD_IMAGE\)\s*$/ and next;
		/^(\s*\$\(Q\))ln -fsn \.\.\/\.\.\/x86\/boot\/bzImage( \$\(objtree\)\/arch\/\$\(UTS_MACHINE\)\/boot\/\$@\s*)/ and $_="$1touch$2";
		print FILE;
	}
	close FILE or die("Can't close main arch makefile after patching: $!");
}

sub patch_arch_files_x86 {
	vsay 'NORMAL', "Patching arch makefile for x86.\n";		
	patch_arch_x86_makefile($kernel_info);
}

sub patch_headers {
	vsay 'NORMAL', "Patching header file: \"$kernel_info->{'header_linux_gfp_h'}\".\n";
	open (FILE, $kernel_info->{'header_linux_gfp_h'}) or die("Can't open header file reading while patching: $!");
	my @string = <FILE>;
	close FILE or die("Can't close main arch makefile after reading for patching: $!");
	open (FILE,">".$kernel_info->{'header_linux_gfp_h'}) or die("Can't open header file for patching: $!");
	my $state = 1;
	foreach (@string) {
		/^(\s*if \(__builtin_constant_p\(bit\)\)\s*)$/ and $_="/*$1";
		/^\s*BUG_ON\(\(GFP_ZONE_BAD >> bit\) & 1\);\s*$/ and $state = 2;
		/^\s*#endif\s*$/ and $state==2 and $state=3;
		/^(\s*})(\s*)$/ and $state==3 and $state=1 and $_="$1*/$2";
		print FILE;
	}
	close FILE or die("Can't close header file after patching: $!");

	vsay 'NORMAL', "Patching header file: \"$kernel_info->{'header_linux_kernel_h'}\".\n";
	open (FILE, $kernel_info->{'header_linux_kernel_h'}) or die("Can't file reading while patching: $!");
	@string = <FILE>;
	close FILE or die("Can't close file after reading for patching: $!");
	open (FILE,">".$kernel_info->{'header_linux_kernel_h'}) or die("Can't open file for patching: $!");
	$state = 1;
	foreach (@string) {
		/^(\s*#define BUILD_BUG_ON\(condition\) )(\(\(void\)BUILD_BUG_ON_ZERO\(condition\)\)\s*)$/ and $_="$1 //$2";
		/^(\s*#define BUILD_BUG_ON\(condition\) )(\(\(void\)sizeof\(char\[1 - 2\*\!\!\(condition\)\]\)\)\s*)$/ and $_="$1//$2";
		print FILE;
	}
	close FILE or die("Can't close file after patching: $!");

	vsay 'NORMAL', "Patching header file: \"$kernel_info->{'header_net_inet_sock_h'}\".\n";
	open (FILE, $kernel_info->{'header_net_inet_sock_h'}) or die("Can't file reading while patching: $!");
	@string = <FILE>;
	close FILE or die("Can't close file after reading for patching: $!");
	open (FILE,">".$kernel_info->{'header_net_inet_sock_h'}) or die("Can't open file for patching: $!");
	$state = 1;
	foreach (@string) {
		/^\s*kmemcheck_annotate_bitfield\(ireq, flags\);\s*$/ and next;
		print FILE;
	}
	close FILE or die("Can't close file after patching: $!");

	# To allow models 60_1 and 68_1 to be processed with kernel having versions higher then 2.6.33.
	# See details in Bug #338.
	if($kernel_info->{'SUBLEVEL'}>=33) {
		vsay 'NORMAL', "Patching header file: \"$kernel_info->{'header_spinlock_types_h'}\".\n";
		open (FILE, $kernel_info->{'header_spinlock_types_h'}) or die("Can't file reading while patching: $!");
		@string = <FILE>;
		close FILE or die("Can't close file after reading for patching: $!");
		open (FILE,">".$kernel_info->{'header_spinlock_types_h'}) or die("Can't open file for patching: $!");
		$state = 1;
		foreach (@string) {
			/^\s*# define LOCK_PADSIZE \(offsetof\(struct raw_spinlock, dep_map\)\)\s*$/ and $_="\n# define LOCK_PADSIZE 1\n";
			print FILE;
		}
		close FILE or die("Can't close file after patching: $!");
	}
}

sub patch_arch_files {
	my ($kernel_info) = @_;
	foreach $arch (keys %{$kernel_info->{'arch'}}) {
		vsay 'NORMAL', "Patching files for arch \"$arch\"\n";		
		$arch eq 'x86' and patch_arch_files_x86($kernel_info);
	}
}

sub patch_modpost_makefile {
	my ($kernel_info) = @_;
	open (FILE, $kernel_info->{'modpost_makefile'}) or die("Can't open main modpost makefile for reading while patching: $!");
	my @string = <FILE>;
	close FILE or die("Can't close main modpost makefile after reading for patching: $!");
	open (FILE,">".$kernel_info->{'modpost_makefile'}) or die("Can't open main modpost makefile for patching: $!");
	foreach (@string) {
		/^(\s*\$\(call cmd,modpost\) )\$\(wildcard vmlinux\) (\$\(filter-out FORCE,\$\^\)\s*)$/ and $_=$1.$2;
		print FILE;
	}
	close FILE or die("Can't close main modpost makefile after patching: $!");
}


sub patch_main_makefile {
	my ($kernel_info) = @_;
	open (FILE, $kernel_info->{'makefile'}) or die("Can't open main makefile for reading while patching: $!");
	my @string = <FILE>;
	close FILE or die("Can't close main makefile after reading for patching: $!");
	open (FILE,">".$kernel_info->{'makefile'}) or die("Can't open main makefile for patching: $!");
	my $state = 1;
	foreach (@string) {
		/^\s*KBUILD_CFLAGS \+= -DCC_HAVE_ASM_GOTO\s*$/ and next;
		/^\s*cmd_vmlinux__ \?= \$\(LD\) \$\(LDFLAGS\) \$\(LDFLAGS_vmlinux\) -o \$@\s*\\\s*$/ and next;
		/^\s*-T \$\(vmlinux-lds\) \$\(vmlinux-init\)\s*\\\s*$/ and next;
		/^\s*--start-group \$\(vmlinux-main\) --end-group\s*\\\s*$/ and $_="\tcmd_vmlinux__ ?=  touch \$@ \\\n";

		/^\s*\$\(Q\)\$\(if \$\(\$\(quiet\)cmd_sysmap\),\s*\\\s*$/ and next;
		/^\s*echo \'  \$\(\$\(quiet\)cmd_sysmap\)  System\.map\' &&\)\s*\\\s*$/ and next;
		/^\s*\$\(cmd_sysmap\) \$\@ System\.map;\s*\\\s*$/ and next;
		/^\s*if \[ \$\$\? -ne 0 \]; then\s*\\\s*$/ and next;
		/^\s*rm -f \$\@;\s*\\\s*$/ and $state = 2 and next;
		/^\s*\/bin\/false;\s*\\\s*$/ and $state == 2 and $state = 3 and next;
		/^\s*fi;\s*$/ and $state == 3 and $state = 1 and next;
		/^\s*\$\(verify_kallsyms\)\s*$/ and next;

		/^ifdef CONFIG_KALLSYMS\s*$/ and $_="ifdef NO_CONFIG_KALLSYMS\n";

		/^\s*cmd_vmlinux-modpost = \$\(LD\) \$\(LDFLAGS\) -r -o \$\@\s*\\\s*$/ and $_="\tcmd_vmlinux-modpost = \\\n";
		/^\s*\$\(vmlinux-init\) --start-group \$\(vmlinux-main\) --end-group\s*\\\s*$/ and next;

		/^\s*\$\(Q\)\$\(MAKE\) -f \$\(srctree\)\/scripts\/Makefile\.modpost \$\@\s*$/ and next;
		print FILE;
	}
	close FILE or die("Can't close main makefile after patching: $!");
}

sub patch_final_link {
	my ($kernel_info) = @_;
	vsay 'NORMAL', "Your kernel version is: ".$kernel_info->{'FULLVERSION'}."\n";
	vsay 'NORMAL', "Patching main makefile \"".$kernel_info->{'makefile'}."\".\n";
	patch_main_makefile($kernel_info);
	vsay 'NORMAL', "Patching main modpost makefile \"".$kernel_info->{'modpost_makefile'}."\".\n";
	patch_modpost_makefile($kernel_info);
	vsay 'NORMAL', "Patching main buid makefile \"".$kernel_info->{'kbuild_include'}."\".\n";
	patch_kbuild_include($kernel_info);
	vsay 'NORMAL', "Patching arch files.\n";
	patch_arch_files($kernel_info);
	vsay 'NORMAL', "Patching headers files.\n";
	patch_headers($kernel_info);
}

sub get_kernel_info {
	my ($path_to_kernel) = @_;
	my %kernel_info = ('path' => $path_to_kernel, 'makefile'=>$path_to_kernel.'/Makefile');	
	open FILE, "<", $kernel_info{'makefile'} or die("Can't open main makefile for reading kernel information: $!");
	while(<FILE>) {
		/^\s*VERSION\s*=\s*([0-9]+)\s*$/ and $kernel_info{'VERSION'}=$1;
		/^\s*PATCHLEVEL\s*=\s*(.*)\s*$/ and $kernel_info{'PATCHLEVEL'}=$1;
		/^\s*SUBLEVEL\s*=\s*(.*)\s*$/ and $kernel_info{'SUBLEVEL'}=$1;
		/^\s*EXTRAVERSION\s*=\s*(.*)\s*$/ and $kernel_info{'EXTRAVERSION'}=$1;
		/^\s*NAME\s*=\s*(.*)\s*$/ and $kernel_info{'NAME'}=$1;
	}
	$kernel_info{'FULLVERSION'} = $kernel_info{'VERSION'}.'.'.
					 $kernel_info{'PATCHLEVEL'}.'.'.
					 $kernel_info{'SUBLEVEL'}.
					 $kernel_info{'EXTRAVERSION'};
	$kernel_info{'modpost_makefile'} = $path_to_kernel.'/scripts/Makefile.modpost';
	$kernel_info{'kbuild_include'} = $path_to_kernel.'/scripts/Kbuild.include';
	$kernel_info{'arch'}->{'x86'}->{'makefile'} = $path_to_kernel.'/arch/x86/Makefile';
	$kernel_info{'header_linux_gfp_h'} = $path_to_kernel.'/include/linux/gfp.h';
	$kernel_info{'header_linux_kernel_h'} = $path_to_kernel.'/include/linux/kernel.h';
	$kernel_info{'header_net_inet_sock_h'} = $path_to_kernel.'/include/net/inet_sock.h';
	$kernel_info{'header_spinlock_types_h'} = $path_to_kernel.'/include/linux/spinlock_types.h';
	close FILE or die("Can't close main makefile after reading kernel information.");
	return {%kernel_info};
}

