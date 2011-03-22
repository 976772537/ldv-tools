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
		Nanite.push(target, payload, :selector => :ldv_selector)
		EM.add_timer(3) { @log.trace "Sender dies" if @log; EM.stop }
	end

end

