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
		$stderr.puts "New sender: #{({:format => :json, :initrb => File.join(@options[:root],'tester.rb')}.merge @options).inspect}"
		agent = Nanite::Agent.new({:format => :json, :initrb => File.join(@options[:root],'tester.rb')}.merge @options)
		agent.run
	end

	def send(target,payload)
		Nanite.push(target, payload, :selector => :ldv_selector)
		#$stderr.puts "Pushed #{payload.inspect}.  Dying in 3 seconds"
		EM.add_timer(3) { EM.stop }
	end

end

