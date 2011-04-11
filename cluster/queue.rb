# Helper for queue
require 'rubygems'
require 'nanite'
$:.unshift File.dirname(__FILE__)
require 'waiter.rb'

def start_queue(opts = {}, &actions)
	agent = Nanite::Agent.new( {:format => :json, :ping_time => 4, :identity => 'main_queue', :fragile=>true, :root => File.dirname(__FILE__)}.merge opts)
	agent.run
	queue = agent.registry.actors['ldvqueue']
	# Invoke reconfiguration at once, since there's no way to do it through constructor in Nanite
	queue.reconfigure(opts)
	queue.init_waiter({:format => :json}.merge opts)
	if actions
		actions.call queue
	else
		queue
	end
end

