
# Include Cluster's command send capabilities
$cluster_dir = File.dirname(__FILE__)
require File.join($cluster_dir,'sender.rb')
require File.join($cluster_dir,'waiter.rb')
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

	def sender
		unless @sender
			@sender = NaniteSender.new({:log_level=>:warn}.merge opts)
			$log.warn "sender init opts #{opts.inspect}"
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
		send_files "#{key.join('.')}-from-parent.pax",files

		# The local IP is the IP as seen by AMQP host
		this_machine_info = {
			# For prototyping reasons, we'll fix this
			#:host => local_ip(ENV['LDV_ABROAD'] || self.opts[:host]),
			:host => 'shved',
			:sshuser => 'pavel',
			:root => '/mnt/cluster/work',
		}
		payload = { :type => what, :args => (ENV['LDV_NOREAD_TASKS'] ? 'intentionally empty' : IO.read(task_fname)), :key => mk(key), :env => [], :workdir => workdir, :parent_machine => this_machine_info  }
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
		#$stderr.puts "Unpack!"
		# We ignore +path+ since it's hardcoded in the archive
		# We use -O to make pax not prompt user for anything (for instance, when archive file's not found)

		# First, print archive contents to notify the user what files we have here
		say_and_run(%w(pax -O -f),contents)

		# FIXME: during development we ignore the error in unpacking
		# NOTE: Currently, the package is transferred to the local machine in @waiter.  Should make a better mechanism for that.
		say_and_run(%w(pax -r -O -f),contents)
		$log.warn "Unpacking finished!"
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
		send_files "#{key.join('.')}-to-parent.pax",files
		# Send task
		task = {:key => key.join('.'), :type => type}
		$stderr.puts "******************************\n\nSending result for task #{task.inspect}\n\n"
		EM.run { sender.send('/ldvqueue/result', task) }
	end

	# Sends files to +ENV['LDV_FILESRV']+ as destination for SCP
	# TODO: fix this env var (or not? or set it up in the cluster node spawn operation?)
	private; def send_files package_name, files
		$log.warn "name: #{package_name.inspect}, fi: #{files.inspect}"
		return true if files.empty?
		# TODO : fix /tmp here
		archive_name = File.join("/tmp",package_name)
		# Expand file names to absolute, so that the archive would unpack at the receiver's site easily
		expanded_files = files.map {|fname| File.expand_path fname }
		say_and_run(%w(pax -w -x cpio),expanded_files,"-f",archive_name)
		# Copy the resultant archive to the server
		raise "LDV_FILESRV is not set!  Can't sent anything anywhere!" unless ENV['LDV_FILESRV']
		say_and_run("scp",archive_name,ENV['LDV_FILESRV'])
	end

end

