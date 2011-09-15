#! /usr/bin/perl -w


use DBI;
use English;
use Env qw(LDV_DEBUG LDV_KB_RECALC_DEBUG LDVDBHOST LDVDB LDVUSER LDVDBPASSWD);
use FindBin;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../shared/perl", "$FindBin::RealBin/../shared/perl/error-trace-visualizer");

# Add some nonstandard local Perl packages.
use Browser qw(call_stacks_eq call_stacks_ne);
use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info
  print_debug_debug print_debug_trace print_debug_all get_debug_level
  check_system_call);


################################################################################
# Subroutine prototypes.
################################################################################

# Delete records from KB cache in accordance with specified KB ids.
# args: reference to KB ids array or NULL (that implies all records).
# retn: nothing.
sub delete_cache($);

# Delete records from KB in accordance with specified KB ids.
# args: reference to KB ids array or NULL (that implies all records).
# retn: nothing.
sub delete_kb($);

# Generate cache that binds verification results with KB in accordance with
# specified KB ids..
# args: reference to KB ids array or NULL (that implies all records).
# retn: nothing.
sub generate_cache($);

# Process command-line options. To see detailed description of these options
# run script with --help option.
# args: no.
# retn: nothing.
sub get_opt();

# Print help message on the screen and exit.
# args: no.
# retn: nothing.
sub help();

# Upload schema or and common data to KB.
# args: no.
# retn: nothing.
sub init_kb();

# Obtain needed files and dirs and check their presence.
# args: no.
# retn: nothing.
sub prepare_files_and_dirs();


################################################################################
# Global variables.
################################################################################

# Common database handler.
my $dbh;

# Prefix for all debug messages.
my $debug_name = 'kb-recalc';

# The system mysql binary.
my $mysql_bin = 'mysql';
# String with mysql connection parameters.
my $mysql_connection;

# Sets of KB ids corresponding to some action.
my @kb_ids_delete;
my @kb_ids_new;
my @kb_ids_update_pattern;
my @kb_ids_update_pattern_script;
my @kb_ids_update_result;

# SQL script describing KB schema.
my $kb_schema = "$FindBin::RealBin/../knowledge-base/kb.sql";
my $kb_common_data = "$FindBin::RealBin/../knowledge-base/kb-common.sql";

# Command-line options. Use --help option to see detailed description of them.
my $opt_common_data;
my $opt_delete;
my $opt_help;
my $opt_init;
my $opt_init_cache;
my $opt_init_cache_db;
my $opt_init_cache_script;
my $opt_init_common_data;
my $opt_init_kb;
my $opt_init_schema;
my $opt_new;
my $opt_schema;
my $opt_update_pattern;
my $opt_update_pattern_script;
my $opt_update_result;

# A header and tail to be used for each executed script in KB cache (re)generating.
my $script_header =
"";
my $script_tail =
"0;";


################################################################################
# Main section.
################################################################################

# Obtain the debug level.
get_debug_level($debug_name, $LDV_DEBUG, $LDV_KB_RECALC_DEBUG);

print_debug_normal("Process the command-line options");
get_opt();

print_debug_normal("Check presence of needed files, executables and directories. Copy needed files and directories");
prepare_files_and_dirs();

if ($opt_init_schema or $opt_init_common_data)
{
  print_debug_normal("Upload KB schema or/and common KB data to the database");
  init_kb();
}

my $host;
$LDVDBHOST ? $host = $LDVDBHOST : $host = 'localhost';
$dbh = DBI->connect("DBI:mysql:database=$LDVDB;host=$host", $LDVUSER, $LDVDBPASSWD)
    or die("Couldn't connect to database: " . DBI->errstr);

if ($opt_init_cache_db or $opt_init_cache_script)
{
  if ($opt_new)
  {
    print_debug_normal("Calculate KB cache for new KB entities");
    generate_cache(\@kb_ids_new);
  }
  else
  {
    print_debug_normal("Start KB cache (re)generation");
    generate_cache(undef);
  }
}

if ($opt_delete)
{
  print_debug_normal("Delete records from KB cache");
  delete_cache(\@kb_ids_delete);
  # We need to delete records from KB just after corresponding records were
  # deleted from KB cache table because of foreign key constraint.
  print_debug_normal("Delete records from KB");
  delete_kb(\@kb_ids_delete);
}

if ($opt_update_pattern)
{
  print_debug_normal("Calculate KB cache for KB entities having updated pattern");
  generate_cache(\@kb_ids_update_pattern);
}

if ($opt_update_pattern_script)
{
  print_debug_normal("Calculate KB cache for KB entities having updated pattern script");
  generate_cache(\@kb_ids_update_pattern_script);
}

if ($opt_update_result)
{
  print_debug_normal("Nothing will be done for KB entities with updated results (by design)");
}

print_debug_normal("Make all successfully");


################################################################################
# Subroutines.
################################################################################

sub delete_cache($)
{
  my $kb_ids_ref = shift;

  if ($kb_ids_ref)
  {
    my @kb_ids = @{$kb_ids_ref};
    print_debug_trace("Delete records from KB cache with KB ids '@kb_ids'...");
    $dbh->do("DELETE FROM results_kb WHERE results_kb.kb_id in (@kb_ids)") or die($dbh->errstr);
    print_debug_debug("KB cache records were deleted successfully");
  }
  else
  {
    print_debug_trace("Drop the whole KB cache...");
    $dbh->do('DELETE FROM results_kb') or die($dbh->errstr);
    print_debug_debug("KB cache was dropped successfully");
  }
}

sub delete_kb($)
{
  my $kb_ids_ref = shift;

  if ($kb_ids_ref)
  {
    my @kb_ids = @{$kb_ids_ref};
    print_debug_trace("Delete records from KB with KB ids '@kb_ids'...");
    $dbh->do("DELETE FROM kb WHERE id in (@kb_ids)") or die($dbh->errstr);
    print_debug_debug("KB records were deleted successfully");
  }
  else
  {
    print_debug_trace("Drop the whole KB...");
    $dbh->do('DELETE FROM kb') or die($dbh->errstr);
    print_debug_debug("KB was dropped successfully");
  }
}

sub generate_cache($)
{
  my $kb_ids_ref = shift;
  my $kb_ids_str = '';
  my $kb_ids_in = '';
  my @kb_ids;

  if ($kb_ids_ref)
  {
    @kb_ids = @{$kb_ids_ref};
    $kb_ids_str = " for KB ids '@kb_ids'";
    $kb_ids_in = " AND kb.id in (@kb_ids) ";
  }

  print_debug_trace("Generate KB cache$kb_ids_str...");

  if ($opt_init_cache_db or $opt_update_pattern)
  {
    # Before fast initialization of the whole KB cache by means of db tools
    # we need to delete the whole cache. Also we need to delete those records
    # from KB cache that corresponds to KB entities with updated patterns.
    if ($kb_ids_ref)
    {
      delete_cache($kb_ids_ref)
        if ($opt_update_pattern);
    }
    else
    {
      delete_cache(undef);
    }

    print_debug_trace("Begin to perform fast KB cache initialization$kb_ids_str...");
    $dbh->do(
      "INSERT INTO results_kb
       SELECT traces.id, kb.id, IF(kb.script IS NULL, 'Exact' , 'Require script')
       FROM kb, launches
         LEFT JOIN traces on traces.id=launches.trace_id
         LEFT JOIN rule_models on rule_models.id=launches.rule_model_id
         LEFT JOIN scenarios on scenarios.id=launches.scenario_id
       WHERE traces.result='unsafe'
         AND IF(kb.model is NULL, 1, rule_models.name like kb.model) = 1
         AND IF(kb.module is NULL, 1, scenarios.executable like kb.module) = 1
         AND IF(kb.main is NULL, 1, scenarios.main like kb.main) = 1
         $kb_ids_in") or die($dbh->errstr);
    print_debug_debug("Fast KB cache initialization was performed successfully");
  }

  # This seems to require too much time. So, separate it from the fast cache
  # initialization.
  if ($opt_init_cache_script or $opt_update_pattern_script)
  {
    # Specify that KB cache recalculation by means of corresponding scripts is
    # required.
    if ($opt_update_pattern_script)
    {
      $dbh->do("UPDATE results_kb SET fit='Require script' WHERE kb_id in (@kb_ids)")
         or die($dbh->errstr);
    }

    print_debug_trace("Begin to perform KB cache initialization with scripts$kb_ids_str...");
    my $all_data = $dbh->selectall_arrayref(
      "SELECT rule_models.name, scenarios.executable, scenarios.main, kb.script, traces.id, kb.id, traces.error_trace, kb.error_trace
       FROM launches
         LEFT JOIN traces on traces.id=launches.trace_id
         LEFT JOIN results_kb on traces.id=results_kb.trace_id
         LEFT JOIN kb on kb.id=results_kb.kb_id
         LEFT JOIN rule_models on rule_models.id=launches.rule_model_id
         LEFT JOIN scenarios on scenarios.id=launches.scenario_id
       WHERE results_kb.fit='Require script'
       $kb_ids_in") or die($dbh->errstr);

    foreach my $data (@{$all_data}) {
      my ($model, $module, $main, $script, $trace_id, $kb_id, $error_trace, $kb_error_trace) = @{$data};

      print_debug_trace("Execute script '$script' with model '$model', module '$module', main '$main', error trace ... and KB error trace ...");
      my $ret = eval("$script_header\n$script\n$script_tail");

      if ($EVAL_ERROR)
      {
        print_debug_warning("Couldn't execute script '$script': \n'$EVAL_ERROR'");
        next;
      }

      if ($ret)
      {
        print_debug_debug("Script failed");
        # In this case we should delete corresponding record from KB cache.
        $dbh->do(
          "DELETE FROM results_kb WHERE trace_id=$trace_id AND kb_id=$kb_id") or die($dbh->errstr);
        print_debug_debug("Remove from KB cache record with trace id '$trace_id' and KB id '$kb_id'");
      }
      else
      {
        print_debug_debug("Script passed");
        # In this case we should set corresponding record from KB cache as 'Exact'.
        $dbh->do(
          "UPDATE results_kb SET results_kb.fit='Exact' WHERE trace_id=$trace_id AND kb_id=$kb_id") or die($dbh->errstr);
        print_debug_debug("Update KB cache record (change fit from 'Require script' to 'Exact') with trace id '$trace_id' and KB id '$kb_id'");
      }
    }

    print_debug_debug("KB cache initialization with scripts application was performed successfully");
  }

  print_debug_debug("KB cache was generated successfully");
}

sub get_opt()
{
  unless (GetOptions(
    'common-data=s' => \$opt_common_data,
    'delete=s' => \$opt_delete,
    'help|h' => \$opt_help,
    'init' => \$opt_init,
    'init-cache' => \$opt_init_cache,
    'init-cache-db' => \$opt_init_cache_db,
    'init-cache-script' => \$opt_init_cache_script,
    'init-common-data' => \$opt_init_common_data,
    'init-kb' => \$opt_init_kb,
    'init-schema' => \$opt_init_schema,
    'new=s' => \$opt_new,
    'schema=s' => \$opt_schema,
    'update-pattern=s' => \$opt_update_pattern,
    'update-pattern-script=s' => \$opt_update_pattern_script,
    'update-result=s' => \$opt_update_result))
  {
    warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
    help();
  }

  help() if ($opt_help);

  # Check consistency.
  die("Don't specify both --update-pattern or --update-pattern-script together with --init-cache or --init-cache-kb or --init-cache-script")
    if (($opt_update_pattern or $opt_update_pattern_script)
      and ($opt_init_cache or $opt_init_cache_db or $opt_init_cache_script));

  # Full initialization includes both KB and cache initializations.
  $opt_init_kb = $opt_init_cache = 1 if ($opt_init);

  # KB initialization implies KB schema uploading as well as KB data.
  $opt_init_schema = $opt_init_common_data = 1 if ($opt_init_kb);

  print_debug_debug("KB schema will be uploaded to the specified database")
    if ($opt_init_schema);

  print_debug_debug("Common KB data will be uploaded to the specified database")
    if ($opt_init_common_data);

  # Both cache initializations will be performed in this case.
  $opt_init_cache_db = $opt_init_cache_script = 1 if ($opt_init_cache);

  if ($opt_delete)
  {
    @kb_ids_delete = split('/,/', $opt_delete);
    print_debug_debug("Deleted KB ids are '@kb_ids_delete'");
  }
  if ($opt_new)
  {
    @kb_ids_new = split('/,/', $opt_new);
    print_debug_debug("New KB ids are '@kb_ids_new'");
  }
  if ($opt_update_pattern)
  {
    @kb_ids_update_pattern = split('/,/', $opt_update_pattern);
    print_debug_debug("KB ids with updated pattern '@kb_ids_update_pattern'");
  }
  if ($opt_update_pattern_script)
  {
    @kb_ids_update_pattern_script = split('/,/', $opt_update_pattern_script);
    print_debug_debug("KB ids with updated pattern script '@kb_ids_update_pattern_script'");
  }
  if ($opt_update_result)
  {
    @kb_ids_update_result = split('/,/', $opt_update_result);
    print_debug_debug("KB ids with updated result '@kb_ids_update_result'");
  }

  print_debug_debug("The command-line options are processed successfully");
}

sub help()
{
    print(STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to initialize and recalculate
    Knowledge Base.

SYNOPSIS
  $PROGRAM_NAME [option...]

OPTIONS

  --common-data <file>
    Path to user defined common data to be uploaded to KB instead of
    the default one.

  --delete <ids>
    KB ids for which corresponding KB cache records will be deleted.

  -h, --help
    Print this help and exit with a error.

  --init
    Means both KB and cache initializations.

  --init-cache
    Synonym for --init-cache-db and --init-cache-script.

  --init-cache-db
    Fast initialization of KB cache by means of database tools.

  --init-cache-script
    Addition to the --init-cache-db option. Except database tools
    relevant scripts will be involved. After all either corresponding
    exact cache records will be obtained or they will be removed.

  --init-common-data
    Upload common data to the specified KB.

  --init-kb
    Means that common data will be uploaded to KB. It turns on
    --init-schema.

  --init-schema
    Upload KB schema to a specified database. Note that the given
    database should contain statistics database schema uploaded.

  --new <ids>
    New KB ids for which corresponding KB cache records will be
    calculated in depence on --init-cache-db and --init-cache-script
    options.

  --schema <file>
    Path to user defined KB schema to be uploaded to KB instead of
    the default one.

  --update-pattern <ids>
    KB ids with updated patterns. For them corresponding KB cache
    records will be recalculated just in the fast manner. Don't use
    --init-cache, --init-cache-db and --init-cache-script together
    with the given option.

  --update-pattern-script <ids>
    KB ids with updated pattern scripts. For them corresponding KB
    cache records will be recalculated with help of scripts. Don't use
    --init-cache, --init-cache-db and --init-cache-script together
    with the given option.

  --update-result <ids>
    Cache (re)generation isn't required in this case, so, nothing will
    be done.

ENVIRONMENT VARIABLES

  LDV_DEBUG
    It's an optional environment variable that specifies a debug
    level. It uses the standard designatures to distinguish different
    debug information printings. Each next level includes all previous
    levels and its own messages.

  LDV_KB_RECALC_DEBUG
    Like LDV_DEBUG but it has more priority. It specifies a debug
    level just for this instrument.

  LDVDBHOST, LDVDB, LDVUSER, LDVDBPASSWD
    Keeps settings (host, database, user and password) for connection
    to the database. Note that LDVDB and LDVUSER must always be
    presented!

EOM

  exit(1);
}

sub init_kb()
{
  if ($opt_init_schema)
  {
    my $schema = $kb_schema;
    $schema = $opt_schema if ($opt_schema);
    print_debug_info("Execute the command '$mysql_connection < $schema'");
    `$mysql_connection < $schema`;

    if (!$CHILD_ERROR and $opt_init_common_data)
    {
      my $common_data = $kb_common_data;
      $common_data = $opt_common_data if ($opt_common_data);
      print_debug_info("Execute the command '$mysql_connection < $common_data'");
      `$mysql_connection < $common_data`;
    }

    die("There is no the mysql executable in your PATH!")
      if (check_system_call() == -1);
    # This is checked separately since mysql isn't the part of the LDV toolset but
    # it's too important for toolset.
    die("The mysql returns '" . ($CHILD_ERROR >> 8) . "'")
      if ($CHILD_ERROR >> 8);
  }
}

sub prepare_files_and_dirs()
{
  print_debug_trace("Check that database connection is setup");
  die("You don't setup connection to your database. See --help for details")
    unless ($LDVDB and $LDVUSER);

  $mysql_connection = "$mysql_bin --user=$LDVUSER $LDVDB";
  $mysql_connection .= " --host=$LDVDBHOST" if ($LDVDBHOST);
  $mysql_connection .= " --password=$LDVDBPASSWD" if ($LDVDBPASSWD);
  print_debug_debug("Connection to mysql is '$mysql_connection'");

  if ($opt_init_schema)
  {
    if ($opt_schema)
    {
      print_debug_trace("Check presence of user specified KB database schema");
      die("KB schema '$opt_schema' doesn't exist") if (!-f $opt_schema);
    }
    else
    {
      print_debug_trace("Check presence of default KB database schema");
      die("KB schema '$kb_schema' doesn't exist") if (!-f $kb_schema);
    }
  }

  if ($opt_init_common_data)
  {
    if ($opt_common_data)
    {
      print_debug_trace("Check presence of user specified common KB data");
      die("Common KB data '$opt_common_data' doesn't exist") if (!-f $opt_common_data);
    }
    else
    {
      print_debug_trace("Check presence of default common KB data");
      die("Common KB data '$kb_common_data' doesn't exist") if (!-f $kb_common_data);
    }
  }
}
