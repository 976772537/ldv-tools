
# Include Cluster's command send capabilities
$cluster_dir = File.dirname(__FILE__)
require File.join($cluster_dir,'sender.rb')
require File.join($cluster_dir,'waiter.rb')
require File.join($cluster_dir,'packer.rb')
require File.join($cluster_dir,'utils.rb')

# For current user name
require 'etc'

class WatcherRemote < Watcher
	REMOTE_OPTS = {
		:host => 'localhost',
		:user => 'ldv',
		:vhost => '/ldv',
		:spawn_key => nil
	}
	attr_accessor :spawn_key, :opts
	public; def initialize(_opts = {})
		@opts = REMOTE_OPTS.merge(_opts.dup)
		super(@opts)

		$log.debug "External key is #{ENV['LDV_SPAWN_KEY']}"
		config[:spawn_key] ||= ENV['LDV_SPAWN_KEY']
		split_spawn_key
	end

	def waiter
		@waiter ||= Waiter.new(REMOTE_OPTS.merge(opts))
	end
	def packer
		# Use directory set up from env
		#FileUtils.mkdir_p File.join('incoming') 
		@packer ||= Packer.new(ENV['LDV_FILES_TMPDIR'],opts[:filesrv])
	end

	def sender
		unless @sender
			@sender = NaniteSender.new({:log_level=>:warn, :log=>$log}.merge opts)
			$log.debug "sender init opts #{opts.inspect}"
		end
		@sender
	end

	public; def key(_)
		puts spawn_key.join(",")
	end

	public; def wait(type,*key)
		$log.info "Waiting for #{type} with keys #{key.inspect}"
		EM.run { waiter.wait_for(key.join('.')) }
	end

	public; def queue(what,task_fname,workdir,*key__files)
		key, files = separate_args key__files
		$log.info "Queueing #{what} task with #{task_fname} and wd #{workdir}"

		$log.warn "Packing files #{files.inspect}"
		packer.send_files key,:from_parent,files

		payload = { :type => what, :args => (ENV['LDV_NOREAD_TASKS'] ? 'intentionally empty' : IO.read(task_fname)), :key => mk(key), :env => [], :workdir => workdir }
		EM.run { sender.send('/ldvqueue/queue', payload)}
	end

	# Successful task completion
	# Following double dash are the files to send to parent
	public; def success(type,*key__files)
		key, files = separate_args key__files
		$log.debug "Success.  Key: #{key.inspect}, files: #{files.inspect}, kf: #{key__files.inspect}"
		result 'success', type, key, files
	end

	public; def fail(type,*key__files)
		key, files = separate_args key__files
		$log.debug "FAIL!.  Key: #{key.inspect}, files: #{files.inspect}, kf: #{key__files.inspect}"
		result 'fail', type, key
	end

	public; def unpack(path,contents)
		# We ignore +path+ since it's hardcoded in the archive
		# We use -O to make pax not prompt user for anything (for instance, when archive file's not found)

		# First, print archive contents to stdout to notify the user what files we have here
		Kernel.system('pax','-O','-f',contents)

		# Perform the unpack
		packer.unpack contents

		# After we unpacked, and the files appeared in the filesystem, we may remove the archive.
		FileUtils.rm_f contents

		return nil # Suppress printing
	end

	private; def mk(key)
		key.join('.')
	end

	private; def split_spawn_key
		raise "You're using a remote cluster, and you don't have a SPAWN KEY set!" unless config[:spawn_key]
		self.spawn_key = config[:spawn_key].split('.')
	end

	private; def result(message,type,key,files = [])
		# Package files
		packer.send_files key,:to_parent,files
		# Send task
		task = {:key => key.join('.'), :type => type}
		EM.run { sender.send('/ldvqueue/result', task) }
	end


end

