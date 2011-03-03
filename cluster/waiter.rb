
# Waiter is a class which implements synchronous waits with aid of AMQP
# Its core is an AMQP's "topic exchange".  To signal that a job is done, initialize a waiter instance and invoke +job_done+ method with a routing key and a payload.
# To wait for such signals, invoke +wait_for+ with a routing key, which can contain AMQP wildcards.
#
# AMQP is used in the following way: +wait_for+ creates temporal queues and establishes a binding with a central exchange (ldv-wait-for-results).  Then, +job_done+ merely publishes it to the exchange.
# If at the moment of publication, no queue with a proper binding is connected to the exchange, the job is kept in the local array, and the waiter wakes up each 5 seconds, and tries to send the requests again.
# Note that +job_done+ won't block in this case, but will just add a packet to a local array and ensure that the eventmachine-based timer is started.  In any case, +job_done+ should be called at master's site, not at node's site.

require 'fileutils'
require 'logger'

class Waiter

	include Nanite::AMQPHelper

	attr_accessor :options, :serializer, :mq

	DEFAULT_OPTS = { :format => :json }.freeze
	# Create a new waiter instance.  Options is a hash:
	# 	:host, :port, :vhost, :user, :pass => AMQP connection parameters
	# 	:format => ruby serialization format
	def initialize(opts = {})
		@options = DEFAULT_OPTS.merge opts
		@serializer = Nanite::Serializer.new(@options[:format])

		@mq = start_amqp(@options)

		@stash_lock = Mutex.new
		# Set up a callback for messages that aren't consumed by any waiters -- we should stash them
		set_noroute_callback

		# Logging proxy: should work both with cluster's sophisticated logging and without it
		if defined? Logging
			@log = Logging.logger['Task']
		else
			@log = Logging.logger.new(STDERR)
			@log.level = Logger::WARN
		end
	end

	def topic
		@topic ||= mq.topic('ldv-wait-for-results', :durable => true)
	end

	def queue
		# This will only create one queue
		@rn ||= rand(10000)
		@queue ||= mq.queue("ldv-results-queue-#{@rn}", :exclusive => true, :auto_delete => true)
	end

	# Waits for the key specified.  The key is an AMQP topic exchange key
	def wait_for(key) 
		# Issue a blocking binding, and wait for a result
		packet = nil
		@log.warn "Waiting for tasks with key #{key}..."
		self.queue.bind(topic, :key=>key).subscribe do |header, body|
			# I don't know how to check properly, but if the queue is empty, header is not nil, but its properties are!
			received_key = header.properties[:routing_key]
			@log.warn "Received results for key: #{received_key}"
			packet = serializer.load(body)
			# Copy packet's data to a proper place and fill in the following vars
			# NOTE: this should be in sync with watcher's cluster interface
			package_name = "#{received_key}-to-parent.pax"
			# TODO: replace "/tmp" with something more sane
			package_dir = "/tmp/incoming"
			FileUtils.mkdir_p package_dir
			contents = File.join package_dir,package_name
			say_and_run("scp","#{ENV['LDV_FILESRV']}/#{package_name}",contents)

			# ! It so happens that we ignore path--paths are recorded in the package
			path = ''

			# Print info and flush
			to_out = [path,contents] + received_key.split('.');
			$stdout.sync = true
			$stdout.puts(to_out.join(','))
			$stdout.flush
		end
	end

	# Signal that a job is done.
	def job_done(key,payload)
		@log.debug "Trying to send a result message to key #{key}..."
		self.topic.publish(serializer.dump(payload), :routing_key => key, :mandatory => true)
	end

	# Sets up a callback for noroute messages.
	# It's a very crude AMQP patch, and it works really badly.  Don't blame me, please, it's not my fault that AMQP in ruby's crap!
	def set_noroute_callback
    MQ.message_returned { |msg|
      if msg.reply_text == 'NO_ROUTE'
				key = msg.routing_key
				payload = serializer.load(msg.original_body)
				@log.debug "Broker returned a message to #{key} with code #{msg.reply_code} (#{msg.reply_text})"
				stash_request key,payload
			else
				@log.error "Broker returned a message to #{key} with code #{msg.reply_code} (#{msg.reply_text})"
			end
    }
	end

	def stash_request key, payload
		@stash_lock.synchronize do
			@stash ||= []
			@stash << {:key => key, :payload => payload}
		end
		ensure_stash_loop_runs
	end

	# Start loop that tries to send stashed events
	def ensure_stash_loop_runs
		# ||= make us sure that loop is run only once
		@stash_loop ||= EM.add_periodic_timer(@options[:result_send_time] || 5) do
			# We should clone our stash, and make the original one empty.  Messages about failed delieveries will start coming asynchronously even before we finish sending
			retry_packages = []
			@stash_lock.synchronize do
				retry_packages = @stash.dup
				@stash = []
			end
			retry_packages.each do |req|
				self.topic.publish(serializer.dump(req[:payload]), :routing_key => req[:key], :mandatory => true)
				@log.debug "Trying to send a result message to key #{req[:key]}..."
			end
			# The undelievered messages will be stashed (see ensure_ as soon as the relevant async messages arrive
		end
	end

end

