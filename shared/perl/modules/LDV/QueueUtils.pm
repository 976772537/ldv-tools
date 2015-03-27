# Package for replacement SOAP::Lite. Implement data exchanging within files.
package LDV::QueueUtils;

use File::Basename;
use strict;
use warnings;
use File::Path qw(make_path remove_tree);
use Fcntl qw(:flock SEEK_END);

use vars qw(@ISA @EXPORT_OK @EXPORT);
@EXPORT=qw( init_queue post_message post_data_message);
use base qw(Exporter);

# Initialize queue
sub init_queue {
	my ($index, $collection) = @_;

	# Recreate collection
	if($collection) {
		if (-e $collection) {
			remove_tree $collection;
		}
		make_path $collection;
	}

	# Recreate index file
	if (-e $index) {
		remove_tree $index;
	}
	open my $fh, '>', $index or die "Cannot open index file '$index'";
	close $fh;

	return;
}

# Add new command to both collection and message to index file.
sub post_message {
	my ($index, $type, $message) = @_;

	if ($type =~ /\n|::/g || $message =~ /\n|::/g) {
		die "One can post only one-line messages without '::' to the index of the queue";
	}
	else {
		# Open
		open my $fh, '>>', $index or die "Cannot open index file '$index': $!";
		flock($fh, LOCK_EX) or die "Cannot lock index file '$index': $!";

		# Print
		print {$fh} $type . q{::} . $message . "\n" 
			or die "Cannot print index file '$index': $!";
		
		# Close
		flock($fh, LOCK_UN) or die "Cannot unlock index file '$index': $!";
		close $fh or die "Cannot close index file '$index': $!";
	}

	return;
}

# Send message with data: save data to file and add to the index type with
# path to the file in the collection.
sub post_data_message {
	my ($collection, $index, $data_file, $type, $data) = @_;

	my $file = "$collection/$data_file";
	
	# Prepare path
	my $path = dirname($file);
	if (!-d $path) {
		make_path $path;
	}

	# Post data
	open my $fh, '>', $file or die "Cannot open data file '$file': $!";
	flock($fh, LOCK_EX) or die "Cannot lock data file '$file': $!";
	print {$fh} $data or die "Cannot print to data file '$file': $!";

	# Close
	flock($fh, LOCK_UN) or die "Cannot unlock data file '$file': $!";
	close $fh or die "Cannot close data file '$file': $!";

	# post short message
	post_message($index, $type, "$collection/$data_file");
}

# Add special message which ends collecting
sub finish_collecting {
	return;
}

# Add artificial LDM command
sub add_ldm_command {
	return;
}

# Check that command collecting is finished
sub is_finished {
	return;
}

# Add new command or message to index file
sub __post_to_index {
	return;
}

# Add coomand to the collection
sub __save_to_collection {
	return;
}
 