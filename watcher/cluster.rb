
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
		$log.debug "External key is #{ENV['LDV_SPAWN_KEY']}"
		opts[:spawn_key] ||= ENV['LDV_SPAWN_KEY']
		super(REMOTE_OPTS.merge(opts))
		split_spawn_key
	end

	public; def key(_)
		puts spawn_key.join(",")
	end

	public; def result
	end

	private; def split_spawn_key
		raise "You're using a remote cluster, and you don't have a SPAWN KEY set!" unless config[:spawn_key]
		self.spawn_key = config[:spawn_key].split('.')
	end
end

