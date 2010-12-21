require 'tempfile'
require 'fileutils'

def say_and_run(*args)
	$stderr.write "Running: #{args.inspect}\n"
	Kernel.system *args
end

class Ldvnode
	include Nanite::Actor
	expose :hello, :dscv, :ldv, :rcv

	attr_accessor :status
	# Normally, actors don't know ping time of an agent, but here we use it in result sending mechanism
	attr_accessor :ping_time

	Task_availability_default = { :ldv => 1, :dscv => 1, :rcv => 1 }

	def initialize
		puts "Setting status..."
		@status = Task_availability_default.dup
		@status_update_mutex = Mutex.new
		puts "Setting status to #{@status} for #{self}"
		@home = ENV['LDV_HOME'] || File.join(File.dirname(__FILE__),"..","..")
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
				# Set key (which is transferred via an environment variable)
				ENV['LDV_SPAWN_KEY'] = task['key']
				spawn_child(job_type,task)
			end
		end

		callback_op = proc do
			if send_job_back
				# If the job's to be sent back, don't touch statuses, just send
				puts "A #{job_type} job rejected, sending back: #{task.inspect}"
				Nanite.push("/ldvqueue/redo", task)
			else
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
	def spawn_child(job_type,task)
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

					ENV['WORK_DIR'] = workdir
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

					ENV['DSCV_HOME'] = @home
					ENV['WORK_DIR'] = workdir
					say_and_run(File.join(@home,'dscv','rcv','blast'),"--rawcmdfile=#{temp_file.path}")
				end
		end
	end

end

