require 'tempfile'
require 'fileutils'

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
		# Update local status
		@status_update_mutex.synchronize do
			if @status[job_type] > 0
				@status[job_type] -= 1
			else
				# Send task back to queuer, and exit from the outer method
				puts "A #{job_type} job rejected, sending back: #{task.inspect}"
				Nanite.push("/ldvqueue/redo", task)
				return
			end
		end
		puts "Job #{job_type} accepted: #{task.inspect}"
		begin
			# Set key (which is transferred via an environment variable)
			ENV['LDV_SPAWN_KEY'] = task['key']

			spawn_child(job_type,task)
		ensure
			puts "Backing status"
			@status_update_mutex.synchronize do
				@status[job_type] += 1
			end
		end
		puts "The #{job_type} job done"
		# We sleep for some time, greater than ping time.  Server will update status if we use ldv_selector, however, that status should already be delievered.  Status is sent by ping, so we must be sure that ping succeeded before we send the actual result.
		EM.add_timer(ping_time.call + 2) do
			Nanite.push("/ldvqueue/result", task, :selector => :ldv_selector)
		end
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
					unless Kernel.system('ldv-manager')
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
					Kernel.system('dscv',"--rawcmdfile=#{temp_file.path}")
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

					ENV['WORK_DIR'] = workdir
					Kernel.system(File.join(@home,'dscv','rcv','blast'),"--rawcmdfile=#{temp_file.path}")
				end
		end
	end

end

