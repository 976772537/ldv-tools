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
	end

	def send(target,payload)
		EM.run do
			agent = Nanite::Agent.new({:format => :json, :initrb => File.join(@options[:root],'tester.rb')}.merge self.options)
			agent.run

			Nanite.push(target, payload, :selector => :ldv_selector)
			EM.add_timer(2) { EM.stop }
		end
	end

end

