#! /usr/bin/perl -w


use DBI;
use English;
use Env qw(LDV_DEBUG LDV_KB_RECALC_DEBUG LDVDBHOST LDVDB LDVUSER LDVDBPASSWD);
use FindBin;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../shared/perl");

# Add some nonstandard local Perl packages.
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

# Generate cache that binds verification results with KB.
# args: no.
# retn: nothing.
sub generate_cache();

# Process command-line options. To see detailed description of these options
# run script with --help option.
# args: no.
# retn: nothing.
sub get_opt();

# Print help message on the screen and exit.
# args: no.
# retn: nothing.
sub help();

# Obtain needed files and dirs and check their presence.
# args: no.
# retn: nothing.
sub prepare_files_and_dirs();

# Upload schema or and common data to KB.
# args: no.
# retn: nothing.
sub upload_to_kb();


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
my $opt_init_schema;
my $opt_new;
my $opt_schema;
my $opt_update_pattern;
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

if ($opt_init_schema or $opt_init)
{
  print_debug_normal("Upload KB schema or/and common KB data to the database");
  upload_to_kb();
}

my $host;
$LDVDBHOST ? $host = $LDVDBHOST : $host = 'localhost';
$dbh = DBI->connect("DBI:mysql:database=$LDVDB;host=$host", $LDVUSER, $LDVDBPASSWD)
    or die("Couldn't connect to database: " . DBI->errstr);

if ($opt_init_cache_db or $opt_init_cache_script)
{
  print_debug_normal("Start KB cache (re)generation");
  generate_cache();
}

if ($opt_delete)
{
  print_debug_normal("Delete records from KB cache");
  delete_cache(\@kb_ids_delete);
}

if ($opt_new)
{
  print_debug_normal("Calculate KB cache for new KB entities");
#  new_kb_ids_to_cache();
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
  my $kb_ids = shift;

  if ($kb_ids)
  {
    my @kb_ids = @{$kb_ids};
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

sub generate_cache()
{
  print_debug_trace("Generate KB cache...");

  if ($opt_init_cache_db)
  {
    # Just before fast initialization by means of db tools we need to delete
    # the whole cache.
    delete_cache(undef);

    print_debug_trace("Begin to perform fast KB cache initialization...");
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
         AND IF(kb.main is NULL, 1, scenarios.main like kb.main) = 1") or die($dbh->errstr);
    print_debug_debug("Fast KB cache initialization was performed successfully");
  }

  # This seems to require too much time. So, separate it from the fast cache
  # initialization.
  if ($opt_init_cache_script)
  {
    my $all_data = $dbh->selectall_arrayref(
      "SELECT rule_models.name, scenarios.executable, scenarios.main, kb.script, traces.id, kb.id
       FROM launches
         LEFT JOIN traces on traces.id=launches.trace_id
         LEFT JOIN results_kb on traces.id=results_kb.trace_id
         LEFT JOIN kb on kb.id=results_kb.kb_id
         LEFT JOIN rule_models on rule_models.id=launches.rule_model_id
         LEFT JOIN scenarios on scenarios.id=launches.scenario_id
       WHERE results_kb.fit='Require script'") or die($dbh->errstr);

    foreach my $data (@{$all_data}) {
      my ($model, $module, $main, $script, $trace_id, $kb_id) = @{$data};

      print_debug_trace("Execute script '$script' with model '$model', module '$module' and main '$main'");
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
    'init-schema' => \$opt_init_schema,
    'new=s' => \$opt_new,
    'schema=s' => \$opt_schema,
    'update-pattern=s' => \$opt_update_pattern,
    'update-result=s' => \$opt_update_result))
  {
    warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
    help();
  }

  help() if ($opt_help);

  # Initialization implies KB schema uploading as well as KB data.
  $opt_init_schema = 1 if ($opt_init);

  print_debug_debug("KB schema will be uploaded to the specified database")
    if ($opt_init_schema);

  print_debug_debug("Common KB data will be uploaded to the specified database")
    if ($opt_init);

  # Both cache initializations will be performed in this case.
  if ($opt_init_cache)
  {
    $opt_init_cache_db = 1;
    $opt_init_cache_script = 1;
  }

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

  -h, --help
    Print this help and exit with a error.

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

  if ($opt_init)
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

sub upload_to_kb()
{
  if ($opt_init_schema)
  {
    my $schema = $kb_schema;
    $schema = $opt_schema if ($opt_schema);
    print_debug_info("Execute the command '$mysql_connection < $schema'");
    `$mysql_connection < $schema`;

    if (!$CHILD_ERROR and $opt_init)
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
