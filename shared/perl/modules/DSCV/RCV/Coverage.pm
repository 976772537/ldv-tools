#!/usr/bin/perl -w

package DSCV::RCV::Coverage;

use File::Basename;
use LDV::Utils;
#use Getopt::Long qw(GetOptions);
#Getopt::Long::Configure qw(posix_default no_ignore_case);
use base qw(Exporter);
@EXPORT=qw(&gen_coverage_report &merge_original_files);
use strict;

sub usage{ 
        my $msg=shift;
	print STDERR $msg."\n";
        die;
}

sub gen_coverage_report
{
	my %options = @_;
	my $output_dir = $options{output_dir};
	if ( ! -d $output_dir) {
		mkdir($output_dir) or die ("Can't create $output_dir\n");
	}
	my $lcov_info_fname = $options{info_file};
	my $skip_expression = $options{skip};
	usage("LCOV info file isn't specified") unless $lcov_info_fname;
	open(my $lcov_info_fh, "<", $lcov_info_fname) or usage("Can't open LCOV info file ".$lcov_info_fname." for read");

	vsay ('DEBUG', "Using output directory for coverage report $output_dir\n");

	my $fname = basename($lcov_info_fname);
	my $output_lcov = $output_dir.$fname.".orig";

	open(my $new_lcov_info_fh, ">", $output_lcov) or usage("Can't open LCOV file for write: $output_lcov");


	# We'd like to relate a given CPAchecker error trace with original source code,
	# not with the CIL one. So first of all build a map between sources.
	# Read a CIL source file from the beginning of the error trace.
	my %src_map;
	sub process_cil_file ($)
	{
		my $cil_fname = shift;
		open(my $cil_fh, "<", $cil_fname) or die("Can't open CIL file for read $cil_fname\n"."You may specify it using --cil option");

		my $src_cur = '';
		my $src_line_cur = 0;
		my $cil_line_cur = 1;

		while (<$cil_fh>)
		{
			my $str = $_;

			chomp($str);

			if ($str =~ /^#line (\d+) "([^"]+)"$/)
			{
				$src_line_cur = $1;
				$src_cur = $2;
				# Change path 'dir1/../dir2/' to 'dir2/'
			    if ($src_cur =~ /(.*)\/([^\/]+)\/\.\.\/([^\/]+)/) {
				    $src_cur = $1."\/".$3;
			    }
			}
			elsif ($str =~ /^#line (\d+)$/)
			{
				$src_line_cur = $1;
			}
			else
			{
				$src_map{$cil_line_cur} = {
					 'file' => $src_cur
					, 'line' => $src_line_cur};
			}

			$cil_line_cur++;
		  }
	}

	my %info_fn;
	my %info_fnda;
	my %info_da;
	my @skipped_lines;
	
	top:while (<$lcov_info_fh>)
	{
		my $str = $_;
		 
		chomp($str);
		  
		next if ($str =~ /^TN/);
		  
		if ($str =~ /^SF:(.+)$/)
		{
			process_cil_file ($1);
		}
		  
		if ($str =~ /^FN:(\d+),(.+)$/)
		{
			my $start_location = $1;
			my $orig_location = $src_map{$start_location} or die("Can't get original location for line '$1'");
			my $start_line = $orig_location->{'line'};
			my $func_name = $2;
			$str = <$lcov_info_fh>;
			chomp($str);
			$str =~ /^#FN:(\d+)$/;
			my $end_location = $1;
			unless (defined($skip_expression) && $func_name =~ /$skip_expression/) {
				push(@{$info_fn{$orig_location->{'file'}}}, {'line' => $start_line, 'func'=>$func_name});
			} else {
				push(@skipped_lines, {'start'=>$start_location, 'end'=>$end_location});
			}
		}

		if ($str =~ /^FNDA:(\d+),(.+)$/)
		{
			$info_fnda{$2} = $1;
		}
		  
		if ($str =~ /^DA:(\d+),(.+)$/)
		{
			my $location = $1;
			my $orig_location = $src_map{$location} or die("Can't get original location for line '$1'");
		 
			foreach my $skip (@skipped_lines)
			{
				#this line should be deleted from report. Skip it.
				next top if ($skip->{'start'} <= $location && $skip->{'end'} >= $location)
			}			

			foreach my $info (@{$info_da{$orig_location->{'file'}}})
			{
				next top if ($info->{'line'} == $orig_location->{'line'} && $info->{'used'} == $2) 
			}
		    
			push(@{$info_da{$orig_location->{'file'}}}, {'line' => $orig_location->{'line'}, 'used'=>$2});
		}
	}

	foreach my $file (keys(%info_fn))
	{
		if ($file !~ '^/')
		{
			vsay ('INFO', "File '$file' has relative path and was skipped from coverage report\n");
			next;
		}
		  
		if (!-f $file)
		{
			vsay ('INFO', "File '$file' was skipped from coverage report\n");
			next;
		}

		print ($new_lcov_info_fh "TN:\nSF:$file\n");
		  
		my $info_fn_for_file = $info_fn{$file};
		my @fn_names;
		foreach my $info_fn (@{$info_fn_for_file})
		{
			my $fn_name = $info_fn->{'func'};
			push(@fn_names, $fn_name);
			my $fn_line = $info_fn->{'line'};
		    
			print ($new_lcov_info_fh "FN:$fn_line,$fn_name\n");
		}
		  
		foreach my $fn_name (@fn_names)
		{
			if ($info_fnda{$fn_name})
			{
				print ($new_lcov_info_fh "FNDA:$info_fnda{$fn_name},$fn_name\n");
			}
		}
		  
		my $info_da_for_file = $info_da{$file};
		# We should remember, which lines we've printed,
		# because there may be several lines transfered into one original line
		my %existed_lines;
		foreach my $info_da (@{$info_da_for_file})
		{
			my $used = $info_da->{'used'};
			my $line = $info_da->{'line'};
		    
			unless (exists($existed_lines{$line}) && $existed_lines{$line} > $used)
			{
			  $existed_lines{$line} = $used;
			}
		}
		
		foreach my $key (keys %existed_lines)
		{
			print ($new_lcov_info_fh "DA:$key,$existed_lines{$key}\n");
		}
		  
		print ($new_lcov_info_fh "end_of_record\n");
	}

	close($new_lcov_info_fh);
	system("genhtml --output-directory $output_dir --legend --quiet $output_lcov");
	vsay ('INFO', "Coverage report is successfully generated\n");
	return $output_lcov;
}


sub merge_original_files
{
	my %options = @_;
	my $output_dir = $options{output_dir};
	if (! -d $output_dir) {
		mkdir($output_dir) or die ("Can't create $output_dir\n");
	}
	my $file_list = $options{file_list};
	my $output_file = $output_dir."coverage.orig";
	
	my %info_fn;
	my %info_fnda;
	my %info_da;
	my $file_number = @$file_list;
	if ($file_number < 1) {
		print "Error! There are no .info files";
		return;
	}
	if ($file_number == 1)
	{
		vsay ('DEBUG', "Only one file for coverage report\n");
		system("cp @$file_list[0] $output_file");
		system("genhtml --output-directory $output_dir --legend --quiet $output_file");
		return;
	}
	foreach my $orig_file (@$file_list)
	{
		open(my $orig_fh, "<", $orig_file) or die("Can't open file for read $orig_file\n");
		
		my $current_file;
top2:		while (<$orig_fh>)
		{
			my $str = $_;
	  
	  		chomp($str);
	 		 
	 		next if ($str =~ /^TN/);
	  
			if ($str =~ /^SF:(.+)$/)
			{
				$current_file = $1;
			}
			
			if ($str =~ /^FN:(\d+),(.+)$/)
			{
			    	push(@{$info_fn{$current_file}}, {'line' => $1, 'func'=>$2});
			}

			if ($str =~ /^FNDA:(\d+),(.+)$/)
			{
				my $function_name = $2;
				my $function_counter = $1;
			    	foreach my $func (@{$info_fnda{$current_file}})
                                {
                                        if ($func->{'name'} eq $function_name)
                                        {
                                                my $new_value = $func->{'value'} + $function_counter;
                                                $func->{'value'} =  $new_value;
                                                next top2;
                                        }
                                }
                                push(@{$info_fnda{$current_file}}, {'name' => $function_name, 'value' => $function_counter});
			}
			  
			if ($str =~ /^DA:(\d+),(.+)$/)
			{
				foreach my $tmp_info (@{$info_da{$current_file}})
				{
					if ($tmp_info->{'line'} == $1) {
						my $new_usage = $tmp_info->{'used'} + $2;
						$tmp_info->{'used'} = $new_usage;
						next top2;
					}
				}
			    
				push(@{$info_da{$current_file}}, {'line' => $1, 'used'=>$2});
			}
		}
		close($orig_fh);
	}
	open(my $output_file_fh, ">", $output_file) or usage("Can't open LCOV file for write: $output_file");
	
	foreach my $file (keys(%info_fn))
	{
		if ($file !~ '^/')
		{
			vsay ('INFO', "File '$file' has relative path and was skipped from coverage merging\n");
			next;
		}
		  
		if (!-f $file)
		{
			vsay ('INFO', "File '$file' was skipped from coverage merging\n");
			next;
		}

		print ($output_file_fh "TN:\nSF:$file\n");
		  
		my $info_fn_for_file = $info_fn{$file};
		my @current_functions;
		foreach my $info_fn (@{$info_fn_for_file})
		{
			my $fn_name = $info_fn->{'func'};
			my $fn_line = $info_fn->{'line'};
		    	push (@current_functions, $fn_name);
			print ($output_file_fh "FN:$fn_line,$fn_name\n");
		}

		my $current_fnda = $info_fnda{$file};
func_process:   foreach my $fn_name (@current_functions)
                {
                        foreach my $tmp_fn (@{$current_fnda})
                        {
                                if ($tmp_fn->{'name'} eq $fn_name)
                                {
                                        print ($output_file_fh "FNDA:$tmp_fn->{'value'},$fn_name\n");
                                        next func_process;
                                }
                        }
                }
		  
		my $info_da_for_file = $info_da{$file};
		foreach my $current_info_da (@{$info_da_for_file})
		{
			my $used = $current_info_da->{'used'};
			my $line = $current_info_da->{'line'};
		   
			print ($output_file_fh "DA:$line,$used\n");
		}
		  
		print ($output_file_fh "end_of_record\n");
	}
	close($output_file_fh);
	system("genhtml --output-directory $output_dir --legend --quiet $output_file");
	vsay ('INFO', "Coverage reports are successfully merged\n");
}
