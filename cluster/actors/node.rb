require 'tempfile'
require 'fileutils'

$:.unshift File.dirname(__FILE__)
require 'utils.rb'

def say_and_run(*args)
	$stderr.write "Running: #{args.inspect}\n"
	Kernel.system *args
end

require 'open3'
def say_and_open3(*args)
	$stderr.write "Running: #{args.inspect}\n"
	Open3.popen3(*args) do |a,b,c|
		yield a,b,c
	end
end

class RealSpawner
	def initialize(ldv_home)
		@home = ldv_home
	end

	def spawn_child(job_type,task,spawn_key)
		# Set up environment variables for child processes
		task['env'].each { |var,val| ENV[var] = val.to_s }
		task['env'].each { |var,val| puts "Env: #{var} = '#{val.to_s}'" }

		# Workdir
		workdir = task['workdir']

		# Run job-specific targets
		# NOTE that we don't need any asynchronous forking.  Here we can just synchronously call local processes, and wait for them to finish, because Nanite node can perform several jobs at once
		# However, we should watch TODO that eventmachine doesn't prevent from working in parallel!
		case job_type
			when :ldv then
				puts "LDV"
				# ldv-manager gets all it needs from environment.  However, we should create a directory for it, and work inside it.
				puts "Creating #{workdir}"
				Dir.chdir(FileUtils.mkdir_p(workdir)) do
					# FIXME: replace with execve equivalent: possible race condition here
					ENV['LDV_SPAWN_KEY'] = spawn_key
					unless say_and_run('ldv-manager')
						$stderr.puts "Failed to run ldv-manager..."
					end
				end
			when :dscv then
				puts "DSCV"
				# Dump taskfile to a temp file
				tmpdir = File.join(workdir,'tmp')
				FileUtils.mkdir_p tmpdir
				Tempfile.open("ldv-cluster-task-#{task['key']}",tmpdir) do |temp_file|
					temp_file.write task['args']
					temp_file.close
					puts "Saved task to temporary file #{temp_file.path}"
					puts task['args']

					# FIXME: replace ENV assignments with execve equivalent: possible race condition here
					ENV['WORK_DIR'] = workdir
					# FIXME: this may actually differ, if user sets it up differently.
					ENV['LDV_RULE_DB'] = File.join(@home,'kernel-rules','model-db.xml')
					ENV['LDV_SPAWN_KEY'] = spawn_key
					say_and_run('dscv',"--rawcmdfile=#{temp_file.path}")
				end
			when :rcv then
				puts "DSCV"
				# Dump taskfile to a temp file
				tmpdir = File.join(workdir,'tmp')
				FileUtils.mkdir_p tmpdir
				Tempfile.open("ldv-cluster-task-#{task['key']}",tmpdir) do |temp_file|
					temp_file.write task['args']
					temp_file.close
					puts "Saved task to temporary file #{temp_file.path}"
					puts task['args']

					# FIXME: replace ENV assignments with execve equivalent: possible race condition here
					ENV['DSCV_HOME'] = @home
					ENV['WORK_DIR'] = workdir
					ENV['LDV_SPAWN_KEY'] = spawn_key
					say_and_run(File.join(@home,'dscv','rcv','blast'),"--rawcmdfile=#{temp_file.path}")
				end
		end
	end
end

class Player
	def initialize(ldv_home,fname)
		@home = ldv_home
		@scenarios = {}
		File.new(fname).each do |line|
			if md = /([^:]*): (.*)/.match(line)
				key,args_str = md[1],md[2]
				args = args_str.split(" ")
				@scenarios[key] ||= []
				@scenarios[key] << args
			end
		end
		@watcher = File.join(@home,'watcher','ldv-watcher')

		@env_mutex=Mutex.new
	end

	def env_say_and_run(env,*args)
		#@env_mutex.synchronize do
			env.each {|k,v| ENV[k]=v }
			say_and_run(*args)
		#end
	end

	def env_say_and_open3(env,*args,&block)
		#@env_mutex.synchronize do
			env.each {|k,v| ENV[k]=v }
			say_and_open3(*args,&block)
		#end
	end

	def spawn_child(job_type,task,spawn_key)
		#call_env = { 'LDV_SPAWN_KEY' => spawn_key }
		call_env = { 'LDV_SPAWN_KEY' => spawn_key, 'LDV_NOREAD_TASKS' => 'aaa' }
		scenario = @scenarios[spawn_key]
		raise "Scenario for key \"#{spawn_key}\" is not found" unless scenario
		$stderr.puts "KEY #{spawn_key.inspect} going to execute preset scenario: #{scenario.inspect}"

		wait_by_args = {}

		scenario.each do |args|
			# Our sleep will block this Eventmachine thread, but that's what the usual workflow does too
			#Kernel.sleep 2
			if args[0] == 'wait'
				# Since waiters usually wait for only one packet, we assume that it's the case in our scenarios, and terminate waiter if a line is read
				wait_by_args[args] ||= 0
				wait_by_args[args] += 1
			else
				env_say_and_run(call_env,@watcher,*args)
			end
		end
		# Do our postponed waits
		puts "POSTPONED WAITING for #{wait_by_args.inspect}!"
		wait_by_args.each do |args, lines|
			to_read = lines
			while to_read > 0
				env_say_and_open3(call_env,@watcher,*args) do |cin, cout, cerr|
					while to_read > 0
						puts "FAKE WAITING for #{args.inspect}, #{to_read} more to go (test failed on hangup)"
						r = select([cout,cerr],nil,nil,1)
						begin
							$stderr.puts cerr.read_nonblock 10000
						rescue EOFError
							nil
						end
						if line = cout.readline
							to_read -= 1
							puts "FAKE WAIT RETURNS #{line.inspect}, #{to_read} left"
						end
					end
					cin.close
					cout.close
					cerr.close
				end
				Kernel.sleep 1
			end
			$stderr.puts "FAKE WAITING for #{args.inspect} FINISHED!"
		end
	end
end

class Ldvnode
	include Nanite::Actor
	expose :hello, :dscv, :ldv, :rcv

	attr_accessor :status
	# Normally, actors don't know ping time of an agent, but here we use it in result sending mechanism
	attr_accessor :ping_time

	# Function to spawn child.  Substitute with scenario player if you want to run integration tests
	attr_accessor :spawner

	Task_availability_default = { :ldv => 1, :dscv => 1, :rcv => 1 }

	def initialize
		puts "Setting status..."
		@status = Task_availability_default.dup
		@status_update_mutex = Mutex.new
		puts "Setting status to #{@status} for #{self}"
		@home = ENV['LDV_HOME'] || File.join(File.dirname(__FILE__),"..","..")

		if fname = ENV['LDV_PLAY']
			@spawner = Player.new(@home,fname)
		else
			# run regression tests
			@spawner = RealSpawner.new(@home)
		end
	end

	def hello(world)
		puts "Hello, #{world.inspect}"
	end

	def rcv(task)
		launch_child_job(:rcv,task)
	end

	def dscv(task)
		launch_child_job(:dscv,task)
	end

	def ldv(task)
		launch_child_job(:ldv,task)
	end

	protected

	def launch_child_job(job_type,task)
		puts "Job #{job_type} accepted: #{task.inspect}."
		# Whether we descided to send job back (local for closures created below)
		send_job_back = false

		child_op = proc do
			# Update local status
			@status_update_mutex.synchronize do
				if @status[job_type] > 0
					@status[job_type] -= 1
				else
					send_job_back = true
				end
			end
			unless send_job_back
				spawner.spawn_child job_type,task,task['key']
			end
		end

		callback_op = proc do
			if send_job_back
				# If the job's to be sent back, don't touch statuses, just send
				puts "A #{job_type} job rejected, sending back: #{task.inspect}"
				Nanite.push("/ldvqueue/redo", task)
			else
				puts "The #{job_type} job completed, result should have been sent: #{task.inspect}"
				@status_update_mutex.synchronize do
					@status[job_type] += 1
				end
			end
		end

		EM.defer child_op, callback_op

		puts "The #{job_type} will run in the background, and will send results!"
	end

	Child_jobs = { :ldv => {:cmd=>'ldv-manager'},
		:dscv => {:cmd => 'dscv', :taskfile=>true},
		:rcv => {:cmd => 'dscv', :taskfile=>true},
	}

end

