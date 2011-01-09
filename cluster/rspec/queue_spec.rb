# RSpec for LDV cluster queue

require 'queue.rb'

RSpec.configure do |c|
	#c.filter_run :focus => true
	# Exclude tests which are known to fail due to a badly implmented AMQP binding
	c.filter_run_excluding :amqp_binding_sucks => true
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

OPTS = {:log_level => :warn}

describe "Queue" do
	context "with unreachable host" do
		it "should tell that" do
			expect { em_for(2) {start_queue(OPTS.merge :host => 'some.unknown.host')}}.to raise_error(EventMachine::ConnectionError)
		end
	end
	context "with unreachable virtual host", :amqp_binding_sucks => true do
		it "should tell that" do
			expect { em_for(2) {start_queue(OPTS.merge :host => 'localhost', :vhost=>vhost_bad)}}.to raise_error
		end
	end
	context "with wrong password" do
		it "should throw on srartup", :amqp_binding_sucks => true do
			expect { em_for(2) {start_queue(OPTS.merge :host => 'localhost', :user=>'ldv', :password => 'qweiojwqejiorewjoiew', :log_level => :debug)}}.to raise_error
		end
	end
	context "with correct AMQP credentials" do
		def mk_queue(opts = {},&blk)
			start_queue(OPTS.merge({:host => 'localhost', :vhost => '/rspecldvc', :user => 'ldv', :password => '12345'}).merge opts ) {|a| blk.call(a) if blk}
		end

		it "should not throw on srartup" do
			expect { em_for(1) {mk_queue}}.to_not raise_error
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

		it "should send one task when several are queued", :focus => true do
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

	end
end


