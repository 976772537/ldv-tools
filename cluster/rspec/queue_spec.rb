# RSpec for LDV cluster queue

require 'queue.rb'

RSpec.configure do |c|
	#c.filter_run :focus => true
	# Exclude tests which are known to fail due to a badly implmented AMQP binding
	c.filter_run_excluding :amqp_binding_sucks => true
	c.filter_run_excluding :lack_of_rspec_knowledge => true
end

# If a hash contains keys and values as in the expected one
RSpec::Matchers.define :contain_subhash do |expected|
	match do |actual|
		actual.is_a? Hash and expected.inject(true){ |accum,kv| accum &&= actual[kv[0]] == kv[1] }
	end
end

def symbolize(hash)
	hash.inject({}) {|r,kv| r[kv[0].to_sym]=kv[1]; r }
end

def em_for(time = 3)
	EM.run do
		yield
		EM.add_timer(time) { EM.stop }
	end
end

# First, create some stuff
vhost = '/rspecldvc'
vhost_bad = '/rspecldvcbad'
ctl = 'sudo /usr/sbin/rabbitmqctl'
restart = proc do
Kernel.system("
#{ctl} delete_vhost #{vhost} ;
#{ctl} delete_vhost #{vhost_bad};
#{ctl} add_vhost #{vhost} ;
#{ctl} add_user ldv 12345 ;
#{ctl} set_permissions -p #{vhost} ldv '.*' '.*' '.*'
")
end
restart.call

OPTS = {:log_level => :warn}

shared_examples_for "a nanite agent" do 
	context "with unreachable host" do
		it "should tell that" do
			expect { em_for(2) {factory.call(OPTS.merge :host => 'some.unknown.host')}}.to raise_error(EventMachine::ConnectionError)
		end
	end
	context "with unreachable virtual host", :amqp_binding_sucks => true do
		it "should tell that" do
			expect { em_for(2) {factory.call(OPTS.merge :host => 'localhost', :vhost=>vhost_bad)}}.to raise_error
		end
	end
	context "with wrong password" do
		it "should throw on srartup", :amqp_binding_sucks => true do
			expect { em_for(2) {factory.call(OPTS.merge :host => 'localhost', :user=>'ldv', :pass => 'qweiojwqejiorewjoiew', :log_level => :debug)}}.to raise_error
		end
	end
	context "with correct AMQP credentials" do
		it "should not throw on srartup" do
			expect { em_for(1) {factory.call(OPTS.merge({:host => 'localhost', :vhost => '/rspecldvc', :user => 'ldv', :pass => '12345'}))}}.to_not raise_error
		end
	end
	
end

describe "Queue" do
	it_should_behave_like "a nanite agent" do
		let(:factory) { lambda { |arg| start_queue arg } }
	end
	context "with correct AMQP credentials" do
		def mk_queue(opts = {},&blk)
			start_queue(OPTS.merge({:host => 'localhost', :vhost => '/rspecldvc', :user => 'ldv', :pass => '12345'}).merge opts ) {|a| blk.call(a) if blk}
		end

		it "should not queue a nil task"  do
			expect { em_for(1) {mk_queue do |q|
				q.queue(nil)
			end
			}}.to raise_error
		end

		it "should not queue a nil task"  do
			expect { em_for(1) {mk_queue do |q|
				q.queue(nil)
			end
			}}.to raise_error
		end

		it "should not queue a task with wrong type"  do
			em_for(1) do
				mk_queue do |q|
					expect {q.queue({'type'=>'wrong','args'=>'b','workdir'=>'c','key'=>'d','env'=>[]})}.to raise_error
				end
			end
		end

		it "should queue a task with a correct type" do
			em_for(1) do; mk_queue do |q|
					q.queue({'type'=>'dscv','args'=>'b','workdir'=>'c','key'=>'d','env'=>[]})
			end; end
		end

		it "should not send a task with no nodes" do
			Nanite.stub(:push) do |str,task,opts|
				str.should == '/ldvnode'
			end
			Nanite.should_not_receive(:push)

			# 6 is 4+50%, where 4 is the period of sending queued tasks
			em_for(6) do; mk_queue do |q|
					q.queue({'type'=>'dscv','args'=>'b','workdir'=>'c','key'=>'d','env'=>[]})
			end; end
		end

		it "should send a task if there is a node" do
			stub_task = {'type'=>'dscv','args'=>'b','workdir'=>'c','key'=>'d','env'=>[]}
			Nanite.stub(:push) do |str,task,opts|
				str.should == '/ldvnode/dscv'
				task.should == symbolize(stub_task)
				opts.should contain_subhash :target => 'stub_node' 
			end
			Nanite.should_receive(:push)

			# 6 is 4+50%, where 4 is the period of sending queued tasks
			em_for(6) do; mk_queue do |q|
				q.announce('stub_node'=>{'dscv'=>1,'ldv'=>1,'rcv'=>1})
				q.queue(stub_task)
			end; end
		end

		it "should send one task when several are queued" do
			mk_task = proc do |i|
				{'type'=>'dscv','args'=>'b','workdir'=>'c','key'=>"#{i}",'env'=>[]}
			end
			Nanite.stub(:push) do |str,task,opts|
				str.should == '/ldvnode/dscv'
				task.should == symbolize(mk_task.call(task[:key].to_i))
				opts.should contain_subhash :target => 'stub_node' 
			end
			Nanite.should_receive(:push)

			# 6 is 4+50%, where 4 is the period of sending queued tasks
			em_for(6) do; mk_queue do |q|
				q.announce('stub_node'=>{'dscv'=>1,'ldv'=>1,'rcv'=>1})
				(1..10).each {|n| q.queue(mk_task.call(n))}
			end; end
		end

		it "should redo task on the relevant request" do
			# Subject to race condition fails!
			mk_task = proc do |i|
				{'type'=>'dscv','args'=>'b','workdir'=>'c','key'=>"#{i}",'env'=>[]}
			end
			Nanite.stub(:push) do |str,task,opts|
				str.should == '/ldvnode/dscv'
				# We should push 1st task two times: we redo
				task.should == symbolize(mk_task.call(1))
				opts.should contain_subhash :target => 'stub_node' 
			end
			Nanite.should_receive(:push).exactly(2).times

			# 10 is 8+2sec%, where 8 is two periods of sending queued tasks
			em_for(10) do; mk_queue do |q|
				q.announce('stub_node'=>{'dscv'=>1,'ldv'=>1,'rcv'=>1})
				(1..10).each {|n| q.queue(mk_task.call(n))}
				# We can't just Kernel.sleep here, since this test and the SUT run in the same eventmachine instance
				EM.add_timer(5) do 
					q.announce('stub_node'=>{'dscv'=>1,'ldv'=>1,'rcv'=>1})
					q.redo(mk_task.call(1))
				end
			end; end
		end

		it "should remove tasks of node when removing a node, and requeue them subsequently" do
			# Subject to race condition fails!
			mk_task = proc do |i|
				{'type'=>'dscv','args'=>'b','workdir'=>'c','key'=>"#{i}",'env'=>[]}
			end
			was = false
			Nanite.stub(:push) do |str,task,opts|
				str.should == '/ldvnode/dscv'
				# We should push 1st task two times: we redo
				task.should == symbolize(mk_task.call(1))
				if was
					opts.should contain_subhash :target => 'new_node' 
				else
					was = true
					opts.should contain_subhash :target => 'stub_node' 
				end
			end
			Nanite.should_receive(:push).exactly(2).times

			# 10 is 8+2sec%, where 8 is two periods of sending queued tasks
			em_for(10) do; mk_queue do |q|
				q.announce('stub_node'=>{'dscv'=>1,'ldv'=>1,'rcv'=>1})
				(1..10).each {|n| q.queue(mk_task.call(n))}
				# We can't just Kernel.sleep here, since this test and the SUT run in the same eventmachine instance
				EM.add_timer(5) do 
					q.announce('new_node'=>{'dscv'=>1,'ldv'=>1,'rcv'=>1})
				end
			end; end
		end

		it "should send one task when several are queued with several nodes" do
			mk_task = proc do |i|
				{'type'=>'dscv','args'=>'b','workdir'=>'c','key'=>"#{i}",'env'=>[]}
			end
			nodes_employed = {}
			Nanite.stub(:push) do |str,task,opts|
				str.should == '/ldvnode/dscv'
				task.should == symbolize(mk_task.call(task[:key].to_i))
				opts[:target].should_not be_nil
				nodes_employed[opts[:target]].should be_nil
				nodes_employed[opts[:target]] = true
				puts nodes_employed.inspect
			end
			Nanite.should_receive(:push).exactly(2).times

			# 10 is 8+2, where 8 is two periods of sending queued tasks
			em_for(10) do; mk_queue do |q|
				q.announce('node_1'=>{'dscv'=>1,'ldv'=>1,'rcv'=>1},'node_2'=>{'dscv'=>1,'ldv'=>1,'rcv'=>1})
				(1..10).each {|n| q.queue(mk_task.call(n))}
			end; end
		end

	end
end

require 'sender.rb'

require 'json'

describe "Sender" do
	it_should_behave_like "a nanite agent" do
		let(:factory) { lambda { |arg| NaniteSender.new arg } }
	end

	context "with correct AMQP credentials" do
		def mk_sender(opts = {},&blk)
			sender = NaniteSender.new(OPTS.merge({:host => 'localhost', :vhost => '/rspecldvc', :user => 'ldv', :pass => '12345'}).merge opts)
			blk.call(sender) if blk
		end

		it "should queue a sample packet", :lack_of_rspec_knowledge => true  do
			task = {'type'=>'dscv','args'=>'b','workdir'=>'c','key'=>"sample.key",'env'=>[]}
      amq = mock("AMQueue", :queue => mock("queue", :subscribe => {}, :publish => {}), :fanout => mock("fanout", :publish => nil))
      MQ.stub!(:new).and_return(amq)
			amq.fanout.stub(:publish) do |_content|
				_content.should_not be_nil
				packet = JSON.load _content
				# Pushed will be the object of nanite::push
				if packet.class == Nanite::Push
					packet.payload.should == task
					packet.type.should == '/sample/target'
				end
			end
			em_for(10) do; mk_sender do |s|
				s.send('/sample/target',task)
			end; end
		end

		it "should not choke if many senders are launched" do
			mk_task = proc do |i|
				task = {'type'=>'dscv','args'=>'b','workdir'=>'c','key'=>"#{i}",'env'=>[]}
			end
			packets_sent = {}
      amq = mock("AMQueue", :queue => mock("queue", :subscribe => {}, :publish => {}), :fanout => mock("fanout", :publish => nil))
      MQ.stub!(:new).and_return(amq)
			amq.fanout.stub(:publish) do |_content|
				_content.should_not be_nil
				packet = JSON.load _content
				# Pushed will be the object of nanite::push
				if packet.class == Nanite::Push
					packet.payload.should_not be_nil
					packet.payload['key'].should_not be_nil
					key = packet.payload['key'].to_i

					# Conversion to int should not fail
					key.should_not == 0
					packets_sent[key].should be_nil
					packets_sent[key] = true

					packet.payload.should == mk_task[key]
					packet.type.should == '/sample/target'
				end
			end
			expect do 
			em_for(10) do; 
				(1..10).each do |i|
					mk_sender do |s|
						s.send('/sample/target',mk_task[i])
					end
				end
			end
			end.to change{packets_sent.keys.length}.from(0).to(10)
		end
	end
end

# Tests for waiter
require 'waiter.rb'
require 'json'

describe "Waiter",:focus=>true do
	it_should_behave_like "a nanite agent" do
		let(:factory) { lambda { |arg| start_queue arg } }
	end
	context "with correct AMQP credentials" do
		WAITER_OPTS = {:host => 'localhost', :vhost => '/rspecldvc', :user => 'ldv', :pass => '12345'}
		def mk_waiter(opts = {},&blk)
			waiter = Waiter.new(OPTS.merge(WAITER_OPTS).merge opts)
			blk.call(waiter) if blk
		end

		it "should initialize correctly" do
			em_for(2) do
				mk_waiter
			end
		end

		it "should send job to AMQP on job_done call" do
			got_packet = false
			expect do em_for(12) do
				sample_task = {'task'=>'sample.key', 'status' => 'finished'}
				mk_waiter do |w|
					# Subscribe to exchange
					mmm = w.mq
					exchange = mmm.topic('ldv-wait-for-results', :durable => true)
					mmm.queue('sample_wait_que1', :auto_delete => true).bind(exchange, :key => '#').subscribe do |head,body|
						packet = JSON.load body
						packet.should == sample_task
						got_packet = true
					end
					# Call the funciton under test
					w.job_done('sample.key',sample_task)
				end
			end; end.to change {got_packet}.from(false).to(true)
		end

		it "should delay job on job_done call if no consumer is attached" do
			got_packet = false
			expect do em_for(14) do
				sample_task = {'task'=>'sample.key', 'status' => 'finished'}
				mk_waiter do |w|
					# Subscribe to exchange
					EM.add_timer(7) do
						mmm = w.mq
						exchange = mmm.topic('ldv-wait-for-results', :durable => true)
						mmm.queue('sample_wait_que1', :auto_delete => true).bind(exchange, :key => '#').subscribe do |head,body|
							packet = JSON.load body
							packet.should == sample_task
							got_packet = true
						end
					end
					# Call the funciton under test
					w.job_done('sample.key',sample_task)
				end
			end; end.to change {got_packet}.from(false).to(true)
		end

		it "should properly wait for a packet with concrete key" do
			em_for(14) do
				sample_task = {'task'=>'concrete.key', 'status' => 'finished'}
				mk_waiter do |w|
					# Subscribe to exchange
					EM.add_timer(11) do
						mmm = w.mq
						exchange = mmm.topic('ldv-wait-for-results', :durable => true)
						exchange.publish(JSON.dump(sample_task), :routing_key => 'concrete.key')
					end
					# Set up a trigger that changes before the above AMQP sending fires.  Then check that wait returns after the trigger changes.
					too_early = true
					EM.add_timer(10) do
						too_early = false
					end
					# Set up a hook to stdout, and check if we dumped the key correctly
					$stdout.stub(:puts) do |key_str|
						# FIXME: first two fields should be filled with information transfer data
						key_str.should == ',,concrete,key'
						too_early.should be_false
					end
					# Check if we did a flush
					$stdout.should_receive :flush
					# Launch function under test
					w.wait_for('concrete.key')
				end
			end
		end

		it "should not wait if no packet with a proper key is sent" do
			em_for(10) do
				sample_task = {'task'=>'wtf', 'status' => 'finished'}
				mk_waiter do |w|
					# Subscribe to exchange
					EM.add_timer(5) do
						mmm = w.mq
						exchange = mmm.topic('ldv-wait-for-results', :durable => true)
						exchange.publish(JSON.dump(sample_task), :routing_key => 'concrete.key.is.bad')
					end
					$stdout.should_not_receive(:puts)
					# Launch function under test (should not wait)
					w.wait_for('concrete.key')
				end
			end
		end

		it "should properly wait for a packet with a sharp-ending key" do
			em_for(14) do
				key = 'dscv.task.15'
				sample_task = {'task'=>key, 'status' => 'finished'}
				mk_waiter do |w|
					# Subscribe to exchange
					EM.add_timer(7) do
						mmm = w.mq
						exchange = mmm.topic('ldv-wait-for-results', :durable => true)
						exchange.publish(JSON.dump(sample_task), :routing_key => key)
					end
					# Set up a trigger that changes before the above AMQP sending fires.  Then check that wait returns after the trigger changes.
					too_early = true
					EM.add_timer(6) do
						too_early = false
					end
					# Set up a hook to stdout, and check if we dumped the key correctly
					$stdout.stub(:puts) do |key_str|
						# FIXME: first two fields should be filled with information transfer data
						key_str.should == ',,dscv,task,15'
						too_early.should be_false
					end
					# Check if we did a flush
					$stdout.should_receive :flush
					# Launch function under test
					w.wait_for('dscv.#')
				end
			end
		end

		it "should not wait for a non-matching packet with a sharp-ending key" do
			em_for(14) do
				key = 'dscv.task.15.rcv.22'
				sample_task = {'task'=>key, 'status' => 'finished'}
				mk_waiter do |w|
					# Subscribe to exchange
					EM.add_timer(7) do
						mmm = w.mq
						exchange = mmm.topic('ldv-wait-for-results', :durable => true)
						exchange.publish(JSON.dump(sample_task), :routing_key => key)
					end
					# Launch function under test
					$stdout.should_not_receive(:puts)
					# Launch function under test (should not wait)
					w.wait_for('dscv.task.16.#')
				end
			end
		end

		it "should properly wait for a packet with a asterisk-ending key" do
			em_for(14) do
				key = 'asterisk.task.with.100'
				sample_task = {'task'=>key, 'status' => 'finished'}
				mk_waiter do |w|
					# Subscribe to exchange
					EM.add_timer(7) do
						mmm = w.mq
						exchange = mmm.topic('ldv-wait-for-results', :durable => true)
						exchange.publish(JSON.dump(sample_task), :routing_key => key)
					end
					# Set up a trigger that changes before the above AMQP sending fires.  Then check that wait returns after the trigger changes.
					too_early = true
					EM.add_timer(6) do
						too_early = false
					end
					# Set up a hook to stdout, and check if we dumped the key correctly
					$stdout.stub(:puts) do |key_str|
						# FIXME: first two fields should be filled with information transfer data
						key_str.should == ',,asterisk,task,with,100'
						too_early.should be_false
					end
					# Check if we did a flush
					$stdout.should_receive :flush
					# Launch function under test
					w.wait_for('asterisk.task.with.*')
				end
			end
		end

		it "should not wait for a non-matching packet with a asterisk-ending key" do
			em_for(14) do
				key = 'asterisk.task.with'
				sample_task = {'task'=>key, 'status' => 'finished'}
				mk_waiter do |w|
					# Subscribe to exchange
					EM.add_timer(7) do
						mmm = w.mq
						exchange = mmm.topic('ldv-wait-for-results', :durable => true)
						exchange.publish(JSON.dump(sample_task), :routing_key => key)
					end
					# Launch function under test
					$stdout.should_not_receive(:puts)
					# Launch function under test (should not wait)
					w.wait_for('asterisk.task.with.*')
				end
			end
		end
	end
end

