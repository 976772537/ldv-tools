#! /usr/bin/perl -w


use English;
use Env('LDV_ASPECTATOR', 'LDV_LLVM_C_BACKEND', 'LDV_LLVM_GCC', 'LDV_LLVM_LINKER');
use Getopt::Long;
Getopt::Long::Configure('posix_default', 'no_ignore_case');
use strict;
use XML::Twig;


################################################################################
# Subroutine prototypes.
################################################################################

# Obtain information for required model from models database xml.
# args: no.
# retn: nothing.
sub get_model_info();

# Process command-line options. To see detailed description of these options 
# run script with --help option.
# args: no.
# retn: nothing.
sub get_opt();

# Print help message on the screen and exit with syntax error.
# args: no.
# retn: nothing.
sub help();

# Process single cc command from input xml file.
# args: no.
# retn: nothing.
sub process_cmd_cc();

# Process single ld command from input xml file.
# args: no.
# retn: nothing.
sub process_cmd_ld();

# Process commands from input xml file.
# args: no.
# retn: nothing.
sub process_cmds();


################################################################################
# Global variables.
################################################################################

# Suffix to files 
my $aspectator_suffix = '.bc';

# Information on current command.
my %cmd;
# Instrumentor basedir.
my $cmd_basedir;

# Errors return codes.
my $error_syntax = 1; 
my $error_semantics = 2;

# File handlers.
my $file_xml_out;

# Options to be passed to llvm c backend.
my $llvm_c_backend_opts='-f -march=c';

# Options to be passed to llvm linker.
my $llvm_linker_opts='-f';

# Information on needed model.
my %model;

# Name of xml file containing models database. Name is relative to models 
# directory. 
my $model_db_xml = 'model-db.xml';

# Command-line options. Use --help option to see detailed description of them.
my $opt_basedir;
my $opt_cmd_xml_in;
my $opt_cmd_xml_out;
my $opt_help;
my $opt_model_dir;
my $opt_model_id;

# Xml nodes names.
my $xml_cmd_basedir = 'basedir';
my $xml_cmd_attr_id = 'id';
my $xml_cmd_entry_point = 'main';
my $xml_cmd_cc = 'cc';
my $xml_cmd_cwd = 'cwd';
my $xml_cmd_in = 'in';
my $xml_cmd_ld = 'ld';
my $xml_cmd_opt = 'opt';
my $xml_cmd_out = 'out';
my $xml_model_db_attr_id = 'id';
my $xml_model_db_engine = 'engine';
my $xml_model_db_files = 'files';
my $xml_model_db_files_aspect = 'aspect';
my $xml_model_db_files_common = 'common';
my $xml_model_db_files_filter = 'filter';
my $xml_model_db_hints = 'hints';
my $xml_model_db_kind = 'kind';
my $xml_model_db_model = 'model';


################################################################################
# Main section.
################################################################################

# Check whethe needed tools are specified trough environment variables.
unless ($LDV_ASPECTATOR)
{
  warn("Aspectator script isn't specified through environment variable LDV_ASPECTATOR");
	
  exit($error_syntax);	
}

unless ($LDV_LLVM_C_BACKEND)
{
  warn("Ldv llvm c backend isn't specified through environment variable LDV_LLVM_C_BACKEND");
	
  exit($error_syntax);	
}

unless ($LDV_LLVM_GCC)
{
  warn("Ldv llvm gcc isn't specified through environment variable LDV_LLVM_GCC");
	
  exit($error_syntax);	
}

unless ($LDV_LLVM_LINKER)
{
  warn("Ldv llvm linker isn't specified through environment variable LDV_LLVM_LINKER");
	
  exit($error_syntax);	
}

# Get and parse command-line options.
get_opt();

# Prepare twig xml parser for models database and input commands.
my $xml_twig = new XML::Twig;

# Get and store information on required model.
get_model_info();

# Print standard xml file header.
print($file_xml_out "<?xml version=\"1.0\"?>\n");
# Print root node open tag.
print($file_xml_out "<cmdstream>\n");
# Print rule instrumentor basedir.
print($file_xml_out "  <basedir>$opt_basedir</basedir>\n");

# Process commands step by step.
process_cmds();

# Print root node close tag.
print($file_xml_out "</cmdstream>\n");

close($file_xml_out) 
  or die("Couldn't close file '$opt_cmd_xml_out': $ERRNO\n");


################################################################################
# Subroutines.
################################################################################

sub get_model_info()
{
  # Read models database xml file.
  $xml_twig->parsefile("$opt_model_dir/$model_db_xml");
  my $model_db = $xml_twig->root;

  # Obtain all models.
  my @models = $model_db->children;

  # Iterate over all models to find appropriate if so.
  foreach my $model (@models)
  {
    # Try to read id attribute foreach model to find corresponding one.	
    my $id_attr = $model->att($xml_model_db_attr_id);
  
    unless ($id_attr)
    {
	  warn("Models database doesn't contain id attribute for model");
	
	  exit($error_syntax);
    }
  
    # Model is found!
    if ($id_attr == $opt_model_id)
    { 
	  # Read model information.
	  my $engine = $model->first_child_text($xml_model_db_engine);
	  my $hints = $model->first_child_text($xml_model_db_hints);
    
      my @kinds;
      # Read array of kinds.
      for (my $kind = $model->first_child($xml_model_db_kind)
        ; $kind
        ; $kind = $kind->next_elt($xml_model_db_kind))
      {
	    push(@kinds, $kind->text);
	  
	    last if ($kind->is_last_child($xml_model_db_kind));
      }

      # Read files.
      my $files = $model->first_child($xml_model_db_files);
      my $aspect = $files->first_child_text($xml_model_db_files_aspect);
      my $common = $files->first_child_text($xml_model_db_files_common);
      my $filter = $files->first_child_text($xml_model_db_files_filter);
    
      # Store model information into hash.
      %model = (
        'id' => $id_attr, 
        'kind' => \@kinds,
        'aspect' => $aspect,
        'commmon' => $common,
        'filter' => $filter,
        'engine' => $engine, 
        'hints' => $hints);
     
      # Finish models iteration after the first one is found and processed.
      last;
    }
  }

  unless (%model)
  {
    warn("Specified through option model id '$opt_model_id' doesn't exist in models database"); 	

    exit($error_semantics);
  }	
}

sub get_opt()
{
  if (scalar(@ARGV) == 0)
  {
    warn("No options were specified through command-line. Please see help to " .
      "understand how to use this tool");

    help();
  }
  
  unless (GetOptions(
    'basedir|b=s' => \$opt_basedir,
    'cmd-xml-in|i=s' => \$opt_cmd_xml_in,
    'cmd-xml-out|o=s' => \$opt_cmd_xml_out,
    'help|h' => \$opt_help,
    'model-dir|d=s' => \$opt_model_dir,
    'model-id|m=s' => \$opt_model_id))
  {
    warn("Incorrect options may completely change the meaning! Please run " .
      "script with --help option to see how you may use this tool.");

    help();
  }
 
  help() if ($opt_help);
  
  unless ($opt_basedir && $opt_cmd_xml_in && $opt_cmd_xml_out && $opt_model_dir && $opt_model_id) 
  {
    warn("You must specify options --basedir, --cmd-xml-in, --cmd-xml-out, --model-dir, --model-id in command-line");
    
    help();
  }
  
  unless($opt_model_id =~ /^\d+$/)
  {
    warn("Value of option --model-id must be an integer number");
    
    help();
  }
  
  unless(-d $opt_basedir)
  {
    warn("Directory specified through option --basedir doesn't exist");
    
    help();	  
  }     
  
  unless(-f $opt_cmd_xml_in)
  {
    warn("File specified through option --cmd-xml-in doesn't exist");
    
    help();	  
  }
  
  open($file_xml_out, '>', "$opt_cmd_xml_out")
    or die("Couldn't open file '$opt_cmd_xml_out' for write: $ERRNO");
  
  unless(-d $opt_model_dir)
  {
    warn("Directory specified through option --model-dir doesn't exist");
    
    help();	  
  }
  
  unless(-f "$opt_model_dir/$model_db_xml")
  {
	warn("Directory '$opt_model_dir' specified through option --model-dir must contain models database xml file '$model_db_xml'");
    
    help();
  }
}

sub help()
{
    print(STDERR << "EOM");

NAME
  $PROGRAM_NAME: tool is intended to perform instrumentation of source
  code with model.

SYNOPSIS
  $PROGRAM_NAME [option...]

OPTIONS

  -b, --basedir <dir>
    <dir> is absolute path to tool working directory.

  -d, --model-dir <dir>
    <dir> is absolute path to directory containing model database xml.

  -h, --help
    Print this help and exit with syntax error.

  -i, --cmd-xml-in <file>
    <file> is absolute path to xml file containing commands for tool.

  -m, --model-id <number>
    <number> is integer model id that specify model to be instrumented
    with source code.

  -o, --cmd-xml-out <file>
    <file> is absolute path to xml file that will contain commands
      generated by tool.

EOM

  exit($error_syntax);
}

sub process_cmd_cc()
{
  # On each cc command we run aspectator on corresponding file with 
  # corresponding model aspect and options.	
  `LDV_LLVM_GCC=$LDV_LLVM_GCC $LDV_ASPECTATOR ${$cmd{'ins'}}[0] $opt_model_dir/$model{'aspect'} @{$cmd{'opts'}}`;
	
  # After aspectator work we obtain files ${$cmd{'ins'}}[0]$aspectator_suffix with llvm
  # object code. Copy them to $cmd{'out'} files.
  `cp ${$cmd{'ins'}}[0]$aspectator_suffix $cmd{'out'}`;
  
  # Cc command doesn't produce anything to output xml file.
}

sub process_cmd_ld()
{
  # On each ld command we run llvm linker for all input files together to 
  # produce one linked file.	
  `$LDV_LLVM_LINKER $llvm_linker_opts @{$cmd{'ins'}} -o $cmd{'out'}`;

  # Linked file is converted to c by means of llvm c backend.
  `$LDV_LLVM_C_BACKEND $llvm_c_backend_opts $cmd{'out'}`;
  
  
  
#	<ld id="4">
#		<cwd>/kernel</cwd>
##		<in>/tempdir/after_envgen/driver/mousepad_usb.o</in>
##		<in>/tempdir/after_envgen/driver/common.o</in>
##		<out>/tempdir/after_envgen/driver/mousepad_usb.ko</out>
#		<main>entry_point_1</main>
#	</ld>  
  
  
  
	# Print rule instrumentor basedir.
#print($file_xml_out "  <basedir>$opt_basedir</basedir>\n");
}

sub process_cmds()
{
  # Read input commands xml file.
  $xml_twig->parsefile("$opt_cmd_xml_in");
  my $cmd_root = $xml_twig->root;

  # Obtain all commands.
  my @cmds = $cmd_root->children;

  # Iterate over all commands to execute them and write output xml file.
  foreach my $cmd (@cmds)
  {
    # At the beginning instrumentor basedir must be specified.
    if ($cmd->gi eq $xml_cmd_basedir)
    {
	  $cmd_basedir = $cmd->text;
    }
    # Interpret cc and ld commands.
    elsif ($cmd->gi eq $xml_cmd_cc or $cmd->gi eq $xml_cmd_ld)
    {
	  # General commands section.  
	  my $id_attr = $cmd->att($xml_cmd_attr_id);
	  my $cwd = $cmd->first_child_text($xml_cmd_cwd);
	  my $out = $cmd->first_child_text($xml_cmd_out);

      my @ins;
      # Read array of input files.
      for (my $in = $cmd->first_child($xml_cmd_in)
        ; $in
        ; $in = $in->next_elt($xml_cmd_in))
      {
	    push(@ins, $in->text);
	  
	    last if ($in->is_last_child($xml_cmd_in));
	  }  
    
      my @opts;
      # Read array of options.
      for (my $opt = $cmd->first_child($xml_cmd_opt)
        ; $opt
        ; $opt = $opt->next_elt($xml_cmd_opt))
      {
	    push(@opts, $opt->text);
	  
	    last if ($opt->is_last_child($xml_cmd_opt));
	  }  
	  # Replace maingen directory prefix with the rule instrumentor one.
	  @ins = map {$_ =~ s/^$cmd_basedir/$opt_basedir/; $_} @ins;

	  $out =~ s/^$cmd_basedir/$opt_basedir/;
	  	
	  # Store current command information. 
      %cmd = (
        'id' => $id_attr, 
        'cwd' => $cwd,
        'ins' => \@ins,
        'out' => $out,
        'opts' => \@opts);
    
      undef($cmd{'entry point'});
      
      # cc command doesn't contain any specific settings.
      if ($cmd->gi eq $xml_cmd_cc)
      {
	    process_cmd_cc();
	  }
	
      # ld command additionaly contains array of entry points.
      if ($cmd->gi eq $xml_cmd_ld)
      {
	    my @entry_points;
      
        # Read array of entry points.
        for (my $entry_point = $cmd->first_child($xml_cmd_entry_point)
          ; $entry_point
          ; $entry_point = $entry_point->next_elt($xml_cmd_entry_point))
        {
	      push(@entry_points, $entry_point->text);
	  
	      last if ($entry_point->is_last_child($xml_cmd_entry_point));
	    }  
	    
	    $cmd{'entry point'} = \@entry_points;
	    
	    process_cmd_ld();
	  }
    }
    # Interpret other commands.
    else 
    {
      warn("Input xml file contains command '" . $cmd->gi . "' that can't be interpreted"); 	

      exit($error_semantics);  
    }
  }	
}
