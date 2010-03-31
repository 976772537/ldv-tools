#! /usr/bin/perl -w


use Cwd qw(abs_path cwd);
use English;
use Env qw(LDV_KERNEL_RULES);
use File::Basename qw(basename fileparse);
#use File::Cat qw(cat);
#use File::Copy::Recursive qw(rcopy);
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;
use XML::Twig qw();
use XML::Writer qw();


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

# Obtain needed files and dirs and check their presence.
# args: no.
# retn: nothing.
sub prepare_files_and_dirs();

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

# Suffix for file that will contain general aspect consisting of usual and 
# common aspects.
my $aspect_general_suffix = '.general';

# Information on current command.
my %cmd;
# Instrumentor basedir.
my $cmd_basedir;

# Errors return codes.
my $error_syntax = 1; 
my $error_semantics = 2;

# File handlers.
my $file_xml_out;

# Kind of instrumentation.
my $kind_isplain = 0;
my $kind_isaspect = 0;

my $ldv_rule_instrumentor_abs;
my @ldv_rule_instrumentor_path;
my $ldv_rule_instrumentor_dir;
my $LDV_HOME;
my $ldv_rule_instrumentor;
my $ldv_aspectator_bin_dir;
my $ldv_aspectator;
# Environment variable that says that options passed to gcc compiler aren't
# quoted.
my $ldv_no_quoted = 'LDV_NO_QUOTED';
# Environment variable that will keep path to GCC executable. 
my $ldv_aspectator_gcc = 'LDV_LLVM_GCC';
my $ldv_c_backend;
my $ldv_gcc;
# Linker.
my $ldv_linker;

# Directory contains rules models database and their source code.
my $ldv_model_dir;

# Name of xml file containing models database. Name is relative to models 
# directory. 
my $ldv_model_db_xml = 'model-db.xml';

# Information on needed model.
my %ldv_model;

# Options that are obtained for the version of gcc compiler (version 4.4 or may
# be higher). Note that this is array of options patterns to be excluded.
my @llvm_gcc_4_4_opts = ('-Wframe-larger-than=\d+', '-fno-dwarf2-cfi-asm', '-fconserve-stack');

# Suffix of llvm bitcode files. 
my $llvm_bitcode_suffix = '.bc';

# Suffix of llvm bitcode files instrumented with general aspect.
my $llvm_bitcode_general_suffix = '.general';

# Options to be passed to llvm C backend.
my @llvm_c_backend_opts = ('-f', '-march=c');

# Suffix for llvm C backend production.
my $llvm_c_backend_suffix = '.cbe.c';

# Options to be passed to llvm linker.
my @llvm_linker_opts = ('-f');

# Command-line options. Use --help option to see detailed description of them.
my $opt_basedir;
my $opt_cmd_xml_in;
my $opt_cmd_xml_out;
my $opt_help;
my $opt_model_id;

# Absolute path to working directory of this tool. 
my $tool_working_dir;

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
my $xml_model_db_error = 'error';
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

# Remember absolute path to the current working directory. 
$tool_working_dir = Cwd::cwd();

# Get and parse command-line options.
get_opt();

# Check presence of needed files and directories. Copy needed files and 
# directories.
prepare_files_and_dirs();

# Prepare twig xml parser for models database and input commands.
my $xml_twig = new XML::Twig;

# Get and store information on required model.
get_model_info();

# Print standard xml file header.
print($file_xml_out "<?xml version=\"1.0\"?>\n");

my $xml_writer;

# In aspect mode prepare special xml writer. 
if ($kind_isaspect)
{
  $xml_writer = new XML::Writer(OUTPUT => $file_xml_out, NEWLINES => 1);
  
  $xml_writer->startTag('cmdstream');
    
  # Print rule instrumentor basedir tags.
  $xml_writer->dataElement('basedir' => $opt_basedir);
}
else
{
  # Print root node open tag.
  print($file_xml_out "<cmdstream>\n");	
}

# Process commands step by step.
process_cmds();

if ($kind_isaspect)
{
  # Close cmdstream tag.	
  $xml_writer->endTag();
  
  # Perform final checks.
  $xml_writer->end();
}
else
{
  # Print root node close tag.
  print($file_xml_out "</cmdstream>\n");
}

close($file_xml_out) 
  or die("Couldn't close file '$opt_cmd_xml_out': $ERRNO\n");


################################################################################
# Subroutines.
################################################################################

sub get_model_info()
{
  # Read models database xml file.
  $xml_twig->parsefile("$ldv_model_dir/$ldv_model_db_xml");
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
    if ($id_attr eq $opt_model_id)
    { 
	  # Read model information.
	  my $engine = $model->first_child_text($xml_model_db_engine);
	  my $error = $model->first_child_text($xml_model_db_error);
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
      %ldv_model = (
        'id' => $id_attr, 
        'kind' => \@kinds,
        'aspect' => $aspect,
        'common' => $common,
        'filter' => $filter,
        'engine' => $engine,
        'error' => $error, 
        'hints' => $hints);
     
      foreach my $kind (@kinds)
      {
		if ($kind eq 'aspect')
		{
		  $kind_isaspect = 1;
		}
		elsif ($kind eq 'plain')
		{
		  $kind_isplain = 1;
		}
		else
		{
          warn("Kind '$kind' can't be processed"); 	

          exit($error_semantics);			
		}
	  }
     
      # Create general aspect for the given model in aspect mode.
      if ($kind_isaspect)
      {
        $ldv_model{'general'} = "$ldv_model{'aspect'}$aspect_general_suffix";
        `cat "$ldv_model_dir/$ldv_model{'aspect'}" "$ldv_model_dir/$ldv_model{'common'}" > "$ldv_model_dir/$ldv_model{'general'}"`;
      }
      
      # Finish models iteration after the first one is found and processed.
      last;
    }
  }

  unless (%ldv_model)
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
    'cmdfile|c=s' => \$opt_cmd_xml_in,
    'cmdfile-out|o=s' => \$opt_cmd_xml_out,
    'help|h' => \$opt_help,
    'rule-model|m=s' => \$opt_model_id))
  {
    warn("Incorrect options may completely change the meaning! Please run " .
      "script with --help option to see how you may use this tool.");

    help();
  }
 
  help() if ($opt_help);
  
  unless ($opt_basedir && $opt_cmd_xml_in && $opt_cmd_xml_out && $opt_model_id) 
  {
    warn("You must specify options --basedir, --cmd-xml-in, --cmd-xml-out, --model-id in command-line");
    
    help();
  }

  unless(-d $opt_basedir)
  {
    warn("Directory specified through option --basedir|-b doesn't exist");
    
    help();	  
  }     
  
  unless(-f $opt_cmd_xml_in)
  {
    warn("File specified through option --cmdfile|-c doesn't exist");
    
    help();	  
  }
  
  open($file_xml_out, '>', "$opt_cmd_xml_out")
    or die("Couldn't open file '$opt_cmd_xml_out' specified through option --cmdfile-out|-o for write: $ERRNO");
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

  -h, --help
    Print this help and exit with syntax error.

  -c, --cmdfile <file>
    <file> is absolute path to xml file containing commands for tool.

  -m, --rule-model <id>
    <id> is model id that specify model to be instrumented with 
    source code.

  -o, --cmdfile-out <file>
    <file> is absolute path to xml file that will contain commands
      generated by tool.

ENVIRONMENT VARIABLES

  LDV_KERNEL_RULES
    It's optional option that points to user models directory that 
    will be used instead of the standard one.

EOM

  exit($error_syntax);
}

sub prepare_files_and_dirs()
{
  # LDV_HOME is obtained through directory of rule-instrumentor.
  # It is assumed that there is such organization of LDV_HOME directory:
  # /LDV_HOME/
  #   bin/
  #     rule_instrumentor.pl (this script)
  #   rule_instrumentor/
  #     aspectator/
  #       bin/
  #         symlinks to aspectator script, gcc, linker, c-backend and so on.
  $ldv_rule_instrumentor_abs = abs_path($0) 
    or die("Can't obtain absolute path of '$0'");

  @ldv_rule_instrumentor_path = fileparse($ldv_rule_instrumentor_abs)
    or die("Can't find directory of file '$ldv_rule_instrumentor_abs'");

  $ldv_rule_instrumentor_dir = $ldv_rule_instrumentor_path[1];

  # Obtain LDV_HOME as earlier as possible.
  $ldv_rule_instrumentor_dir =~ /\/bin\/*$/;

  $LDV_HOME = $PREMATCH;

  unless(-d $LDV_HOME)
  {
    warn("Directory '$LDV_HOME' (LDV home directory) doesn't exist");
    
    help();	  
  }

  # Directory where all rule instrumentor auxiliary instruments (such as 
  # aspectator) are placed.
  $ldv_rule_instrumentor = "$LDV_HOME/rule-instrumentor";

  unless(-d $ldv_rule_instrumentor)
  {
    warn("Directory '$ldv_rule_instrumentor' (rule instrumentor directory) doesn't exist");
    
    help();	  
  }

  # Directory contains all binaries needed by aspectator.
  $ldv_aspectator_bin_dir = "$ldv_rule_instrumentor/aspectator/bin";

  unless(-d $ldv_aspectator_bin_dir)
  {
    warn("Directory '$ldv_aspectator_bin_dir' (aspectator binaries directory) doesn't exist");
    
    help();	  
  }

  # Aspectator script.
  $ldv_aspectator = "$ldv_aspectator_bin_dir/compiler";

  unless(-f $ldv_aspectator)
  {
    warn("File '$ldv_aspectator' (aspectator) doesn't exist");
    
    help();	  
  }

  # C backend.
  $ldv_c_backend = "$ldv_aspectator_bin_dir/c-backend";

  unless(-f $ldv_c_backend)
  {
    warn("File '$ldv_c_backend' (LLVM C backend) doesn't exist");
    
    help();	  
  }

  # GCC compiler with aspectator extensions that is used by aspectator
  # script.
  $ldv_gcc = "$ldv_aspectator_bin_dir/compiler-core";

  unless(-f $ldv_gcc)
  {
    warn("File '$ldv_gcc' (GCC compiler) doesn't exist");
    
    help();	  
  }

  # Linker.
  $ldv_linker = "$ldv_aspectator_bin_dir/linker";

  unless(-f $ldv_linker)
  {
    warn("File '$ldv_linker' (LLVM linker) doesn't exist");
    
    help();	  
  }

  # Use environment variable for models instead of standard placement in LDV_HOME.
  if ($LDV_KERNEL_RULES)
  {
    $ldv_model_dir = $LDV_KERNEL_RULES;
  }
  else
  {
    $ldv_model_dir = "$LDV_HOME/kernel-rules";	  
  }

  # Check whether models are installed properly. 
  unless(-d $ldv_model_dir)
  {
    warn("Directory '$ldv_model_dir' (kernel rules models) doesn't exist");
    
    help();	  
  }
  
  unless(-f "$ldv_model_dir/$ldv_model_db_xml")
  {
    warn("Directory '$ldv_model_dir' doesn't contain models database xml file '$ldv_model_db_xml'");
    
    help();
  }
  
  # Copy models dir to base directory since it'll be affected a bit.
# TODO Require Recursive.pm
#  copy($opt_primitives,
#            "$FindBin::RealBin/$settings3::name_file_primitive")
#                or die("Couldn't copy file '$opt_primitives' to file " .
#                    "'$FindBin::RealBin/$settings3::name_file_primitive': $ERRNO");
  `cp -r $ldv_model_dir $opt_basedir`;
#  rcopy($ldv_model_dir, $opt_basedir)
#    or die("Can't copy directory '$ldv_model_dir' to directory '$opt_basedir'");;
  # Change models dir.

  $ldv_model_dir = "$opt_basedir/" . basename($ldv_model_dir);
}

sub process_cmd_cc()
{
  if ($kind_isaspect)
  {	
    # Go to base directory to execute cc command.
    chdir($cmd{'cwd'})
      or die("Can't change directory to '$cmd{'cwd'}'");
  
    # On each cc command we run aspectator on corresponding file with 
    # corresponding model aspect and options.
    $ENV{$ldv_aspectator_gcc} = $ldv_gcc;
    $ENV{$ldv_no_quoted} = 1;
    my @args = ($ldv_aspectator, ${$cmd{'ins'}}[0], "$ldv_model_dir/$ldv_model{'aspect'}", @{$cmd{'opts'}});
    system(@args) == 0 or die("System '@args' call failed: $ERRNO");	
	
    # After aspectator work we obtain files ${$cmd{'ins'}}[0]$llvm_bitcode_suffix with llvm
    # object code. Copy them to $cmd{'out'} files.
    `cp ${$cmd{'ins'}}[0]$llvm_bitcode_suffix $cmd{'out'}`;
  
    # Also do this with general aspect. Don't forget to add -I option with 
    # models directory needed to find appropriate headers for common aspect.
    my $model_dir_abs = abs_path("$ldv_model_dir/$ldv_model{'common'}")
      or die("Can't obtain absolute path of '$ldv_model_dir/$ldv_model{'common'}'");
    my @model_dir_path = fileparse($model_dir_abs)
      or die("Can't find directory of file '$model_dir_abs'");
    my $model_dir = $model_dir_path[1];
    
    $ENV{$ldv_aspectator_gcc} = $ldv_gcc;
    $ENV{$ldv_no_quoted} = 1;
    @args = ($ldv_aspectator, ${$cmd{'ins'}}[0], "$ldv_model_dir/$ldv_model{'general'}", @{$cmd{'opts'}}, "-I$model_dir");
    system(@args) == 0 
      or die("System '@args' call failed: $ERRNO");	
	
    # After aspectator work we obtain files ${$cmd{'ins'}}[0]$llvm_bitcode_suffix with llvm
    # object code. Copy them to $cmd{'out'}$llvm_bitcode_general_suffix files.
    `cp ${$cmd{'ins'}}[0]$llvm_bitcode_suffix "$cmd{'out'}$llvm_bitcode_general_suffix"`;
  
    # Come back.
    chdir($tool_working_dir)
      or die("Can't change directory to '$tool_working_dir'");
  }
}

sub process_cmd_ld()
{
  if ($kind_isaspect)
  {	
    # Go to base directory to execute ld command.
    chdir($cmd{'cwd'})
      or die("Can't change directory to '$cmd{'cwd'}'");
  
    # On each ld command we run llvm linker for all input files together to 
    # produce one linked file. Note that excact one file to be linked must be
    # generally (i.e. with usual and common aspects) instrumented. We choose the
    # first one here.
    my @ins = ("${$cmd{'ins'}}[0]$llvm_bitcode_general_suffix", @{$cmd{'ins'}}[1..$#{$cmd{'ins'}}]);
    my @args = ($ldv_linker, @llvm_linker_opts, @ins, '-o', $cmd{'out'});
    system(@args) == 0 or die("System '@args' call failed: $ERRNO");	

    # Make name for c file corresponding to the linked one. 
    $cmd{'out'} =~ /\.[^\.]*$/;
    my $c_out = "$PREMATCH$llvm_c_backend_suffix";
  
    # Linked file is converted to c by means of llvm c backend.
    @args = ($ldv_c_backend, @llvm_c_backend_opts, $cmd{'out'}, '-o', $c_out);
    system(@args) == 0 or die("System '@args' call failed: $ERRNO");
    
    # Come back.
    chdir($tool_working_dir)
      or die("Can't change directory to '$tool_working_dir'");

    # Print corresponding commands to output xml file. 
    $xml_writer->startTag('cc', 'id' => "$cmd{'id'}-llvm-cc");
    $xml_writer->dataElement('cwd' => $cmd{'cwd'});
    $xml_writer->dataElement('in' => $c_out);
    # Use here the first input file name to relate with corresponding ld 
    # command.    
    $xml_writer->dataElement('out' => ${$cmd{'ins'}}[0]); 
    $xml_writer->dataElement('engine' => $ldv_model{'engine'}); 
    # Close cc tag.
    $xml_writer->endTag();
     
    $xml_writer->startTag('ld', 'id' => "$cmd{'id'}-llvm-ld");
    $xml_writer->dataElement('cwd' => $cmd{'cwd'});    
    $xml_writer->dataElement('in' => ${$cmd{'ins'}}[0]);  
    $xml_writer->dataElement('out' => $cmd{'out'});
    $xml_writer->dataElement('engine' => $ldv_model{'engine'}); 
  
    foreach my $entry_point (@{$cmd{'entry point'}})
    {
       $xml_writer->dataElement('main' => $entry_point);
    }
    
    # TODO: obtain value from models db!
    $xml_writer->dataElement('error' => $ldv_model{'error'});
    
    $xml_writer->dataElement('hints' => $ldv_model{'hints'});
    # Close ld tag.
    $xml_writer->endTag();
  }
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
	# To print out user friendly xml output.  
	$cmd->set_pretty_print('indented');
	  
    # At the beginning instrumentor basedir must be specified.
    if ($cmd->gi eq $xml_cmd_basedir)
    {
	  $cmd_basedir = $cmd->text;
	  
	  if ($kind_isplain)
      {
        $cmd->print($file_xml_out);
        
        print($file_xml_out "\n\n");
      }
    }
    # Interpret cc and ld commands.
    elsif ($cmd->gi eq $xml_cmd_cc or $cmd->gi eq $xml_cmd_ld)
    {
	  # For nonaspect mode (plain mode) just copy and modify a bit input xml.	
	  if ($kind_isplain)
      {
		# Add additional input model file and error tat for each ld command.   
		if ($cmd->gi eq $xml_cmd_ld)
		{
		  my $xml_common_model = new XML::Twig::Elt('in', "$ldv_model_dir/$ldv_model{'common'}");	
		  $xml_common_model->paste('last_child', $cmd);
		  # TODO: get value from models db.
		  $xml_common_model = new XML::Twig::Elt('error', $ldv_model{'error'});
		  $xml_common_model->paste('last_child', $cmd);
		}
		
		# Add engine tag for both cc and ld commands.
		if ($cmd->gi eq $xml_cmd_ld or $cmd->gi eq $xml_cmd_cc)
		{
		  my $xml_common_model = new XML::Twig::Elt('engine', $ldv_model{'engine'});	
		  $xml_common_model->paste('last_child', $cmd);
	    }
			  
        $cmd->print($file_xml_out);
        
        print($file_xml_out "\n\n");
      }			
		
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
    
      # Read array of options.
      my @opts;
      
      for (my $opt = $cmd->first_child($xml_cmd_opt)
        ; $opt
        ; $opt = $opt->next_elt($xml_cmd_opt))
      {
		my $opt_text = $opt->text;
		
		# Exclude options for the new gcc compiler.
		foreach my $llvm_gcc_4_4_opt (@llvm_gcc_4_4_opts)
		{
		  if ($opt_text =~ /^$llvm_gcc_4_4_opt$/)
		  {
			$opt_text = '';
			last;
		  }
		}
		  
		next unless ($opt_text);
		  
	    push(@opts, $opt_text);
	  
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
