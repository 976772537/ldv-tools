#! /usr/bin/perl -w


use Cwd qw(abs_path cwd);
use English;
use Env qw(LDV_DEBUG LDV_REGR_TEST_LAUNCHER_DEBUG);
use File::Basename qw(fileparse);
use File::Copy qw(copy);
use File::Path qw(mkpath);
use FindBin;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(posix_default no_ignore_case);
use strict;

# Add some local Perl packages.
use lib("$FindBin::RealBin/../../shared/perl");

# Add some nonstandard local Perl packages.
use LDV::Utils qw(vsay print_debug_warning print_debug_normal print_debug_info print_debug_debug print_debug_trace print_debug_all get_debug_level);


################################################################################
# Subroutine prototypes.
################################################################################

# Collect the ldv-manager results.
# args: no.
# retn: nothing.
sub collect_results();

# Process command-line options. To see detailed description of these options 
# run script with --help option.
# args: no.
# retn: nothing.
sub get_opt();

# Obtain tasks for the ldv-manager.
# args: no.
# retn: nothing.
sub get_tasks();

# Print help message on the screen and exit.
# args: no.
# retn: nothing.
sub help();

# Pass tasks to the ldv-manager.
# args: no.
# retn: nothing.
sub launch_tasks();

# Obtain needed files and dirs and check their presence.
# args: no.
# retn: nothing.
sub prepare_files_and_dirs();

# Verify that ldv-manager tasks are proper.
# args: no.
# retn: nothing.
sub verify_tasks();


################################################################################
# Global variables.
################################################################################

# An absolute path to the current working directory.
my $current_working_dir;

# Prefix for all debug messages.
my $debug_name = 'regr-test-launcher';

# Path to the binary of the ldv-manager. It will be found in the PATH.
my $ldv_manager_bin = "ldv-manager";
# The directory where the ldd-manager puts its results. It's relative to the
# ldv-manager working directory.
my $ldv_manager_result_dir = 'finished';
# The ldv-manager results are identified by their suffix.
my $ldv_manager_result_suffix = '.pax';
# The directory from where the ldv-manager will be launched. It's relative to the 
# current working directory.
my $ldv_manager_work_dir = 'ldv-manager-work-dir';

# Command-line options. Use --help option to see detailed description of them.
my $opt_help;
my $opt_out;
my $opt_test_set;

# Two different kinds of drivers (external in archives and kernel internal).
my $origin_external = 'external';
my $origin_kernel = 'kernel';

# The available predefined test sets.
my %predefined_test_sets = ('small' => 1, 'medium' => 1, 'big' => 1);
# An absolute path to the directory containing predefined test sets.
my $predefined_test_sets_dir = "$FindBin::RealBin/../../ldv-tests/regr-tests/test-sets";

# The prefix to the regression test task.
my $regr_task_prefix = 'regr-task-';

# The directory where results (ldv-manager archives) will be putted.
my $result_dir;

# The name of the launcher task.
my $task_name = 'regression-test';

# This hash contains unique tasks to be executed. Task is '(driver, kernel, 
# model)'.
my %tasks;

# The test set to be used. It's an absolute path to the test set task file.
my $test_set;
# The directory of the test set.
my $test_set_dir;


################################################################################
# Main section.
################################################################################

# Obtain the debug level.
get_debug_level($debug_name, $LDV_DEBUG, $LDV_REGR_TEST_LAUNCHER_DEBUG);

print_debug_normal("Process the command-line options");
get_opt();

print_debug_normal("Check presence of needed files, executables and directories. Copy needed files and directories");
prepare_files_and_dirs();

print_debug_normal("Obtain tasks for the ldv-manager");
get_tasks();

print_debug_normal("Check that ldv-manager tasks are given in the proper way");
verify_tasks();

print_debug_normal("Launch the necessary tasks by means of ldv-manager");
launch_tasks();

print_debug_normal("Copy results obtained from for the ldv-manager to the specified directory");
collect_results();

print_debug_normal("Make all successfully");


################################################################################
# Subroutines.
################################################################################

sub collect_results()
{
  if (-d "$current_working_dir/$ldv_manager_work_dir/$ldv_manager_result_dir")
  {	
	foreach my $result (<$current_working_dir/$ldv_manager_work_dir/$ldv_manager_result_dir/*>) 
    {
      if (-f $result and $result =~ /([^\/]*$ldv_manager_result_suffix)$/)
      { 
        copy("$current_working_dir/$ldv_manager_work_dir/$ldv_manager_result_dir/$1", "$result_dir/$1")
          or die("Can't copy the file '$current_working_dir/$ldv_manager_work_dir/$ldv_manager_result_dir/$1' to the file '$result_dir/$1'");
        
        print_debug_debug("The ldv-manager results file '$current_working_dir/$ldv_manager_work_dir/$ldv_manager_result_dir/$1' was copied to the '$result_dir/$1'");
      }
    }
  }
  
  print_debug_normal("The ldv-manager results are in the '$result_dir' directory now");	          
}

sub get_opt()
{
  unless (GetOptions(
    'help|h' => \$opt_help,
    'results|o=s' => \$opt_out,
    'test-set=s' => \$opt_test_set))
  {
    warn("Incorrect options may completely change the meaning! Please run script with the --help option to see how you may use this tool.");
    help();
  }

  help() if ($opt_help);

  if ($opt_out)
  {
    die("The directory '$opt_out' specified through the option --results|o doesn't exist: $ERRNO")
      unless (-d $opt_out);
    print_debug_debug("The results will be put to the '$opt_out' directory");
  }

  if ($opt_test_set)
  {
	# I.e. the absolute path to the regression test task.
	if ($opt_test_set =~ /\//)
	{
      die("The file '$opt_test_set' specified through the option --test-set doesn't exist: $ERRNO")
        unless (-f $opt_test_set);	  
	}
	# One of the predefined test sets.
	else
	{  
	  unless (defined($predefined_test_sets{$opt_test_set}))
	  {  
        warn("The test set '$opt_test_set' specified through the option --test-set can't be processed. Please use one of the following ones:\n");
      
        foreach my $test_set (keys(%predefined_test_sets))
        {
		  warn("  - '$test_set'\n");
	    }
      
        die(); 
      }
    }
    
    print_debug_debug("The choosen test set is '$opt_test_set'");
  }
  
  print_debug_debug("The command-line options are processed successfully");
}

sub get_tasks()
{
  open(my $file_test_set, '<', "$test_set")
    or die("Can't open the file '$test_set' for read: $ERRNO");	
  
  print_debug_trace("Begin to process the test set task file");
  foreach my $launch (<$file_test_set>)
  {
	chomp($launch);
	next if ($launch =~ /^\s*$/);
	print_debug_trace("Parse the launch information '$launch'");  
	my @launch_info = split(/;/, $launch);
	
	# Launch information contains the following infomation:
	#   (necessary)
	#   - driver (either archive or kernel drivers subdirectory)
	#   - driver origin (external | kernel)
	#   - kernel (kernel name corresponding to the archive)
	#   - model (model identifier)
	#   (the rest isn't interesting for launcher).
	# Each launch information has form 'name=value'.
	# Read first four fielrds of launch information array.
	my @launch_info_keys;
	for (my $i = 0; $i < 4; $i++)
	{
	  die("Incorrect format of the test set task file. Field '$i' is corrupted.")
	    unless ($launch_info[$i]);
	  
	  # Obtain value of field.
	  $launch_info[$i] =~ /=/;
	  
	  push(@launch_info_keys, $POSTMATCH);
	}
	print_debug_debug("Key values are '@launch_info_keys'");	
    
    # Add keys for the ldv-manager tasks.	
    $tasks{$launch_info_keys[0]}{$launch_info_keys[1]}{$launch_info_keys[2]}{$launch_info_keys[3]} = 1;
  }  
  print_debug_debug("Finish to process the test set task file");
      
  close($file_test_set) 
    or die("Can't close the file '$test_set': $ERRNO\n");
}

sub help()
{
    print(STDERR << "EOM");

NAME
  $PROGRAM_NAME: the tool is intended to launch the ldv-manager to obtain new 
    results for the regression test.

SYNOPSIS
  $PROGRAM_NAME [option...]

OPTIONS

  -h, --help
    Print this help and exit with a error.

  -o, --results <dir>
    <dir> is a path to a directory where all launches results will be 
    placed. It's optional. If it isn't specified then results are 
    placed to the current directory.

  --test-set <name>
    <name> may be one of the predefined test set names or may be absolute
    path to the regression test task file. It's optional. If this option isn't 
    specified, then current folder is scanned for the first regression test 
    task. Note then regression test task is a file beginning with the 
    '$regr_task_prefix' prefix.

ENVIRONMENT VARIABLES

  LDV_DEBUG
    It's an optional environment variable that specifies a debug 
    level. It uses the standard designatures to distinguish different
    debug information printings. Each next level includes all previous
    levels and its own messages.

  LDV_REGR_TEST_LAUNCHER_DEBUG
    Like LDV_DEBUG but it has more priority. It specifies a debug 
    level just for this instrument.
    
EOM

  exit(1);
}

sub launch_tasks()
{
  foreach my $driver (keys(%tasks))
  {
	foreach my $origin (keys(%{$tasks{$driver}}))
	{
	  foreach my $kernel (keys(%{$tasks{$driver}{$origin}}))
	  {
		foreach my $model (keys(%{$tasks{$driver}{$origin}{$kernel}}))
	    {  
		  my @args = ($ldv_manager_bin, 'tag=current', "envs=$kernel", "drivers=$driver", "rule_models=$model", "name=$task_name");		
		  push(@args, 'kernel_driver=1') if ($origin eq $origin_kernel);
		  print_debug_info("Execute the command '@args'");

          print_debug_trace("Go to the ldv-manager working directory '$current_working_dir/$ldv_manager_work_dir' to launch it");
          chdir("$current_working_dir/$ldv_manager_work_dir")
            or die("Can't change directory to '$current_working_dir/$ldv_manager_work_dir'");
            		  
		  my $status = system(@args);
          print_debug_debug("The ldv-manager returns '$status'");
          
          print_debug_trace("Go to the initial working directory '$current_working_dir'");
          chdir($current_working_dir)
            or die("Can't change directory to '$current_working_dir'");
	    }
	  }
    }
  }
}

sub prepare_files_and_dirs()
{
  # Try to obtain regression test task in case when it isn't specified through
  # the absolute path.
  if ($opt_test_set)
  {
	# It's already choosen.  
	if ($opt_test_set =~ /\//)
	{
	  $test_set = $opt_test_set;
	}
    # Obtain it from the predefined test sets pathes.
	else
	{  
	  die("Can't find test set '$opt_test_set' in the predefined test sets directory '$predefined_test_sets_dir/$opt_test_set'") 
	    unless (-d "$predefined_test_sets_dir/$opt_test_set");
	
	  # TODO At this step we need to find appropriate file.
	  exit 0;
	}
  }
  # Obtain it from the current directory.
  unless ($opt_test_set)
  {
	exit 0;
  }

  $test_set = abs_path($test_set) 
    or die("Can't obtain the absolute path of '$test_set'");
  print_debug_debug("The test set file absolute path is '$test_set'");
  
  print_debug_trace("Try to find the test set directory");
  my @test_set_path = fileparse($test_set)
    or die("Can't find a directory of the file '$test_set'");
  $test_set_dir = $test_set_path[1];
  print_debug_debug("The test set directory is '$test_set_dir'");
    
  $current_working_dir = Cwd::cwd() 
    or die("Can't obtain the current working directory");
  print_debug_debug("The current working directory is '$current_working_dir'");
  
  die("You run launcher in the already used directory. Please remove ldv-manager working directory '$current_working_dir/$ldv_manager_work_dir' and corresponding test results") 
    if (-d "$current_working_dir/$ldv_manager_work_dir");
  
  mkpath("$current_working_dir/$ldv_manager_work_dir")
    or die("Couldn't recursively create directory '$current_working_dir/$ldv_manager_work_dir': $ERRNO");
    
  print_debug_trace("Obtain the directory where results will be put");  
  if ($opt_out)
  {
	$result_dir = $opt_out;
  }
  else
  {
	$result_dir = $current_working_dir;  
  }
  print_debug_debug("The ldv-manager results will be put to the '$result_dir' directory");
  
  print_debug_trace("Check that there is no results left from the previous launches");
  foreach my $file (<$result_dir/*>) 
  {
    die("You want to put results to the directory '$result_dir' that already contains some results (e.g. '$file')")
	  if (-f $file and $file =~ /$ldv_manager_result_suffix$/);	  
  }
  
  print_debug_trace("Check presence of scripts");
  die ("There is no the ldv-manager executable '$ldv_manager_bin' in your PATH")
    unless (-x "$ldv_manager_bin"); 
}

sub verify_tasks()
{
  # Already copied external drivers and kernels.
  my %drivers;
  my %kernels;

  # Tasks with the correct names of kernels.
  my %tasks_fixed;
  	
  foreach my $driver (keys(%tasks))
  {
	foreach my $origin (keys(%{$tasks{$driver}}))
	{
	  foreach my $kernel (keys(%{$tasks{$driver}{$origin}}))
	  {
		foreach my $model (keys(%{$tasks{$driver}{$origin}{$kernel}}))
	    { 
		  # Check that needed external drivers and kernels are present and copy 
		  # them to the ldv-manager working directory.
		  if ($origin eq $origin_external)
		  {
			unless ($drivers{$driver})
			{  
		      if (-f "$test_set_dir/$driver")
		      {
		        copy("$test_set_dir/$driver", "$current_working_dir/$ldv_manager_work_dir/$driver")
                  or die("Can't copy the file '$test_set_dir/$driver' to the file '$current_working_dir/$ldv_manager_work_dir/$driver'");
		        print_debug_debug("The external driver file '$test_set_dir/$driver' was copied to the '$current_working_dir/$ldv_manager_work_dir/$driver'");
		      }
  		      else
		      {
			    die("There is no driver '$driver' in the test set directory '$test_set_dir'");
		      }
		      
		      $drivers{$driver} = 1;
		    }
		  }
  	      
		  unless ($kernels{$kernel})
  	      {
			my $kernel_real;
			
			print_debug_trace("Try to find the kernel by its short name in the test set directory '$test_set_dir'");  
            foreach my $kernel_full (<$test_set_dir/*>) 
            {	
		      if ($kernel_full =~ /($kernel[^\/]*)$/) 
			  {	 
				die("The matched kernels full names are ambiguous ('$kernel_real' and '$1' both matches to '$kernel').") if ($kernel_real); 
				$kernel_real = $1;
			  }
			}	 	  
  	        if ($kernel_real and -f "$test_set_dir/$kernel_real")
  	        {
		      copy("$test_set_dir/$kernel_real", "$current_working_dir/$ldv_manager_work_dir/$kernel_real")
                or die("Can't copy the file '$test_set_dir/$kernel_real' to the file '$current_working_dir/$ldv_manager_work_dir/$kernel_real'");
		      print_debug_debug("The kernel file '$test_set_dir/$kernel_real' was copied to the '$current_working_dir/$ldv_manager_work_dir/$kernel_real'");
			}
			else
			{
  	          die("There is no kernel '$kernel' (short name) in the test set directory '$test_set_dir'");
  	        }
  	        
  	        $kernels{$kernel} = $kernel_real;
	      }
	      
	      $tasks_fixed{$driver}{$origin}{$kernels{$kernel}}{$model} = 1;
	    }
	  }
    }
  }
  
  print_debug_trace("Fix the tasks for the ldv-manager");
  %tasks = %tasks_fixed;
}
