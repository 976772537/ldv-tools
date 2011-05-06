require 'tempfile'
require 'fileutils'
require 'rubygems'
require 'nanite'

$:.unshift File.dirname(__FILE__)
require 'utils.rb'
require 'packer.rb'

class Nodeui
	include Nanite::Actor
	expose :take_unique_key

	def initialize
		# NOTE that we should reconfigure at once, since we should announce the initial status
		reconfigure({})
	end

	attr_accessor :opts
	# Reconfigures the actor with the new config
	def reconfigure(opts)
		@opts = opts.dup
		@log = Logging.logger['Generic']

		@master_timeout = 10
	end

	# Stop timer.  If mapper does not respond in @master_timeout seconds, then the node exits.  We do this asynchronously, by setting up a death timer, and canceling it when a response comes
	def initialize_death_clock(service = '')
		@log.debug "Adding death timer"
		@death_clock = EM.add_timer(@master_timeout) {@log.fatal "Cluster does not respond from amqp://#{opts[:user]}@#{opts[:host]}#{opts[:vhost]}#{service}. Exit."; exit 1;}
		@log.trace "Timer: #{@death_clock.inspect}"
	end
	def stop_death_clock
		@log.debug "Stopping death timer"
		@log.trace "Timer: #{@death_clock.inspect}"
		EM.cancel_timer @death_clock
	end

	attr_accessor :packer
	# How lond we wait before package is ready
	MAX_ATTEMPTS = 100
	SLEEP_TIME = 10

	# Gets unique key from node, and launches a task with this key
	def take_unique_key(key)
		@log.info "Received key: #{key}"

		# Package the files supplied and upload them
		@log.info "Packing and sending files you supplied"
		packer = Packer.new(".",opts[:filesrv])
		# HACK: we make all paths absolute because we can't make a single sed regexp to replace both absolute and relative paths with workdir.  With a backslash at the beginning, absolute paths will not be harmed, and relative will be given a slash at the beginning to be replaced with a workdir.
		files_abs = (opts[:files] || []).map {|f| File.expand_path f}
		# Note the / after the workdir!  It's important for a correct regexp is workdir specification itself does not have a /
		packer.send_files [key], :from_parent, files_abs, :rewrite => "|.*/|#{opts[:workdir]}/|p"

		# Set a unique name for the task unless specified
		task_env = opts[:env].dup
		task_env['name'] ||= key

		# Create and launch the relevant task
		task = {
			:type => 'ldv',
			:args => "",
			:workdir=> opts[:workdir],
			:key => key,
			:env => task_env,
			:global => {:sshuser=>opts[:sshuser], :host => opts[:sshhost], :root => opts[:workdir], :filesrv=>opts[:filesrv], :env => task_env}
		}
		@log.debug "Task prepared, here it is: #{task.inspect}.  Sending."
		initialize_death_clock('/ldvqueue/queue')
		Nanite.request('/ldvqueue/queue',task,:offline_failsafe => true, :selector => :ldv_selector) do |res|
			@log.info "Task queued, waiting for its results..."
			stop_death_clock
		end

		# Asynchronously wait for the task to finish
		Waiter.new(opts).wait_async key do |received_key,_|
			@log.info "Task #{received_key.inspect} has finished!  Still, results may not have been uploaded.  Waiting for some time."

			# Download package from server.  If it doesn't download, then wait and try again.
			# The thing is that ldv-core may send the result message when the package is not yet ready.  It may perform the final fixups for up to 10 minutes per kernel.
			attempts = 0
			begin
				if attempts > 0
					@log.debug "Package is not yet ready"
					Kernel.sleep(SLEEP_TIME)
				end
				attempts += 1
				package = packer.download received_key, :to_parent
			end while !package && attempts < MAX_ATTEMPTS

			unless package
				@log.error "Maximal number of attempts reached, package is still not downloaded.  Something bad happened."
			else
				# We do not need to copy package to the current folder--as we have initalized packer to use cwd as the working one
				@log.info "Your results are stored in #{package}"
				# Gracefully exit
				EM.stop_event_loop
			end
		end
	end

end


