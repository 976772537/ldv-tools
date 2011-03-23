# Ruby interface to sending stuff to cluster
#
require 'rubygems'
require 'nanite'

class NaniteSender

	attr_accessor :options
	def initialize(opts = {})
		@options = opts.dup
		@options[:ping_time] = 1
		@options[:root] = File.dirname(__FILE__)

		@log = opts[:log]
		@log.trace "New sender: #{({:format => :json, :initrb => File.join(@options[:root],'tester.rb')}.merge @options).inspect}" if @log
		agent = Nanite::Agent.new({:format => :json, :initrb => File.join(@options[:root],'tester.rb')}.merge @options)
		agent.run
	end

	def send(target,payload)
		@log.trace "Sending payload #{payload.inspect}" if @log
		# Instead of push/die, we do a request/die, because three seconds is sometimes not enough for cluster to process yet another small node.
		Nanite.request(target, payload, :selector => :ldv_selector) do |res|
			@log.trace "Reply gotten.  Sender dies in a second." if @log
			# Die, but do it outside this handler.
			EM.add_timer(0.5) { EM.stop }
		end
	end

end

