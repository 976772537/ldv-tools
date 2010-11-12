#!/usr/bin/perl -w

use FindBin;

BEGIN {
        $ENV{'LDV_HOME'} ||= "$FindBin::Bin/..";
        push @INC,"$ENV{'LDV_HOME'}/shared/perl";
}

sub usage{ print STDERR<<usage_ends;

Usage:
        LDV_DEBUG=debuglevel DBUSER=dbuser DBPASS=dbpass DBHOST=dbhost DBNAME=dbname checkdb.pl -o report.xml -d true|false

usage_ends
        die;
}

use File::Temp qw/tempfile/;
use Getopt::Long qw(:config require_order);

my $config = {
	etv => "$ENV{'LDV_HOME'}/bin/error-trace-visualizer.pl",
	loadsrc => "$ENV{'LDV_HOME'}/ldv-tests/integration-testing/load-src.pl",
	verbosity => $ENV{'LDV_DEBUG'} || 'NORMAL',
        debug => 'false',
        dbuser => $ENV{'DBUSER'},
        dbpass => $ENV{'DBPASS'},
	dbhost => $ENV{'DBHOST'} || 'localhost',
	dbname => $ENV{'DBNAME'}
};

GetOptions(
       'report|c=s'=>\$config->{report},
       'debug|d=s'=>\$config->{debug}
) or usage;

defined $config->{report} && -f $config->{report} && die'Report file already exists.';

use XML::Twig;
use File::Temp qw/ :POSIX /;
use LDV::Utils;

LDV::Utils::set_verbosity($config->{verbosity});
LDV::Utils::push_instrument('checkdb');

##############################################
#   SUB
##############################################
sub get_db_trace_sources;
sub fill_etv_souces;
sub compare_sources;
sub compare_sources_list;
sub print_report_about_sources;


##############################################
#   MAIN
##############################################

vsay 'NORMAL', "Start checking your LDV trace sources.\n";
compare_sources;
vsay 'NORMAL', "Finished.\n";


##############################################
#   SUB
##############################################
sub print_report_about_sources {
	my ($cmpsources) = @_;

	my $twig = XML::Twig->new();
	$twig->set_xml_version( '1.0');

        my $listT = XML::Twig::Elt->new('list');

        foreach my $trace_id (keys %$cmpsources) {
		! scalar keys %{$cmpsources->{$trace_id}->{notindb}} && ! scalar keys %{$cmpsources->{$trace_id}->{notinetv}} && next;
                my $traceT = XML::Twig::Elt->new('trace');
                $traceT->set_att('id',$trace_id);

		if($config->{debug} eq 'true') {	
			if(scalar keys %{$cmpsources->{$trace_id}->{etvsources}}) {
	                	my $notinT = XML::Twig::Elt->new('etvsources');
				XML::Twig::Elt->new('source',$_)->paste($notinT) foreach keys %{$cmpsources->{$trace_id}->{etvsources}};
				$notinT->paste($traceT);
			}
		
			if(scalar keys %{$cmpsources->{$trace_id}->{dbsources}}) {
	                	my $notinT = XML::Twig::Elt->new('dbsources');
				XML::Twig::Elt->new('source',$_)->paste($notinT) foreach keys %{$cmpsources->{$trace_id}->{dbsources}};
				$notinT->paste($traceT);
			}
		}

		if(scalar keys %{$cmpsources->{$trace_id}->{notindb}}) {
                	my $notinT = XML::Twig::Elt->new('notindb');
			XML::Twig::Elt->new('source',$_)->paste($notinT) foreach keys %{$cmpsources->{$trace_id}->{notindb}};
			$notinT->paste($traceT);
		}

		if(scalar keys %{$cmpsources->{$trace_id}->{notinetv}}) {
                	my $notinT = XML::Twig::Elt->new('notinetv');
			XML::Twig::Elt->new('source',$_)->paste($notinT) foreach keys %{$cmpsources->{$trace_id}->{notinetv}};
			$notinT->paste($traceT);
		}

                $traceT->paste($listT);
        }

	$twig->set_root($listT);
	$twig->set_pretty_print('indented');
	$twig->print_to_file($config->{report});
}

sub compare_sources {
	vsay 'NORMAL', "Getting sources list for all traces from db.\"";
	my ($tmpdir, $trace_sources) = get_db_trace_sources();
	fill_etv_souces($trace_sources);
	vsay 'TRACE', "Remove temp dir $tmpdir\n";
	rmdir $tmpdir or die"$!";
	vsay 'NORMAL', "Start compare sources lists\n";
	compare_sources_list($trace_sources);
	print_report_about_sources($trace_sources);
}

sub compare_sources_list {
	my ($sources) = @_;
	foreach my $trace_id (keys %{$sources}) {
		$sources->{$trace_id}->{notinetv} = {%{$sources->{$trace_id}->{dbsources}}};
		$sources->{$trace_id}->{notindb} = {%{$sources->{$trace_id}->{etvsources}}};
		foreach my $etv_source (keys %{$sources->{$trace_id}->{notindb}}) {
			vsay 'TRACE', "Finding etv source \"$etv_source\" in db sources.\n";
			if($sources->{$trace_id}->{notinetv}->{$etv_source}) {
				delete $sources->{$trace_id}->{notindb}->{$etv_source};
				delete $sources->{$trace_id}->{notinetv}->{$etv_source}	
			} else {
				$compared_sources->{$trace_id}->{notindb}->{$etv_source} = 1;
			}
		}
	}
	return $compared_sources;
}

sub fill_etv_souces {
	my ($sources) =@_;
	foreach my $trace_id (keys %{$sources}) {
		vsay 'DEBUG', "Get etv report for trace id $trace_id\n";
		# running erro-trace-visualizer for getting source names for current trace
		my $etv_report = tmpnam();
		my @etv_args = ($config->{etv},
				"--engine=blast",
				'--report='.$sources->{$trace_id}->{path},
				"--reqs-out=$etv_report");
		vsay 'DEBUG', "Starting error-trace-visulaizer for trace $trace_id...\n";
		vsay 'TRACE', "@etv_args\n";
		system(@etv_args) and die"$!";
		# cooment prev and set that line for debug system('touch',$etv_report);
		vsay 'TRACE', "Remove trace ".$sources->{$trace_id}->{path}."\n";
		unlink $sources->{$trace_id}->{path};
		vsay 'TRACE', "Read sources list from $etv_report\n";
		# getting list with error trace sources
		open FILE, $etv_report or die"$!";
		while(<FILE>) {
			chomp $_;
			$_ =~ s/.*\/(csd_deg_dscv\/[0-9]+\/.*)/$1/ || $_ =~ s/.*\/ldv_tempdir\/driver\/(.*)/$1/;
			$sources->{$trace_id}->{etvsources}->{$_} = 1;	
		}
		close FILE;	
		unlink $etv_report;
		vsay 'TRACE', "Removing report $etv_report\n";
	}
}

sub get_db_trace_sources {
	# run the check db	
	my $loadsrc_report = tmpnam();
	my @loadsrc_args = ($config->{loadsrc},"--report=$loadsrc_report");
	vsay 'DEBUG', "Starting load-src.pl...\n";
	vsay 'TRACE', "@loadsrc_args\n";
	system(@loadsrc_args) and die"$!";
        my $twig=new XML::Twig();
        $twig->parsefile($loadsrc_report);
        my $listT=$twig->root;
        my $tmpdir = $listT->first_child('dir')->text;
	my $traces = {};
	foreach my $trace_info ($listT->children('trace')) {
		$traces->{$trace_info->att('id')}->{path} = "$tmpdir/".$trace_info->att('name');
		$traces->{$trace_info->att('id')}->{dbsources}->{$_->text}=1 foreach ($trace_info->children('source'));
	}
	unlink $loadsrc_report;
	return ($tmpdir, $traces);
}
