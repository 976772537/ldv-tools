
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
		$stderr.puts "ARGV #{ARGV.inspect}"
		$stderr.puts "Waiting with key #{key}"
		wait_timer = EM.add_periodic_timer(4) do 
			# Pop one message from a queue.  If queue is empty, the block will be enterred with nil as an argument.
			# Then, do nothing and try again
			$stderr.puts "Waiting with key #{key}"
			self.queue.bind(topic, :key=>key).pop do |header, body|
				# I don't know how to check properly, but if the queue is empty, header is not nil, but its properties are!
				$stderr.puts "Got something... #{header.inspect} b #{body.inspect}"
				unless body.nil?
					received_key = header.properties[:routing_key]
					$stderr.puts "**********************************************************************************"
					$stderr.puts "Got key: #{received_key}"
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
		$stderr.puts "ROUTED RESULTS!  KEY: #{key} pay: #{payload.inspect}"
		#topic.publish('hello,world', :routing_key => key, :mandatory => true)
		payload ||= "no payload!"
		self.topic.publish(serializer.dump(payload), :routing_key => key, :immediate => true)
	end

end

