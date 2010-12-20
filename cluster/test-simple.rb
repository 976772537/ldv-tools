#!/usr/bin/env ruby
# Application to issue a couple of test requests

require 'rubygems'
require 'nanite'


EM.run do
  agent = Nanite::Agent.new(:host => 'localhost', :user => 'mapper', :pass => 'testing', :vhost => '/nanite', :log_level => 'debug', :format => :json, :ping_time => 4, :identity => 'tester', :initrb => 'tester.rb')
	agent.run

	Nanite.push("/ldvnode/hello", "I'm testing you!", :offline_failsafe => true, :selector => :ldv_selector)
	(1..1).each do |i|
		Nanite.push("/ldvqueue/queue", { :type => 'ldv', :args => "task #{i}", :workdir=>'/home/pavel/work/ldv/test', :key => "ldv.#{i}", :env => {'RCV_TIMEOUT'=>20,'LDV_DEBUG'=>20,'envs'=>'linux-2.6.31.6.tar.bz2','drivers'=>'wl12xx.ko.tar.bz2','rule_models'=>'32_7'} }, :offline_failsafe => true, :selector => :ldv_selector)
	end
	(1..3).each do |i|
		Nanite.push("/ldvqueue/queue", { :type => 'dscv', :args => "task #{i}", :workdir=>'/', :key => "dscv.#{i}", :env => {} }, :offline_failsafe => true, :selector => :ldv_selector)
	end

end




