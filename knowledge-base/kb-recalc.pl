#! /usr/bin/perl -w


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
my $opt_init_schema;
my $opt_new;
my $opt_schema;
my $opt_update_pattern;
my $opt_update_result;


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

print_debug_normal("Make all successfully");


################################################################################
# Subroutines.
################################################################################

sub get_opt()
{
  unless (GetOptions(
    'common-data=s' => \$opt_common_data,
    'delete=s' => \$opt_delete,
    'help|h' => \$opt_help,
    'init' => \$opt_init,
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
