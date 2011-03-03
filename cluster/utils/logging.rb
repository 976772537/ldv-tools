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
	def self.ldv_logging_init(_opts)
		opts = LOGGING_OPTS_DEFAULTS.merge _opts

		# Init LDV-specific logging levels
		init :trace, :debug, :info, :warn, :error, :fatal

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
		# Node logger is TODO

	end
end

