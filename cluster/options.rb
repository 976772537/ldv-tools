require 'optparse'
class ClusterOptionsParser

	include Nanite::CommonConfig

	attr_accessor :options, :banner

	def initialize(opts,bnr = "Usage: #{$0} [-flag] [argument]")
		@options=opts
		@banner=bnr
	end

	def do_parse
		opts = OptionParser.new do |opts|
			opts.banner = banner
			opts.define_head "Nanite Agent: ruby process that acts upon messages passed to it by a mapper."
			opts.separator '*'*80

			setup_common_options(opts, options, 'agent')

			opts.on("-n", "--nanite NANITE_ROOT", "Specify the root of your nanite agent project.") do |nanite|
				options[:root] = nanite
			end

			opts.on("--ping-time PINGTIME", "Specify how often the agents contacts the mapper") do |ping|
				options[:ping_time] = ping
			end
			
			opts.on("--actors-dir DIR", "Path to directory containing actors (NANITE_ROOT/actors by default)") do |dir|
				options[:actors_dir] = dir
			end
			
			opts.on("--actors ACTORS", "Comma separated list of actors to load (all ruby files in actors directory by default)") do |a|
				options[:actors] = a.split(',')
			end

			opts.on("--initrb FILE", "Path to agent initialization file (NANITE_ROOT/init.rb by default)") do |initrb|
				options[:initrb] = initrb
			end

			opts.on("--single-threaded", "Run all operations in one thread") do
				options[:single_threaded] = true
			end
			
			opts.on("--threadpool COUNT", Integer, "Number of threads to run all operations in") do |tps|
				options[:threadpool_size] = tps
			end
			
			opts.on("--prefetch COUNT", Integer, "The number of messages stuffed into the queue at anytime.  Set this to a value of 1 or so for longer running jobs (1 or more seconds), so the agent does not get overwhelmed.  Default is unlimited.") do |pref|
				options[:prefetch] = pref
			end
		end

		opts.parse!
		get_opts_from_env!
		set_env_for_opts!
	end

	Opts_env = { :host => 'LDV_WATCHER_SRV', :vhost => 'LDV_CLUSTER_VHOST', :user=>'LDV_CLUSTER_USER', :pass => 'LDV_CLUSTER_PASS', :format => 'LDV_CLUSTER_FORMAT'  } 
	Opts_sym = [ :format ]

	def get_opts_from_env!
		Opts_env.each {|key,env| options[key] = ENV[env] if ENV[env]}
		Opts_sym.each {|key|  options[key] = options[key].to_sym if options[key] }
	end
	def set_env_for_opts!
		Opts_env.each {|key,env|$log.warn "SET ENV : #{env} = #{options[key].inspect}!" if $log}
		Opts_env.each {|key,env|ENV[env] = options[key].to_s if options[key]}
		$log.warn "SET ENV!" if $log
	end
end

