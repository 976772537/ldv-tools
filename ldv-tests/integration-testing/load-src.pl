#!/usr/bin/perl -w

use FindBin;

BEGIN {
        $ENV{'LDV_HOME'} ||= "$FindBin::Bin/../../";
        push @INC,"$ENV{'LDV_HOME'}/shared/perl";
}

sub usage{ print STDERR<<usage_ends;

Usage:
        LDV_DEBUG=debuglevel DBUSER=dbuser DBPASS=dbpass DBHOST=dbhost DBNAME=dbname load-src.pl -r filelist.xml

usage_ends
        die;
}

use File::Temp qw/tempfile/;
use Getopt::Long qw(:config require_order);

my $config = {
	verbosity => $ENV{'LDV_DEBUG'} || 'NORMAL',
        dbuser => $ENV{'DBUSER'},
        dbpass => $ENV{'DBPASS'},
	dbhost => $ENV{'DBHOST'} || 'localhost',
	dbname => $ENV{'DBNAME'}
};

GetOptions(
       'report|r=s'=>\$config->{report},
       'tracedir|t=s'=>\$config->{tracedir},
) or usage;

defined $config->{report} or usage;
-f $config->{report} and die'Output file already exists.';
#defined $config->{tracedir} or usage;
#-d $config->{tracedir} or mkdir $config->{tracedir};

use DBI;
use XML::Twig;
use File::Temp qw/ :POSIX /;
use LDV::Utils;

LDV::Utils::set_verbosity($config->{verbosity});
LDV::Utils::push_instrument('load-src');

##############################################
#   SUB
##############################################
sub init_db_connection;
sub check_trcace_sources;
sub check_if_exists;

vsay 'NORMAL', "Start checking your LDV database.\n";
init_db_connection($config);
get_trace_lists($config);
vsay 'NORMAL', "Finished.\n";

sub init_db_connection {
	my ($config) = @_;
	defined $config->{dbname} or die'Please, specify database name.';
	defined $config->{dbuser} or die'Please, specify database user.';
	# test our datbase connection
	my $dsn = "DBI:mysql:$config->{dbname}:$config->{dbhost}";
	vsay 'DEBUG', "Connection string: \"$dsn\".\n";
	vsay 'TRACE', "DB User: $config->{dbuser}\n";
	vsay 'TRACE', "DB Pass: *****\n";
	vsay 'TRACE', "DB Host: $config->{dbhost}\n";
	vsay 'TRACE', "DB Name: $config->{dbname}\n";
	$config->{conn} = DBI->connect($dsn, $config->{dbuser}, $config->{dbpass}) or exit 1;
}


sub get_trace_lists {
	
	my $traces_info = {};
	my $dirname = tmpnam();
	mkdir $dirname or die"$!";

	# select traces from database
	my $sth_traces = $config->{conn}->prepare(qq{select id, verifier, error_trace from traces where result='unsafe'});

	$sth_traces->execute() or die;
	while (my ($trace_id, $verifier, $error_trace) = $sth_traces->fetchrow_array()) 
	{
		open FILE,">$dirname/$trace_id.trace" or die"$!";
		print FILE $error_trace;
		close FILE, or die"$!";

		vsay 'NORMAL', "Getting source list for trace number $trace_id...\n";
		# select all sources for this trace and prepare report file for etv
		my $sth_sources = $config->{conn}->prepare(qq{SELECT name FROM sources WHERE trace_id=$trace_id});

		$sth_sources->execute() or die;
		my $db_sources = ();
		while (my ($source_name) = $sth_sources->fetchrow_array()) {
			$source_name =~ s/.*?\/(.*)/$1/;
			push @$db_sources, $source_name;
		};
		my $trace_info = {
			sources => $db_sources,
			trace => $error_trace
		};
		$sth_sources->finish() or die;
		$traces_info->{$trace_id} = $trace_info;
	}
	$sth_traces->finish() or die;


	# printing to file
	my $twig = XML::Twig->new();
	$twig->set_xml_version( '1.0');
	my $listT = XML::Twig::Elt->new('list');
	foreach my $trace_id (keys %$traces_info) {
		my $traceT = XML::Twig::Elt->new('trace');
		$traceT->set_att('id',$trace_id);
		$traceT->set_att('name',"$trace_id.trace");
		XML::Twig::Elt->new('source',$_)->paste($traceT) foreach (@{$traces_info->{$trace_id}->{sources}});
		$traceT->paste($listT);
	}
	XML::Twig::Elt->new('dir', $dirname)->paste($listT);
	$twig->set_root($listT);
	$twig->set_pretty_print('indented');
	$twig->print_to_file($config->{report});
}
