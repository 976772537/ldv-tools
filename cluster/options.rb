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

			opts.on("--route-time ROUTE_TIME", "Specify how often the queue attempts to route a task") do |route_time|
				options[:route_time] = route_time
			end

			opts.on("--announce-time ANN_TIME", "Specify how often the cluster controller announces statuses of the node to the scheduler") do |ann_time|
				options[:announce_time] = ann_time
			end

			opts.on("--result-time RESULT_TIME", "How ofter AMQP waiter tries to deliever pending results") do |time|
				options[:result_send_time] = time
			end

			opts.on("--play-scenario FILENAME", "Instead of doing actual work, just respond to events as written in watcher log in FILENAME") do |fname|
				options[:play_scenario] = fname
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

	Opts_env = { :host => 'LDV_WATCHER_SRV', :vhost => 'LDV_CLUSTER_VHOST', :user=>'LDV_CLUSTER_USER', :pass => 'LDV_CLUSTER_PASS', :format => 'LDV_CLUSTER_FORMAT', :filesrv => 'LDV_FILESRV', :namespace_root => 'LDV_NAMESPACE_ROOT' }
	Opts_sym = [ :format ]

	def get_opts_from_env!
		Opts_env.each {|key,env| options[key] = ENV[env] if ENV[env]}
		Opts_sym.each {|key|  options[key] = options[key].to_sym if options[key] }
	end
	def set_env_for_opts!
		Opts_env.each {|key,env|$log.info "SET ENV : #{env} = #{options[key].inspect}!" if $log}
		Opts_env.each {|key,env|ENV[env] = options[key].to_s if options[key]}
	end
end

