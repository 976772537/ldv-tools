#!/usr/bin/env ruby
# Application to issue a couple of test requests

require 'rubygems'
require 'nanite'

$:.unshift File.dirname(__FILE__)
require 'options.rb'

opts_p = ClusterOptionsParser.new({})
opts_p.do_parse

EM.run do
  agent = Nanite::Agent.new({:host => 'localhost', :log_level => 'debug', :format => :json, :ping_time => 4, :identity => 'tester', :initrb => 'tester.rb'}.merge opts_p.options)
	agent.run

	Nanite.push("/ldvnode/hello", "I'm testing you!", :offline_failsafe => true, :selector => :ldv_selector)
	(1..1).each do |i|
		#Nanite.push("/ldvqueue/queue", { :type => 'ldv', :args => "task #{i}", :key => "ldv.#{i}", :env => {'RCV_TIMEOUT'=>20,'LDV_DEBUG'=>20,'envs'=>'linux-2.6.31.6.tar.bz2','drivers'=>'wl12xx.ko.tar.bz2','rule_models'=>'32_7'} }, :offline_failsafe => true, :selector => :ldv_selector)
		Nanite.push("/ldvqueue/queue", { :type => 'ldv', :args => "task #{i}", :workdir=>'/tmp/cluster/wd', :key => "ldv.#{i}", :env => {'RCV_TIMEOUT'=>20,'envs'=>'linux-2.6.31.6.tar.bz2','drivers'=>'wl12xx.ko.tar.bz2','rule_models'=>'32_7'}, 'parent_machine' => {} }, :offline_failsafe => true, :selector => :ldv_selector)

	#Nanite.push("/ldvqueue/queue", {:key=>"ldv.1.dscv.20", :workdir=>"/home/pavel/work/ldv/test/work/current--X--wl12xx.ko.tar.bz2--X--defaultlinux-2.6.31.6--X--32_7/linux-2.6.31.6/csd_deg_dscv/20/dscv_tempdir", :type=>"dscv", :env=>{'LDV_DEBUG'=>'30'}, :args=>"<input>\n  <report>/home/pavel/work/ldv/test/work/current--X--wl12xx.ko.tar.bz2--X--defaultlinux-2.6.31.6--X--32_7/linux-2.6.31.6/csd_deg_dscv/20/dscv_tempdir/report_after_dscv.xml</report>\n  <workdir>/home/pavel/work/ldv/test/work/current--X--wl12xx.ko.tar.bz2--X--defaultlinux-2.6.31.6--X--32_7/linux-2.6.31.6/csd_deg_dscv/20/dscv_tempdir</workdir>\n  <ruledb>/home/pavel/tmp/ldv/ldv-core/../kernel-rules/model-db.xml</ruledb>\n  <properties>32_7</properties>\n  <cmdfile>/home/pavel/work/ldv/test/work/current--X--wl12xx.ko.tar.bz2--X--defaultlinux-2.6.31.6--X--32_7/linux-2.6.31.6/csd_deg_dscv/20/cmd_after_deg.xml</cmdfile>\n</input>\n"})
	end
	#(1..3).each do |i|
		#Nanite.push("/ldvqueue/queue", { :type => 'dscv', :args => "task #{i}", :workdir=>'/', :key => "dscv.#{i}", :env => {} }, :offline_failsafe => true, :selector => :ldv_selector)
	#end

end




