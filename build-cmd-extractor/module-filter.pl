#! /usr/bin/perl -w

use strict;
use English;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use XML::Twig;
use Env qw(LDV_DEBUG);
use FindBin;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../shared/perl");

# Add some nonstandard local Perl packages.
use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info
  print_debug_debug print_debug_trace print_debug_all get_debug_level
  check_system_call);

###############
# Variables
###############
my $debug_name = 'module-filter';

my $opt_xml_file;
my $opt_check_only;
my $opt_results_file;
####################################
# Subroutine prototypes
####################################

# Process command-line options.
# args: no.
# retn: nothing.
sub get_opt();

# Start looking for module
# args: no
# retn: module
sub start();
#######
# main
#######
get_debug_level($debug_name, $LDV_DEBUG);
print_debug_normal("Process the command-line options");
get_opt();

# First 60 codes already occupied
exit(61) unless(start());
#####################
# Subroutines
#####################
sub get_opt()
{
	unless (GetOptions(
		'xml_file=s' => \$opt_xml_file,
		'check_only=s' => \$opt_check_only,
		'results=s' => \$opt_results_file))
	{
		warn("Incorrect options!");
	}
	die"You didn't set up xml_file!" unless($opt_xml_file);
	die"You didn't set up check_only file!" unless($opt_check_only);
	die"Couldn't find xml or check_only file: $ERRNO"
		unless((-f $opt_xml_file) and (-f $opt_check_only));
}

sub start()
{
	my @modified_files;
	# Files which were changed in a patch and can affect the module.
	my @mod_our_files;
	print_debug_debug("Reading $opt_check_only..");
	open(MYFILE, '<', $opt_check_only)
		or die "Couldn't open file '$opt_check_only' for read: $ERRNO";
	while(<MYFILE>)
	{
		chomp($_);
		push(@modified_files, $_);
	}
	close(MYFILE) or die "Couldn't close '$opt_check_only' after read: $ERRNO";
	my $twig = new XML::Twig;
	print_debug_debug("Parsing $opt_xml_file..");
	$twig->parsefile("$opt_xml_file");
	my $root = $twig->root;
	my @cc_commands = $root->children('cc');
	my @ld_commands = $root->children('ld');
	my $basedir= $root->first_child('basedir')->text;
	my @cc_good_out;
	foreach my $cc (@cc_commands)
	{
		foreach my $in_arg($cc->children('in'))
		{
			while(<@modified_files>)
			{
				if($in_arg->text eq "$basedir/$_")
				{
					push(@cc_good_out, $cc->first_child('out')->text);
					push(@mod_our_files, $_);
					last;
				}
			}
		}
	}
	my $module;
	my $ld_id;
	foreach my $ld (@ld_commands)
	{
		foreach my $in_arg ($ld->children('in'))
		{
			while(<@cc_good_out>)
			{
				if($in_arg->text eq $_)
				{
					$module = $ld->first_child('out')->text;
					$module = $1 if($module =~ /$basedir\/(.*)/);
				}
			}
		}
		$ld_id = $ld->att('id');
	}
	if($module)
	{
		open(MYFILE, '>>', $opt_results_file) or die "Couldn't open";
		my $mod_our_files_str = join(',', @mod_our_files);
		print(MYFILE "id=$ld_id;driver=$module;files:$mod_our_files_str;\n");
		close(MYFILE);
		`sed -i -e 's/ /;/g' $opt_results_file`;
		print_debug_debug("Driver in command id = $ld_id is found: '$module'");
	}
	return $module;
}
