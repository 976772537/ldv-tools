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

	# Unpacks archive specified by file name
	# NOTE Paths are absolute, so the data will be unpacked to the correct place.
	def unpack(archive)
		# Trace log level doesn't work here... I don't know why...
		@log.add(1, "Unpacking #{archive}")
		say_and_run(%w(pax -r -O -f),archive)
	end

	# Downloads package for the key given and unpacks it
	def download_and_unpack(key,destination)
		download key,destination

		FileUtils.mkdir_p dir
		local_pack = File.join dir,name_for(key,destination)
		@log.info "Unpacking package for #{key}"
		unpack(local_pack)
		@log.info "Unpack finished"
	end

	# Sends files to parent of key, and posts them to the file server via SCP
	# Destination may be either :to_parent and :to_child
	def send_files key, destination, files, opts = {}
		package_name = name_for(key.join("."),destination)
		@log.debug "call send_files: name: #{package_name.inspect}, fi: #{files.inspect}"
		return true if files.empty?

		archive_name = File.join(dir,package_name)
		FileUtils.mkdir_p File.dirname archive_name

		if rewrite = opts[:rewrite]
			expanded_files = files
			rewrite_paths = rewrite
		else
			# By default -- expand file names to absolute, so that the archive would unpack at the receiver's site easily
			expanded_files = files.map {|fname| File.expand_path fname }
			rewrite_paths = nil
		end

		@log.warn "Send results package #{package_name}"
		pax_args = [%w(pax -O -w -x cpio),expanded_files,"-f",archive_name]
		pax_args.push('-s',rewrite_paths) if rewrite_paths
		say_and_run(*pax_args)
		# Copy the resultant archive to the server
		raise "LDV_FILESRV is not set!  Can't sent anything anywhere!" unless filesrv
		say_and_run("scp",archive_name,filesrv)
	end

	# Get package file name for the key given
	private; def name_for key, destination
		"#{key}-#{(destination == :to_parent)? 'to':'from'}-parent.pax"
	end
end


