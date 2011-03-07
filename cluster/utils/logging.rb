# Logging functionality for the cluster
#
# Essintially, it proxies the ruby logging utils with cluster-specific condig.

require 'rubygems'
require 'logging'

# Open Logging module (of the original logging gem) to add project-specific logging-related functions.
module Logging
	LOG_ROOT_DEFAULT = 'log'
	LOGGING_OPTS_DEFAULTS = {
		# Master logs
		:master_status => :stdout,
		:tasks_verbose => File.join(LOG_ROOT_DEFAULT,'tasks_verbose'),
		:all_verbose => File.join(LOG_ROOT_DEFAULT,'master_verbose'),
		:cluster_verbose => File.join(LOG_ROOT_DEFAULT,'cluster_verbose'),
		# Node logs
		:node_status => :stdout,
		:node_verbose => File.join(LOG_ROOT_DEFAULT,'node_verbose'),
		:work_consolidated => File.join(LOG_ROOT_DEFAULT,'work'),
		:work_task_dir => LOG_ROOT_DEFAULT,
	}
	# Creates an appender acoording to the destination
	def self.mkappender(destination,opts = {})
		layout = Layouts::Pattern.new(:pattern => '%6p| %d %c: %5l: %m\n')
		if destination == :stdout
			appenders.stdout({:layout => layout}.merge opts)
		else
			FileUtils.mkdir_p File.dirname(destination)
			appenders.file(destination,{:layout => layout}.merge(opts))
		end
	end
	@@opts = {}
	def self.opts
		@@opts
	end
	Levels = %w(trace debug info normal warn error fatal)
	def self.ldv_logging_smallinit(_opts)
		opts = LOGGING_OPTS_DEFAULTS.merge _opts
		# Save options
		@@opts = opts.dup

		# Init LDV-specific logging levels
		Logging.init(Levels.map{|l| l.to_sym})

		# Create a generic logger
		logger['Generic'].add_appenders(
			mkappender(:stdout, :level=>:info)
		)
	end

	def self.ldv_logging_init(_opts)
		ldv_logging_smallinit _opts
		# Task logger is responsible for displaying tasks information
		logger['Task'].add_appenders(
			mkappender(opts[:master_status], :level=>:info),
			mkappender(opts[:tasks_verbose], :level=>:all),
			mkappender(opts[:all_verbose],   :level=>:all)
		)
		# Cluster logger is responsible for information about cluster status
		logger['Cluster'].add_appenders(
			mkappender(opts[:master_status], :level=>:warn),
			mkappender(opts[:all_verbose],   :level=>:all)
		)

		# Node main loggers
		logger['Node'].add_appenders(
			mkappender(opts[:node_status], :level=>:info),
			mkappender(opts[:node_verbose], :level=>:all)
		)
		# Log for nanite-related node events
		logger['Nanite'].add_appenders(
			mkappender(opts[:node_verbose], :level=>:all),
			mkappender(opts[:node_status], :level=>:error)
		)
		# Consolidate all node loggers
		consolidate 'Node'
	end

	# Hask key -> logger
	@@key_logger = {}
	# Yield a logger for a node task with the key given
	def self.logger_for key
		@@key_logger[key] ||= new_logger_for(key)
	end

	def self.new_logger_for key
		l = logger["Node::#{key}"]
		l.additive = true	# copy to the consolidated logger
		l.add_appenders(
			# Per-node logging file output
			mkappender(File.join(@@opts[:work_task_dir],"node_#{key}.trace"), :level=>:all),
			mkappender(File.join(@@opts[:work_task_dir],"node_#{key}"),       :level=>:normal)
			# Consolidated log for all nodes
			# automaded--due to additivity
			#mkappender(@@opts[:work_consolidated],       :level=>:info)
		)
		l
	end
end

