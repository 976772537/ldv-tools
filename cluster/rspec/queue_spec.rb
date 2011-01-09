# RSpec for LDV cluster queue

require 'queue.rb'

RSpec.configure do |c|
	#c.filter_run :focus => true
	# Exclude tests which are known to fail due to a badly implmented AMQP binding
	c.filter_run_excluding :amqp_binding_sucks => true
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
Kernel.system("
#{ctl} delete_vhost #{vhost} ;
#{ctl} delete_vhost #{vhost_bad};
#{ctl} add_vhost #{vhost} ;
#{ctl} add_user ldv 12345 ;
#{ctl} set_permissions -p #{vhost} ldv '.*' '.*' '.*'
")

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

		it "should not queue a nil task" => true do
			expect { em_for(1) {mk_queue do |q|
				q.queue(nil)
			end
			}}.to raise_error
		end

		it "should not queue a nil task" => true do
			expect { em_for(1) {mk_queue do |q|
				q.queue(nil)
			end
			}}.to raise_error
		end

		it "should not queue a task with wrong type" => true do
			em_for(1) do
				mk_queue do |q|
					expect {q.queue({'type'=>'wrong','args'=>'b','workdir'=>'c','key'=>'d','env'=>[]})}.to raise_error
				end
			end
		end

		it "should queue a task with a correct type" => true do
			em_for(1) do; mk_queue do |q|
					q.queue({'type'=>'dscv','args'=>'b','workdir'=>'c','key'=>'d','env'=>[]})
			end; end
		end

	end
end


