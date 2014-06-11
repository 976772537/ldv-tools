#! /usr/bin/perl -w

# Update PPoB according to KB.

use XML::Simple;
use DBI;
use English;
use FindBin;
use Env
  qw(LDVDBHOST LDVDB LDVUSER LDVDBPASSWD LDV_UPLOAD_DEBUG LDV_DEBUG);
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;
use File::Temp qw/ tempdir /;
use Cwd;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../shared/perl");
# Add some nonstandard local Perl packages.
use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info
  print_debug_debug print_debug_trace print_debug_all get_debug_level
  check_system_call);

################################################################################
# Global variables.
################################################################################

# The default database host and password. They're used when no host is specified
# through the environment variables.
my $kb_host = $LDVDBHOST || 'localhost';
my $kb_password = $LDVDBPASSWD || '';
my $kb_user = $LDVUSER;
my $kb_db = $LDVDB;

sub help();
sub connect_to_db($$$$);
sub publish($$);
################################################################################
# Main section.
################################################################################

get_debug_level("ppob-publisher", $LDV_DEBUG, $LDV_UPLOAD_DEBUG);

my $dbh = connect_to_db($kb_db, $kb_host, $kb_user, $kb_password);

my $print_help;
my $is_old_kb_format;
my $is_unsafes;
my $output;
my $id;

GetOptions(
	'help|h' => \$print_help, # Print help.
	'id=s' => \$id, # Trace id.
	'output|o=s'  => \$output # Output file.
	) or help();

help() if ($print_help);

print_debug_debug("Trace id to be published: $id");
print_debug_debug("Output file: $output") if ($output);

die "Error: trace id was not specified." if (!$id);
die "Error: output file was not specified." if (!$output);
publish($id, $output);

################################################################################
# Subroutines.
################################################################################

sub help() {
    print( STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to publish information from the Knowledge base into the Public Pool of Bugs.

SYNOPSIS
  $PROGRAM_NAME [options]

OPTIONS

  -h, --help
    Print this help and exit with a error.
  --id
  	Trace id for published record. 
  --output
  	Specify output file. 	

ENVIRONMENT VARIABLES

  LDV_UPLOAD_DEBUG
    It is an optional environment variable that specifies a debug
    level. It uses the standard designatures to distinguish different
    debug information printings. Each next level includes all previous
    levels and its own messages.

  LDVDBHOST, LDVDB, LDVUSER, LDVDBPASSWD
    Keeps settings (host, database, user and password) for connection
    to the KB database. Note that LDVDB and LDVUSER must always be
    presented!

EOM

    exit(1);
}

sub connect_to_db($$$$) {
    my $db = shift;
    my $host = shift;
    my $user = shift;
    my $password = shift;
    
    # Check environment variables.
    if ( !$db )
    {
    	die "Error: Database was not specified. Please specify it with environment variable LDVDB.";
    }
    if ( !$user )
    {
    	die "Error: User was not specified. Please specify it with environment variable LDVUSER.";
    }
    # Connect to Database.
    my $db_handler =
      DBI->connect( "DBI:mysql:$db:$host", $user, $password )
      or die("Can't connect to the database: $DBI::errstr");
    print_debug_normal(
        "Connection to the data base $db has been established");
    print_debug_normal("Host name is: $host");
    print_debug_normal("User name is: $user");
    if ( $password eq '' ) {
        print_debug_normal("Using password: NO");
    }
    else {
        print_debug_normal("Using password: YES");
    }
    return $db_handler;
}

sub disconnect_from_db($$) {
	my $dbh = shift;
	my $name = shift;
    if ($dbh) {
        $dbh->disconnect;
        print_debug_normal("Disconnecting from $name database");
    }
}

sub publish($$) {
	my $id = shift;
	my $output = shift;

    my $kb_query = get_trace_info($id);

    my @tmp_array = $kb_query->fetchrow_array();

    # Get all data for current KB record.
    my %result = parse_kb_record(@tmp_array);

    # Store %result in specified output file.
    store_kb_record(\%result, $output);
}

sub get_trace_info($)
{
	my $id = shift;
	my $query = "
	SELECT environments.version, drivers.name, rule_models.name, toolsets.verifier, scenarios.main
	FROM traces
	    LEFT JOIN launches on launches.trace_id=traces.id
	    LEFT JOIN environments on launches.environment_id=environments.id
	    LEFT JOIN toolsets on launches.toolset_id=toolsets.id
	    LEFT JOIN rule_models on launches.rule_model_id=rule_models.id
	    LEFT JOIN drivers on launches.driver_id=drivers.id
	    LEFT JOIN scenarios on launches.scenario_id=scenarios.id
	WHERE traces.id=$id
	LIMIT 1;";
	my $db_query = $dbh->prepare($query) or die( "Can't prepare a query: " . $dbh->errstr );
    $db_query->execute or die( "Can't execute a query: $query\n" . $dbh->errstr );
    print_debug_all("Executing query: '$query'");
    return $db_query;
}

# Current format of array:
# kernel, module, rule, verifier, main.
sub parse_kb_record
{
	my @array_of_values = @_;
	my %result;
	my $tmp_trace_id;
	($result{'kernel'}, $result{'module'}, $result{'rule'}, $result{'verifier'}, $result{'main'}) = @array_of_values;
    return %result;
}

# Insert/update parsed KB record into the PPoB DB.
sub store_kb_record($$)
{
	my $ref = shift;
	my %result = %{$ref};
	my $output = shift;

	open (OUTPUT, '>', $output) or die "Can't open file: \"$output\", $!";
	foreach my $arg (keys %result)
	{
		print OUTPUT "$arg=$result{$arg}&";
	}
	close OUTPUT or die "Can't close file: \"$output\", $!";
}

sub sql_select($$) {
    my $query = shift;
    my $dbh = shift;
    print_debug_all($query);

    my $db_query = $dbh->prepare($query)
      or die( "Can't prepare a query: " . $dbh->errstr );

    $db_query->execute or die( "Can't execute a query: $query\n" . $dbh->errstr );

    my @row = $db_query->fetchrow_array;

    return $row[0] || 0;
}

sub sql_insert($$) {
    my $query = shift;
    my $dbh = shift;
    print_debug_all($query);

    my $db_query = $dbh->prepare($query)
      or die( "Can't prepare a query: " . $dbh->errstr );

    $db_query->execute or die( "Can't execute a query: $query\n" . $dbh->errstr );

    return $db_query->{mysql_insertid};
}

sub sql_query($$) {
    my $query = shift;
    my $dbh = shift;
    print_debug_all($query);

    my $db_query = $dbh->do($query)
      or die( "Can't do a query: $query\n" . $dbh->errstr );
}

END {
    disconnect_from_db($dbh,'KB');
}

