#! /usr/bin/perl -w

# Update PPoB.

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

my @developers_columns=('author', 'committer');
my $main_table = 'bugs';

sub help();
sub connect_to_db($$$$);
sub update_ppob($$);
################################################################################
# Main section.
################################################################################

get_debug_level("update-ppob", $LDV_DEBUG, $LDV_UPLOAD_DEBUG);

my $ppob_dbh = connect_to_db($ppob_db, $ppob_host, $ppob_user, $ppob_password);

my $print_help;
my $is_old_kb_format;
my $is_unsafes;

my $table;
my %new_info;

GetOptions(
	'help|h' => \$print_help, # Print help.
	'table=s' => \$table,
	'values=s' => \%new_info,
	) or help();

if ($print_help)
{
	help();
}

if (!$table)
{
	help();
}

print_debug_debug("Table to be updated is $table");

foreach my $column (keys %new_info)
{
	print_debug_debug("Column to be updated is $column, new value will be set to '$new_info{$column}'");
}

# TODO:
#check_columns($table, \%new_info);

update_ppob($table, \%new_info); # Update table 'bugs' with columns 'id' (required), 'fix_time', 'author', 'committer', 'commit'.

################################################################################
# Subroutines.
################################################################################

sub help() {
    print( STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to update information in the Public Pool of Bugs.

SYNOPSIS
  $PROGRAM_NAME --table <table_name> [--values <column>=<new_value>]

OPTIONS

  -h, --help
    Print this help and exit with a error.
  --table
  	The name of the table, in which columns should be updated/inserted.
  --values
  	Inserted/updated columns with new values.
  	If column 'id' was specified, then the corresponding row will be updated,
  	otherwise new row will be inserted.

ENVIRONMENT VARIABLES

  LDV_UPLOAD_DEBUG
    It is an optional environment variable that specifies a debug
    level. It uses the standard designatures to distinguish different
    debug information printings. Each next level includes all previous
    levels and its own messages.

  LDVDBHOST, LDVDB, LDVUSER, LDVDBPASSWD
    Keeps settings (host, database, user and password) for connection
    to the PPoB database. Note that LDVDB and LDVUSER must always be
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
        $ppob_dbh->disconnect;
        print_debug_normal("Disconnecting from $name database");
    }
}

sub check_columns()
{
	my $table = shift;
	my $values_ref = shift;
	my %values = %{$values_ref};
	
	print_debug_debug("Checking table '$table' for existence'");
	
	my $res = sql_select("SELECT table_name FROM information_schema.tables WHERE table_name='$table';", $ppob_dbh);
	if (!$res)
	{
		die "Error: Table to be updated '$table' doesn't exist.";
	}
	
	my @available_columns;
	my $get_columns_query = $ppob_dbh->prepare("SELECT column_name FROM information_schema.columns WHERE table_name='$table';")
		or die( "Can't prepare a query: " . $ppob_dbh->errstr );
    $get_columns_query->execute or die( "Can't execute a query: " . $ppob_dbh->errstr );
	while (my @tmp = $get_columns_query->fetchrow_array())
	{
		push (@available_columns, $tmp[0]);
	}
	
	print_debug_debug("Available for table '$table' columns are");
	foreach my $tmp (@available_columns)
	{
		print_debug_debug(" - $tmp");
	}
	
	foreach my $column (keys %values)
	{
		print_debug_debug("Checking column '$column' for existence");
		if (!($column ~~ @available_columns))
		{
			die "Error: Column to be updated '$column' doesn't exist in the table '$table'.";
		}
	}
}

sub update_ppob($$)
{
	my $table = shift;
	my $values_ref = shift;
	my %values = %{$values_ref};
	
	# Check for id column. If this column exist then corresponding row will be updating, 
	# otherwise new column will be inserted.
	my $id = $values{'id'};
	delete $values{'id'};
	
	my $is_main_table = ($table eq $main_table);
	if ($is_main_table)
	{
		my %developers;
		foreach my $cur_dev (@developers_columns)
		{
			$developers{$cur_dev}=$values{$cur_dev};
			delete $values{$cur_dev};
			
			if ($developers{$cur_dev})
			{
				my $cur_dev_id = sql_select(
					"SELECT id FROM developers WHERE (name = '$developers{$cur_dev}') LIMIT 1;", $ppob_dbh)
				|| sql_insert(
					"INSERT INTO developers (name) VALUES ('$developers{$cur_dev}');", $ppob_dbh);
				$values{"$cur_dev"."_id"}=$cur_dev_id;
			}
		}
	}
	
	if ($id) # Update.
	{
		update_table($table, \%values, $id);
	}
	else # Insert.
	{
		insert_table($table, \%values);
	}
}

sub update_table($$)
{
	my $table = shift;
	my $values_ref = shift;
	my $id = shift;
	my %values = %{$values_ref};

	my $query = "UPDATE $table SET";
	my $is_comma = '';
	foreach my $column (keys %values)
	{
		if ($is_comma)
		{
			$query = $query.",";
		}
		else
		{
			$is_comma = 'y';
		}
		$query = $query." $column='$values{$column}'";
	}
	$query = $query." WHERE id='$id'";
	sql_query($query, $ppob_dbh);
}

sub insert_table($$)
{
	my $table = shift;
	my $values_ref = shift;
	my %values = %{$values_ref};

	my $query = "INSERT INTO $table (";
	my $is_comma = '';
	foreach my $column (keys %values)
	{
		if ($is_comma)
		{
			$query = $query.", ";
		}
		else
		{
			$is_comma = 'y';
		}
		$query = $query."$column";
	}
	$query = $query.") VALUES (";
	$is_comma = '';
	foreach my $column (keys %values)
	{
		if ($is_comma)
		{
			$query = $query.", ";
		}
		else
		{
			$is_comma = 'y';
		}
		$query = $query."'$values{$column}'";
	}
	$query = $query.");";
	sql_query($query, $ppob_dbh);
}

=com

sub sync_kb_with_ppob {
    my $kb_query;
    if (!$is_unsafes) # Get all records from KB (default).
    {
        $kb_query = get_kb_records();
    }
    else # Get all unsafes (not just marked in KB).
    {
        # TODO: Should this option be available?
        # Currently this option gets all unsafes without any KB specific columns (all verdicts are considered as 'Unknown').
        $kb_query = get_unsafes();
    }

    # Lock PPoB DB.
    print_debug_normal("Locking PPoB data base");
    sql_query("
    	LOCK TABLES environments WRITE, modules WRITE, rule_specifications WRITE, verifiers WRITE, traces WRITE, sources WRITE, 
    	traces_sources WRITE, possible_bugs WRITE, bugs WRITE, developers WRITE\n", $ppob_dbh);

    # Start transaction.
    print_debug_normal("Starting commit");
    $ppob_dbh->begin_work;

    while (my @tmp_array = $kb_query->fetchrow_array())
    {
    	# Get all data for current KB record.
        my %result = parse_kb_record(@tmp_array);

        # Store %result in PPoB.
        store_kb_record(\%result);
    }

	# Finish transaction.
    $ppob_dbh->commit;
    print_debug_normal("Commit to the PPoB DB has been completed");

	# Unlock PPoB DB.
    print_debug_normal("Unlocking PPoB DB");
    sql_query("UNLOCK TABLES;\n", $ppob_dbh);
}

sub get_kb_records()
{
    # TODO: Should we take every pair of 'results_kb.trace_id'-'results_kb.kb_id' or just the first one?
	# For a given 'results_kb.kb_id' different values of 'results_kb.trace_id' mean different SVT for a given bug.
	# Currently only one pair will be added into th PPoB.
	my $query = "
	SELECT kb.model, kb.module, kb.main, kb.verdict, kb.comment, environments.version, kb.error_trace, toolsets.verifier, res.trace_id, kb.id";
	if (!$is_old_kb_format)
	{
		$query = $query.", kb.found_time, kb.fix_time, kb.author, kb.committer, kb.commit"
	}
	$query = $query." 
	FROM kb, results_kb AS res
	    LEFT JOIN traces on res.trace_id=traces.id
	    LEFT JOIN launches on traces.id=launches.trace_id
	    LEFT JOIN environments on launches.environment_id=environments.id
	    LEFT JOIN toolsets on launches.toolset_id=toolsets.id
	WHERE 
	    kb.id=res.kb_id AND 
	    res.trace_id=(
	        SELECT MIN(trace_id) 
	        FROM results_kb AS res2 
	        WHERE res2.kb_id=kb.id)";
	my $db_query = $kb_dbh->prepare($query) or die( "Can't prepare a query: " . $kb_dbh->errstr );
    $db_query->execute or die( "Can't execute a query: $query\n" . $kb_dbh->errstr );
    print_debug_all("Executing query: '$query'");
    return $db_query;
}

sub get_unsafes()
{
	my $query = "
	SELECT rule_models.name, drivers.name, scenarios.main, 'Unknown', '', environments.version, traces.error_trace, toolsets.verifier, traces.id, ''
	FROM traces
	    LEFT JOIN launches on launches.trace_id=traces.id
	    LEFT JOIN environments on launches.environment_id=environments.id
	    LEFT JOIN toolsets on launches.toolset_id=toolsets.id
	    LEFT JOIN rule_models on launches.rule_model_id=rule_models.id
	    LEFT JOIN drivers on launches.driver_id=drivers.id
	    LEFT JOIN scenarios on launches.scenario_id=scenarios.id
	WHERE result='unsafe';";
	my $db_query = $kb_dbh->prepare($query) or die( "Can't prepare a query: " . $kb_dbh->errstr );
    $db_query->execute or die( "Can't execute a query: $query\n" . $kb_dbh->errstr );
    print_debug_all("Executing query: '$query'");
    return $db_query;
}

# Current format of array:
# rule, module, main, verdict, comment, kernel, trace, verifier, trace_id, kb_id, found_time, fix_time, author, committer, commit.
# Last 5 arguments are optional.
sub parse_kb_record
{
	my @array_of_values = @_;
	my %result;
	my $tmp_trace_id;
	($result{'rule'}, $result{'module'}, $result{'main'}, $result{'verdict'}, $result{'comment'}, $result{'kernel'}, $result{'trace'}, $result{'verifier'}, $tmp_trace_id, $result{'id'}, $result{'found_time'}, $result{'fix_time'}, $result{'author'}, $result{'committer'}, $result{'commit'}) = @array_of_values;
	# Get all sources.
	my $query_src = "
		SELECT sources.name, sources.contents
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
    $result{'src'} = \%result_src;
    return %result;
}

# Insert/update parsed KB record into the PPoB DB.
sub store_kb_record
{
	my $ref = shift;
	my %result = %{$ref};

	my $kernel = $result{'kernel'};
    my $module = $result{'module'};
    my $rule = $result{'rule'};
    my $verifier = $result{'verifier'};
    my $trace = $ppob_dbh->quote($result{'trace'});
    my %sources = %{$result{'src'}};
    my $verdict = $result{'verdict'} || 'Unknown';
    my $comment = $result{'comment'} || '';
    my $found_time = $result{'found_time'} || '';
    my $fix_time = $result{'fix_time'} || '';
    my $author = $result{'author'} || 'Unknown';
    my $committer = $result{'committer'} || 'Unknown';
    my $commit = $result{'commit'} || '';
    my $main = $result{'main'};

    print_debug_debug("Updating PPoB tables for kb_id=$result{'id'}");

    # Table 'environments'.
    my $cur_environment_id = sql_select(
        "SELECT id FROM environments WHERE (version = '$kernel') LIMIT 1;", $ppob_dbh)
    || sql_insert(
        "INSERT INTO environments (version) VALUES ('$kernel');", $ppob_dbh);

    # Table 'modules'.
    my $cur_module_id = sql_select(
        "SELECT id FROM modules WHERE (name = '$module') LIMIT 1;", $ppob_dbh)
    || sql_insert(
        "INSERT INTO modules (name) VALUES ('$module');", $ppob_dbh);

    # Table 'rule_specifications'.
    my $cur_rule_id = sql_select(
        "SELECT id FROM rule_specifications WHERE (name = '$rule') LIMIT 1;", $ppob_dbh)
    || sql_insert(
        "INSERT INTO rule_specifications (name) VALUES ('$rule');", $ppob_dbh);

    # Table 'verifiers'.
    my $cur_verifier_id = sql_select(
        "SELECT id FROM verifiers WHERE (name = '$verifier') LIMIT 1;", $ppob_dbh)
    || sql_insert(
        "INSERT INTO verifiers (name) VALUES ('$verifier');", $ppob_dbh);

    # Table 'traces'.
    # TODO: Should any trace be added into the PPoB or just different ones?
    # Currently: only different traces (full equavalence).
    # TODO: Is there any need for more complex comparison algorithms (like 'tree' or 'mf').
    my $cur_trace_id = sql_select(
        "SELECT id FROM traces WHERE (svt = $trace) LIMIT 1;", $ppob_dbh)
    || sql_insert(
        "INSERT INTO traces (svt) VALUES ($trace);", $ppob_dbh);

    # Tables 'sources' and 'traces_sources'.
    # Only source files with different pathes will be added.
    foreach my $path (keys %sources)
    {
    	my $content = $ppob_dbh->quote($sources{$path});
        my $cur_source_id = sql_select(
            "SELECT id FROM sources WHERE (path = '$path') LIMIT 1;", $ppob_dbh)
        || sql_insert(
            "INSERT INTO sources (path, content) VALUES ('$path', $content);", $ppob_dbh);
        sql_select(
            "SELECT * FROM traces_sources WHERE trace_id=$cur_trace_id and source_id=$cur_source_id LIMIT 1;", $ppob_dbh)
        || sql_query(
            "INSERT INTO traces_sources (trace_id, source_id) VALUES ($cur_trace_id, $cur_source_id);", $ppob_dbh);
    }

    # Table 'developers'.
    # TODO: Is this table needed to store authors/committers?
    # Currently author and committers are considered as developers.
    # If author or committer wasn't specified, than they will be considered as 'Unknown'.
    # This table only make sense for true positives.
    my $cur_author_id = sql_select(
        "SELECT id FROM developers WHERE (name = '$author') LIMIT 1;", $ppob_dbh)
    || sql_insert(
        "INSERT INTO developers (name) VALUES ('$author');", $ppob_dbh);
    my $cur_committer_id = sql_select(
        "SELECT id FROM developers WHERE (name = '$committer') LIMIT 1;", $ppob_dbh)
    || sql_insert(
        "INSERT INTO developers (name) VALUES ('$committer');", $ppob_dbh);   

    # Table 'possible_bugs'.
    # 'kernel-module-rule-verifier-trace' is unique. Old records will be updated.
    my $cur_possible_bug_id = sql_select("
    	SELECT id FROM possible_bugs 
        WHERE 
        	environment_id=$cur_environment_id AND
            module_id=$cur_module_id AND
            rule_specification_id=$cur_rule_id AND
            verifier_id=$cur_verifier_id AND
            trace_id=$cur_trace_id
        LIMIT 1;",
        $ppob_dbh);
    my $is_update = ($cur_possible_bug_id != 0);
    if ($is_update) # Update.
    {
    	sql_query("
        	UPDATE possible_bugs 
            SET 
            	verdict='$verdict',
                comment='$comment',
                entry_point='$main',
                found_time='$found_time'
            WHERE id = $cur_possible_bug_id", 
            $ppob_dbh);
    }
    else # Insert.
    {
    	$cur_possible_bug_id = sql_insert(
            "INSERT INTO possible_bugs 
            	(environment_id, module_id, rule_specification_id, verifier_id, trace_id, 
            	verdict, comment, found_time, entry_point) 
            VALUES 
            	($cur_environment_id, $cur_module_id, $cur_rule_id, $cur_verifier_id, $cur_trace_id, 
            	'$verdict', '$comment', '$found_time', '$main');", 
            $ppob_dbh);
	}

	# Table 'bugs'. Extension of table 'possible_bugs' for true positives.
	# TODO: What to do if possible bug was updated from 'True positive' to anything else?
	# (delete corresponding record in 'bugs' or not?)
	if ($verdict eq 'True positive')
	{
		my $cur_bug_id = sql_select("
        	SELECT id FROM bugs 
            WHERE
            	possible_bug_id=$cur_possible_bug_id
            LIMIT 1;",
            $ppob_dbh);
        $is_update = ($cur_bug_id != 0);
		if ($is_update) # Update.
        {
        	sql_query("
        		UPDATE bugs 
                SET
                	fix_time='$fix_time',
                    author_id=$cur_author_id,
                    committer_id=$cur_committer_id,
                    commit='$commit'
                WHERE id = $cur_bug_id", 
                $ppob_dbh);
        }
        else # Insert.
        {
        	sql_query("
        		INSERT INTO bugs 
                	(possible_bug_id, fix_time, author_id, committer_id, commit) 
                VALUES 
                	($cur_possible_bug_id, '$fix_time', $cur_author_id, $cur_committer_id, '$commit');", 
                $ppob_dbh);
		}
	}
}
=cut
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
    disconnect_from_db($ppob_dbh,'PPoB');
}

