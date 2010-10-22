package MetaUtils;

use strict;
use vars qw(@EXPORT);
@EXPORT=qw();
use base qw(Exporter);

# Metadata-related stuff
use Graph;
# Hash:  filename -> { hash: includes -> [], calls -> [], provides -> [], changed -> bool }
use constant { META_WAIT => 0, META_READING => 1, META_INCLUDES => 2, META_CALLS => 3, META_PROVIDES => 4};
sub meta_to_hash
{
	my $filename = shift or Carp::confess;
	my $FH;
	open $FH,"<",$filename or die "Can't open metadata file '$filename': $!";
	
	my $result = {};

	my $meta_in_st = {st=>META_WAIT, file => undef};
	local $_;

	while (<$FH>){
		if (/^== (.*)/m){
			$meta_in_st->{st} = META_READING;
			$meta_in_st->{file} = $1;
			$result->{$meta_in_st->{file}} ||= {};
		}elsif (/^-- (.*)/m){
			my $modif = $1;
			if ($modif =~ /included/i && ($meta_in_st->{st} == META_READING)){
				$meta_in_st->{st} = META_INCLUDES;
			}elsif($modif =~ /called/i && ($meta_in_st->{st} == META_INCLUDES)){
				$meta_in_st->{st} = META_CALLS;
			}elsif($modif =~ /provided/i && ($meta_in_st->{st} == META_CALLS)){
				$meta_in_st->{st} = META_PROVIDES;
			}else{
				die "Undefined transition, status: $meta_in_st->{st}";
			}
		}elsif($meta_in_st->{st} == META_CALLS){
			$result->{$meta_in_st->{file}}->{calls} ||= []; 
			chomp;
			# "Called" section may also contain list of callers
			if (/(.*) \[(.*)\]/){
				my $function = $1;
				my @callers = split /\s+/,$2;
				for my $caller (@callers){
					$result->{$meta_in_st->{file}}->{called_by}->{$caller} ||= {};
					$result->{$meta_in_st->{file}}->{called_by}->{$caller}->{$function} = 1;
				}
				push @{$result->{$meta_in_st->{file}}->{calls}}, $function;
			}else{
				# No callers
				push @{$result->{$meta_in_st->{file}}->{calls}}, $_ if $_;
			}
		}elsif($meta_in_st->{st} == META_INCLUDES){
			$result->{$meta_in_st->{file}}->{includes} ||= []; 
			chomp;
			push @{$result->{$meta_in_st->{file}}->{includes}}, $_ if $_;
		}elsif($meta_in_st->{st} == META_PROVIDES){
			$result->{$meta_in_st->{file}}->{provides} ||= []; 
			chomp;
			push @{$result->{$meta_in_st->{file}}->{provides}}, $_ if $_;
		}
	}

	close $FH;
	return $result;
}

use constant { RAW_META_WAIT => 0, RAW_META_READING => 1};
sub meta_to_raw_hash
{
	my $filename = shift or Carp::confess;
	my $filter = shift;
	my $FH;
	open $FH,"<",$filename or die "Can't open metadata file '$filename': $!";
	my $meta_in = meta_to_raw_hash_from_fh($FH,$filter);

	close $FH;
	return $meta_in;
}

sub meta_to_raw_hash_from_fh
{
	my $FH = shift or Carp::confess;
	my $filter = shift;
	# For now we assume that new metadata contain just a few files, and can be loaded to memory.
	my $meta_in = {};
	my $meta_in_st = {st=>RAW_META_WAIT, file => undef};
	local $_;
	while (<$FH>){
		if (/^== (.*)/m){
			$meta_in_st->{st} = RAW_META_READING;
			$meta_in_st->{file} = $1;
			$meta_in->{$meta_in_st->{file}} ||= '';
		}else{
			if ($meta_in_st->{st} == RAW_META_READING
				# Filter is off or this file in it.
				&& (!$filter || $filter->{$meta_in_st->{file}})
			){
				$meta_in->{$meta_in_st->{file}} .= $_;
			}
		}
	}
	return $meta_in;
}

1;

