#!/usr/bin/perl -w

################################################################################
# Copyright (C) 2010-2012
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

use FindBin;
BEGIN {
        $ENV{'LDV_HOME'} ||= "$FindBin::Bin/..";
}

BEGIN {
        # Add the lib directory to the @INC to be able to include local modules.
        push @INC,"$ENV{'LDV_HOME'}/shared/perl";
}

sub remove_unused_cmds;
sub filter;
sub is_used;

=head1 NAME

bce-trace-mod.pl - script for createing, numbers, pathcing options, cleaning commands, that not in use

=head1 SYNOPSYS

bce-trace-mod.pl tested on version 2.6.31.6 - 2.6.35.7
	
Example:

	bce-trace-mod.pl -c 

or:

	bce-trace-mod.pl --cmds=/path/to/command-stream.xml

Please, specify -f option if you want to setup filter for drivers.

=cut


sub usage{ print STDERR<<usage_ends;

Usage:
	bce-trace-mod.pl -c path-to-command-stream

usage_ends
	die;
}

use Getopt::Long qw(:config require_order);

my $config = {
	'verbosity' => $ENV{'LDV_DEBUG'} || 'NORMAL',
	'filter' => '.*',
};

GetOptions(
        'cmdfile|c=s'=>\$config->{'cmdfile'},
       'filter|f=s'=>\$config->{'filter'},
) or usage;

$config->{'cmdfile'} or usage;
-f $config->{'cmdfile'} or die("Command stream must be an existing file.");

$config->{'filter'} = $ENV{'CMD_FILTER'} || $config->{'filter'};

use LDV::Utils;
LDV::Utils::set_verbosity($config->{verbosity});
LDV::Utils::push_instrument('cmd-filter');

use XML::Twig;

my $cmdstreamT = new XML::Twig();
$cmdstreamT->parsefile($config->{'cmdfile'});
vsay 'NORMAL',"Filter out drivers.\n";
filter($config,$cmdstreamT);
vsay 'NORMAL',"Remove unused commands.\n";
remove_unused_cmds($config,$cmdstreamT);
$cmdstreamT->set_pretty_print('indented');
open $CMDFILE, ">", $config->{'cmdfile'} or die "Can't open cmd-stream file: $!";
$cmdstreamT->print($CMDFILE);
close $CMDFILE;

sub filter {
	my ($config,$cmdstreamT) = (@_);
	my $cmdsT = $cmdstreamT->root;
	foreach($cmdsT->findnodes('/cmdstream/*/out[@check="true"]')) {
		my $cmdT = $_->parent;
		$cmdT->name eq 'ld' or $cmdT->name eq 'cc' or next;
		if($_->text =~ /$config->{'filter'}/) {
			vsay 'TRACE', "Skip \"".$cmdT->name."\" command with id=".$cmdT->att('id')."\n";
		} else {
			vsay 'TRACE', "Remove \"".$cmdT->name."\" command with id=".$cmdT->att('id')."\n";
			$cmdT->delete;
		}
	}
}

sub remove_unused_cmds {
	my ($config,$cmdstreamT) = (@_);
	my $cmdsT = $cmdstreamT->root;
	foreach ($cmdsT->children) {
		$_->name eq 'ld' or $_->name eq 'cc' or next;
		my $outT = $_->first_child('out');
		if($outT->has_atts('check') && $outT->att('check') eq 'true') { next; };
		if(is_used($outT,$cmdstreamT)) {
			vsay 'TRACE', "Skip used \"".$_->name."\" command with id=".$_->att('id')."\n";
		} else {
			vsay 'TRACE', "Remove unused \"".$_->name."\" command with id=".$_->att('id')."\n";
			$_->delete;
		}
	}
}

sub is_used {
	my ($cmdT,$cmdstreamT) = (@_);
	my $cmdsT = $cmdstreamT->root;
	foreach $lcmdT($cmdsT->children) {
		$lcmdT->name eq 'ld' or $lcmdT->name eq 'cc' or next;
		foreach ($lcmdT->children('in')) {
			$cmdT->text eq $_->text and return 1;
		}
	}
}

















