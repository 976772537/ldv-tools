
# Include Cluster's command send capabilities
$cluster_dir = File.dirname(__FILE__),'..','cluster'
require File.join($cluster_dir,'sender.rb')

class WatcherRemote < Watcher
	REMOTE_OPTS = {
		:host => 'localhost',
		:user => 'ldv',
		:vhost => '/ldv',
		:spawn_key => nil
	}
	attr_accessor :spawn_key
	public; def initialize(_opts = {})
		opts = _opts.dup
		super(REMOTE_OPTS.merge(opts))

		$log.debug "External key is #{ENV['LDV_SPAWN_KEY']}"
		config[:spawn_key] ||= ENV['LDV_SPAWN_KEY']
		split_spawn_key

		@sender = NaniteSender.new(opts)
		@waiter = File.join($cluster_dir,'ldvc-wait-task')
	end

	public; def key(_)
		puts spawn_key.join(",")
	end

	public; def wait(type,*key)
		$log.info "Waiting for #{type} with keys #{key.inspect}"
		Kernel.exec @waiter,*key
	end

	public; def queue(what,task_fname,workdir,*key)
		$log.info "Queueing #{what} task with #{task_fname} and wd #{workdir}"
		payload = { :type => what, :args => IO.read(task_fname), :key => mk(key), :env => [], :workdir => workdir }
		@sender.send('/ldvqueue/queue', payload)
	end

	public; def success(type,*key)
		result 'success', type, *key
	end

	public; def fail(type,*key)
		result 'fail', type, *key
	end

	private; def mk(key)
		key.join('.')
	end

	private; def split_spawn_key
		raise "You're using a remote cluster, and you don't have a SPAWN KEY set!" unless config[:spawn_key]
		self.spawn_key = config[:spawn_key].split('.')
	end

	private; def result(message,type,*key)
		task = {:key => key.join('.'), :type => type}
		@sender.send('/ldvqueue/result', task)
	end

end

