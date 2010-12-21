
class Waiter

	include Nanite::AMQPHelper

	attr_accessor :options, :serializer, :mq

	# Create a new waiter instance.  Options is a hash:
	# 	:host, :port, :vhost, :user, :pass => AMQP connection parameters
	# 	:format => ruby serialization format
	def initialize(opts = {})
		@options = opts.dup
		@serializer = Nanite::Serializer.new(options[:format])

		@mq = start_amqp(opts)
	end

	def topic
		mq.topic('ldv-wait-for-results', :durable => true)
	end

	# Waits for the key specified.  The key is an AMQP topic exchange key
	def wait_for(key) 
		# Issue a blocking binding, and wait for a result
		packet = nil
		EM.add_periodic_timer(2) do 
			# Pop one message from a queue.  If queue is empty, the block will be enterred with nil as an argument.
			# Then, do nothing and try again
			rn = rand(10000)
			mq.queue("ldv-results-queue-#{rn}").bind(topic, :key=>key).pop do |header, body|
				# I don't know how to check properly, but if the queue is empty, header is not nil, but its properties are!
				unless body.nil?
					received_key = header.properties[:routing_key]
					$stderr.puts "Got key: #{received_key}"
					packet = serializer.load(body)
					# TODO: Copy packet's data to a proper place
					$stdout.puts(received_key.split('.').join(','))
					exit 0
				end
			end
		end
		packet
	end

	# Signal that a job is done.
	def job_done(key,payload)
		topic.publish(serializer.dump(payload), :routing_key => key)
	end

end

