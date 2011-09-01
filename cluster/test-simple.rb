#!/usr/bin/env ruby
# Application to issue a couple of test requests
#
# Use this to send DSCV requests to the cluster:
# grep /mnt/cluster/master/log/master_out for 'Routed task.*12345', and insert it to the hash in the push below.  NOTE, that there should be a "global" attribute

require 'rubygems'
require 'nanite'

$:.unshift File.dirname(__FILE__)
require 'options.rb'

opts_p = ClusterOptionsParser.new({})
opts_p.do_parse

EM.run do
  agent = Nanite::Agent.new({:host => 'opal.intra.ispras.ru', :user=>'############', :pass=>'###########', :vhost=>'/quick', :log_level => 'debug', :format => :json, :ping_time => 4, :identity => 'tester', :initrb => 'tester.rb'}.merge opts_p.options)
	agent.run

	Nanite.push('/ldvqueue/queue', {"type"=>"dscv", "args"=>"<input>\n  <report>/mnt/cluster/work/work/current--X--drivers/--X--ldv.315linux-3.0.1--X--32_7/linux-3.0.1/csd_deg_dscv/3348/dscv_tempdir/report_after_dscv.xml</report>\n  <workdir>/mnt/cluster/work/work/current--X--drivers/--X--ldv.315linux-3.0.1--X--32_7/linux-3.0.1/csd_deg_dscv/3348/dscv_tempdir</workdir>\n  <ruledb>/mnt/cluster/toolset/kernel-rules/model-db.xml</ruledb>\n  <properties>32_7</properties>\n  <cmdfile>/mnt/cluster/work/work/current--X--drivers/--X--ldv.315linux-3.0.1--X--32_7/linux-3.0.1/csd_deg_dscv/3348/cmd_after_deg.xml</cmdfile>\n</input>\n", "key"=>"ldv.315.dscv.33488", "env"=>{}, "workdir"=>"/mnt/cluster/work/work/current--X--drivers/--X--ldv.315linux-3.0.1--X--32_7/linux-3.0.1/csd_deg_dscv/3348/dscv_tempdir", "global"=>{"sshuser"=>"cluser", "host"=>"opal.intra.ispras.ru", "root"=>"/mnt/cluster/work", "filesrv"=>"cluser@opal.intra.ispras.ru:/mnt/cluster/files/", "env"=>{"envs"=>"linux-3.0.1.tar.bz2", "drivers"=>"drivers/", "kernel_driver"=>"1", "rule_models"=>"32_7", "BLAST_ALIASES"=>"y", "BLAST_PATH"=>"/mnt/cluster/blast/bin", "BLAST_OPTIONS"=>"-ialias -iclos", "name"=>"ldv.315"}, :name=>"ldv.315"}})

	#Nanite.push("/ldvnode/hello", "I'm testing you!", :offline_failsafe => true, :selector => :ldv_selector)
	#(2..2).each do |i|
		##Nanite.push("/ldvqueue/queue", { :type => 'ldv', :args => "task #{i}", :key => "ldv.#{i}", :env => {'RCV_TIMEOUT'=>20,'LDV_DEBUG'=>20,'envs'=>'linux-2.6.31.6.tar.bz2','drivers'=>'wl12xx.ko.tar.bz2','rule_models'=>'32_7'} }, :offline_failsafe => true, :selector => :ldv_selector)
		#Nanite.request("/ldvqueue/queue", {
			#:type => 'ldv',
			#:args => "task 7",
			#:workdir=>'/mnt/cluster/work',
			#:key => "ldv.7",
			#:env => {'RCV_TIMEOUT'=>900,'envs'=>'linux-2.6.31.6.tar.bz2','drivers'=>'drivers/','kernel_driver'=>'1','rule_models'=>'32_7'},
			#:global => {:sshuser=>'pavel', :host => 'shved', :root => '/mnt/cluster/work', :filesrv=>'pavel@shved:/mnt/cluster/files'},
		#}, :offline_failsafe => true, :selector => :ldv_selector) do |x|
			#puts x
			#end
		#Nanite.push("/ldvqueue/queue", {
			#:type => 'ldv',
			#:args => "task #{i}",
			#:workdir=>'/mnt/cluster/work',
			#:key => "ldv.#{i}",
			#:env => {'RCV_TIMEOUT'=>99,'envs'=>'linux-2.6.31.6.tar.bz2','drivers'=>'wl12xx.ko.tar.bz2','rule_models'=>'32_7'},
			##:env => {'RCV_TIMEOUT'=>99,'envs'=>'linux-2.6.31.6.tar.bz2','drivers'=>'wl12xx.tar.bz2','rule_models'=>'32_7'},
			#:global => {:sshuser=>'pavel', :host => 'shved', :root => '/mnt/cluster/work', :filesrv=>'pavel@shved:/mnt/cluster/files'},
		#}, :offline_failsafe => true, :selector => :ldv_selector)
		#Nanite.push("/ldvqueue/queue", { :type => 'ldv', :args => "task #{i}", :workdir=>'/mnt/cluster/work', :key => "ldv.#{i}", :env => {'envs'=>'linux-2.6.31.6.tar.bz2','drivers'=>'drivers/media','rule_models'=>'32_7','kernel_driver'=>'1'}, :global => {} }, :offline_failsafe => true, :selector => :ldv_selector)

	#Nanite.push("/ldvqueue/queue", {:key=>"ldv.1.dscv.20", :workdir=>"/home/pavel/work/ldv/test/work/current--X--wl12xx.ko.tar.bz2--X--defaultlinux-2.6.31.6--X--32_7/linux-2.6.31.6/csd_deg_dscv/20/dscv_tempdir", :type=>"dscv", :env=>{'LDV_DEBUG'=>'30'}, :args=>"<input>\n  <report>/home/pavel/work/ldv/test/work/current--X--wl12xx.ko.tar.bz2--X--defaultlinux-2.6.31.6--X--32_7/linux-2.6.31.6/csd_deg_dscv/20/dscv_tempdir/report_after_dscv.xml</report>\n  <workdir>/home/pavel/work/ldv/test/work/current--X--wl12xx.ko.tar.bz2--X--defaultlinux-2.6.31.6--X--32_7/linux-2.6.31.6/csd_deg_dscv/20/dscv_tempdir</workdir>\n  <ruledb>/home/pavel/tmp/ldv/ldv-core/../kernel-rules/model-db.xml</ruledb>\n  <properties>32_7</properties>\n  <cmdfile>/home/pavel/work/ldv/test/work/current--X--wl12xx.ko.tar.bz2--X--defaultlinux-2.6.31.6--X--32_7/linux-2.6.31.6/csd_deg_dscv/20/cmd_after_deg.xml</cmdfile>\n</input>\n"})
	#end
	#(1..3).each do |i|
		#Nanite.push("/ldvqueue/queue", { :type => 'dscv', :args => "task #{i}", :workdir=>'/', :key => "dscv.#{i}", :env => {} }, :offline_failsafe => true, :selector => :ldv_selector)
	#end

end




