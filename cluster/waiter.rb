
class Waiter

	include Nanite::AMQPHelper

	attr_accessor :options, :serializer, :mq

	# Create a new waiter instance.  Options is a hash:
	# 	:host, :port, :vhost, :user, :pass => AMQP connection parameters
	# 	:format => ruby serialization format
	def initialize(opts = {})
		@options = opts.dup
		@serializer = Nanite::Serializer.new(@options[:format])

		@mq = start_amqp(@options)

		@stash_lock = Mutex.new
		# Set up a callback for messages that aren't consumed by any waiters -- we should stash them
		set_noroute_callback
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
		$stderr.puts "Waiting for tasks with key #{key}..."
		wait_timer = EM.add_periodic_timer(5) do 
			# Pop one message from a queue.  If queue is empty, the block will be enterred with nil as an argument.
			# Then, do nothing and try again
			$stderr.puts "Still waiting for tasks with key #{key}"
			self.queue.bind(topic, :key=>key).pop do |header, body|
				# I don't know how to check properly, but if the queue is empty, header is not nil, but its properties are!
				unless body.nil?
					received_key = header.properties[:routing_key]
					$stderr.puts "**********************************************************************************"
					$stderr.puts "Received results for task with key: #{received_key}"
					$stderr.puts "**********************************************************************************"
					packet = serializer.load(body)
					# TODO: Copy packet's data to a proper place and fill in the following vars
					path = ''
					contents = ''
					to_out = [path,contents] + received_key.split('.');
					$stdout.puts(to_out.join(','))
					#wait_timer.cancel
					EM.stop
				end
			end
		end
		packet
	end

	# Signal that a job is done.
	def job_done(key,payload)
		$stderr.puts "Trying to send a result message to key #{key}..."
		self.topic.publish(serializer.dump(payload), :routing_key => key, :mandatory => true)
	end

	# Sets up a callback for noroute messages.
	# It's a very crude AMQP patch, and it works really badly.  Don't blame me, please, it's not my fault that AMQP in ruby's crap!
	def set_noroute_callback
    MQ.message_returned { |msg|
      if msg.reply_text == 'NO_ROUTE'
				key = msg.routing_key
				payload = serializer.load(msg.original_body)
				puts "Broker returned a message to #{key} with code #{msg.reply_code} (#{msg.reply_text})"
				stash_request key,payload
			else
				puts "ERROR? Broker returned a message to #{key} with code #{msg.reply_code} (#{msg.reply_text})"
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
		@stash_loop ||= EM.add_periodic_timer(5) do
			# We should clone our stash, and make the original one empty.  Messages about failed delieveries will start coming asynchronously even before we finish sending
			retry_packages = []
			@stash_lock.synchronize do
				retry_packages = @stash.dup
				@stash = []
			end
			retry_packages.each do |req|
				self.topic.publish(serializer.dump(req[:payload]), :routing_key => req[:key], :mandatory => true)
				$stderr.puts "Trying to send a result message to key #{req[:key]}..."
			end
			# The undelievered messages will be stashed (see ensure_ as soon as the relevant async messages arrive
		end
	end

end

