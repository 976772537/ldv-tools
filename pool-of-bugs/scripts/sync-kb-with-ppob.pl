#! /usr/bin/perl -w

# Adds new info into the KB.

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
my $ppob_host = $LDVDBHOST || 'localhost';
my $ppob_password = $LDVDBPASSWD || '';
my $ppob_user = $LDVUSER;
my $ppob_db = $LDVDB;

sub help();
sub connect_to_db($$$$);

my $not_modified = '%';

################################################################################
# Main section.
################################################################################

get_debug_level( "sync-kb-with-ppob", $LDV_DEBUG, $LDV_UPLOAD_DEBUG );

my $ppob_dbh = connect_to_db($ppob_db, $ppob_host, $ppob_user, $ppob_password);

my $kb_host = 'localhost';
my $kb_password = '';
my $kb_user;
my $kb_db;
my $print_help;

GetOptions(
	'help|h' => \$print_help, # Print help.
	'host=s' => \$kb_host,
	'password=s' => \$kb_password,
	'user=s' => \$kb_user,
	'db=s' => \$kb_db
	) or help();

if ($print_help)
{
	help();
}

my $kb_dbh = connect_to_db($kb_db, $kb_host, $kb_user, $kb_password);

sync();

################################################################################
# Subroutines.
################################################################################

sub help() {
    print( STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to update information in the Knowledge base.

SYNOPSIS
  $PROGRAM_NAME --id=<kb_id> [<column_name>=<new_value>]

OPTIONS

  -h, --help
    Print this help and exit with a error.
  --id
  	Id of the Knowledge base entry to be updated.
  --find_time, --fix_time, --author, --committer, --commit
  	Possible columns to be updated.

ENVIRONMENT VARIABLES

  LDV_UPLOAD_DEBUG
    It is an optional environment variable that specifies a debug
    level. It uses the standard designatures to distinguish different
    debug information printings. Each next level includes all previous
    levels and its own messages.

  LDVDBHOST, LDVDB, LDVUSER, LDVDBPASSWD
    Keeps settings (host, database, user and password) for connection
    to the database. Note that LDVDB and LDVUSER must always be
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

sub disconnect_from_db() {
    if ($ppob_dbh) {
        $ppob_dbh->disconnect;
        print_debug_normal("Disconnecting from PPoB database");
    }
    if ($kb_dbh) {
        $kb_dbh->disconnect;
        print_debug_normal("Disconnecting from KB database");
    }
}

sub sync
{
    get_kb_info();
}

sub get_kb_info {
	my $query = 
	"SELECT kb.model, kb.module, kb.main, kb.verdict, kb.comment, kb.found_time, kb.fix_time, kb.author, environments.version, kb.error_trace, kb.committer, kb.commit, toolsets.verifier, traces.id
	 FROM kb
	    LEFT JOIN results_kb on results_kb.kb_id=kb.id
	    LEFT JOIN traces on results_kb.trace_id=traces.id
	    LEFT JOIN launches on traces.id=launches.trace_id
	    LEFT JOIN environments on launches.environment_id=environments.id
	    LEFT JOIN toolsets on launches.toolset_id=toolsets.id";
	
	my $db_query = $kb_dbh->prepare($query) or die( "Can't prepare a query: " . $kb_dbh->errstr );
    $db_query->execute or die( "Can't execute a query: $query\n" . $kb_dbh->errstr );
    while (my @tmp = $db_query->fetchrow_array())
    {
        my %result;
        $result{'rule'}=$tmp[0];
        $result{'module'}=$tmp[1];
        $result{'main'}=$tmp[2];
        $result{'verdict'}=$tmp[3];
        $result{'comment'}=$tmp[4];
        $result{'found_time'}=$tmp[5];
        $result{'fix_time'}=$tmp[6];
        $result{'author'}=$tmp[7];
        $result{'kernel'}=$tmp[8];
        $result{'trace'}=$tmp[9];
        $result{'committer'}=$tmp[10];
        $result{'commit'}=$tmp[11];
        $result{'verifier'}=$tmp[12];
        
        my $tmp_trace_id = $tmp[13];
        
        my $query_src = 
	    "SELECT sources.name, sources.contents
	     FROM traces
	        LEFT JOIN sources on sources.trace_id=traces.id
	     WHERE traces.id=$tmp_trace_id";
	    my $db_query_src = $kb_dbh->prepare($query_src) or die( "Can't prepare a query: " . $kb_dbh->errstr );
        $db_query_src->execute or die( "Can't execute a query: $query_src\n" . $kb_dbh->errstr );
        my %result_src;
        while (my @tmp_src = $db_query_src->fetchrow_array())
        {
            $result_src{$tmp_src[0]}=$tmp_src[1];
        }
        
        foreach my $path (keys %result_src)
        {
             print "SRC: $path\n";
        }
        
        foreach my $row (keys %result)
        {
            my $value = $result{$row};
            if ($row ne 'trace')
        	{
        	    print"$row:$value\n";
        	}
        }
        print "---------------------------------------\n";
    }
}

# Actions which should be completed in case of any errors or after finishing updating.
END {
    disconnect_from_db();
}

