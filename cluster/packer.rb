# Interface to packaging functionality

require File.join(File.dirname(__FILE__),'utils.rb')


# Cluster exchanges large amounts of data by creating PAX archives, up/downloading them to/from file server and packing/unpacking them on local machine.
# This class abstracts these routines
class Packer
	# Create new packer.  Inits with namespace root dir.
	def initialize(namespace_workdir,filesrv)
		@dir = File.join namespace_workdir, 'incoming'
		@log = Logging.logger['Node']
		@filesrv = filesrv
	end

	attr_accessor :dir,:filesrv

	# Downloads package to the special local folder
	# Returns local file with package
	def download(key,destination)
		@log.info "Downloading package for #{key}"

		FileUtils.mkdir_p dir
		local_pack = File.join dir,name_for(key,destination)
		say_and_run("scp","#{filesrv}/#{name_for(key,destination)}",local_pack)

		local_pack
	end

	# Downloads package for the key given and unpacks it
	def download_and_unpack(key,destination)
		download key,destination

		FileUtils.mkdir_p dir
		local_pack = File.join dir,name_for(key,destination)
		# We should also unpack here, as the watcher API doesn't presuppose unpacking at startup.
		# NOTE Paths are absolute, so the data will be unpacked to the correct place.
		@log.info "Unpacking package for #{key}"
		say_and_run(%w(pax -r -O -f),local_pack)
	end

	# Sends files to parent of key, and posts them to the file server via SCP
	# Destination may be either :to_parent and :to_child
	def send_files key, destination, files
		package_name = name_for(key.join("."),destination)
		@log.debug "call send_files: name: #{package_name.inspect}, fi: #{files.inspect}"
		return true if files.empty?

		archive_name = File.join(dir,'tmp',package_name)
		FileUtils.mkdir_p File.dirname archive_name

		# Expand file names to absolute, so that the archive would unpack at the receiver's site easily
		expanded_files = files.map {|fname| File.expand_path fname }

		@log.warn "Send results package #{package_name}"
		say_and_run(%w(pax -O -w -x cpio),expanded_files,"-f",archive_name)
		# Copy the resultant archive to the server
		raise "LDV_FILESRV is not set!  Can't sent anything anywhere!" unless filesrv
		say_and_run("scp",archive_name,filesrv)
	end

	# Get package file name for the key given
	private; def name_for key, destination
		"#{key}-#{(destination == :to_parent)? 'to':'from'}-parent.pax"
	end
end


