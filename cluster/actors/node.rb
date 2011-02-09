require 'tempfile'
require 'fileutils'
require 'rubygems'
require 'nanite'

$:.unshift File.dirname(__FILE__)
require 'utils.rb'

$:.unshift File.dirname(__FILE__)
require 'utils.rb'

class Spawner
	LOCAL_MOUNTS = File.join("mnt","local")
	SSH_MOUNTS = File.join("mnt","ssh")

	# Check if +directory+ is already a mountpoint
	# FIXME: bad code!
	def self.mounted dir
		$stderr.write "Check if #{dir} is mounted..."
		r = Kernel.system("mountpoint",dir)
		raise "Your system doesn't have 'mountpoint' command!  Report this to the developers!" if r.nil?
		$stderr.puts r
		r
	end

	# Returns the local mountpoint of a mirror of the remote directory +dir+ on the host specified.
	# If it's not mounted, creates a mount at the +dir+
	def ensure_mount(key,user,host,dir)
		mount_target = File.expand_path File.join(SSH_MOUNTS,dir)
		$stderr.puts "abspath is #{mount_target}"
		unless Spawner.mounted mount_target or ip_localhost? host
			FileUtils.mkdir_p(mount_target)
			# We user "read-only" to mount from SSH as our workflow doesn't allow writes this way.  Perhaps, after debugging, we'll discard this option.
			sshed = say_and_run("sshfs","-o","ro","#{user}@#{host}:#{dir}",mount_target)
			unless sshed
				raise "SSHFSing failed.  Did you install SSHFS?  Is the host reachable?"
			end
		end
		mount_target
	end

	def ensure_workdir(key,host,_,root)
		# get workdir relevant to root
		# We mount all workdirs of the same root into one (because we can't change union-mount on-line)
		workdir_target = File.join(LOCAL_MOUNTS,root)

		unless ip_localhost?(host)
			# Cleanup and re-create local workdir.  Note that workdir mountpoint remains intact.
			FileUtils.mkdir_p(workdir_target)
		end

		workdir_target
	end

	# Prepares mounts and returns the mountpoint.  Previously it accepted a block and yielded it in the changed dir, but chdir is a global setting, not a local one...
	def prepare_mounts(key,user,host,root,workdir)
		# We do this check regardless of whether root is mounted, since there's a FIXME bug in the way we use sshfs
		sshdir = ensure_mount(key,user,host,root)

		unless Spawner.mounted root or ip_localhost? host
			workdir = ensure_workdir(key,host,workdir,root)
			# --Try to umount previously created dir, if mounted.  If the command fails, that's OK
			# Do not umount! The union is shared across several tasks
			#say_and_run("fusermount","-u",root)

			# Create a mountpoint unless it exists
			FileUtils.mkdir_p root

			# Do the union-mount and report failure unless succeeded
			# If remote host is actually a local host, tham means that we shouldn't mount, as it won't work, and, most likely, it's planned to be like this.
			unless ip_localhost? host
				unioned = say_and_run("unionfs","-o","cow","#{workdir}=RW:#{sshdir}=RO",root)
				unless unioned
					raise "UNION failed.  Did you install unionfs-fuse?  Are all the folders created properly?"
				end
			end
		end

		root
	end
end

class RealSpawner < Spawner
	def initialize(ldv_home)
		@home = ldv_home
	end

	def spawn_child(job_type,task,spawn_key)
		# Set up environment variables for child processes
		task['env'].each { |var,val| ENV[var] = val.to_s }
		task['env'].each { |var,val| puts "Env: #{var} = '#{val.to_s}'" }

		# Workdir
		workdir = task['workdir']

		task_root = prepare_mounts task['key'],task['parent_machine']['sshuser'],task['parent_machine']['host'],task['parent_machine']['root'],task['workdir']

		# Run job-specific targets
		# NOTE that we don't need any asynchronous forking.  Here we can just synchronously call local processes, and wait for them to finish, because Nanite node can perform several jobs at once
		# However, we should watch TODO that eventmachine doesn't prevent from working in parallel!
		case job_type
		when :ldv then
			puts "LDV"
			# ldv-manager gets all it needs from environment.  However, we should create a directory for it, and work inside it.
			puts "Creating #{workdir}"
			Dir.chdir(FileUtils.mkdir_p(workdir)) do
				child = fork do
					ENV['LDV_SPAWN_KEY'] = spawn_key
					unless say_and_exec('ldv-manager')
						$stderr.puts "Failed to run ldv-manager..."
					end
				end
				Process.wait child
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

				child = fork do
					ENV['WORK_DIR'] = workdir
					# FIXME: this may actually differ, if user sets it up differently.
					ENV['LDV_RULE_DB'] = File.join(@home,'kernel-rules','model-db.xml')
					ENV['LDV_SPAWN_KEY'] = spawn_key
					Dir.chdir task_root do
						say_and_exec('dscv',"--rawcmdfile=#{temp_file.path}")
					end
				end
				Process.wait child
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

				child = fork do
					ENV['DSCV_HOME'] = @home
					ENV['WORK_DIR'] = workdir
					ENV['LDV_SPAWN_KEY'] = spawn_key
					Dir.chdir task_root do
						say_and_exec(File.join(@home,'dscv','rcv','blast'),"--rawcmdfile=#{temp_file.path}")
					end
				end
				Process.wait child
			end
		end
	end
end

class Player < Spawner
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
		# LDV_NOREAD_TASKS instructs watcher not to try to pack tasks for queue tasks.  It should be non-empty for the scenario player
		call_env = { 'LDV_SPAWN_KEY' => spawn_key, 'LDV_NOREAD_TASKS' => 'aaa' }
		scenario = @scenarios[spawn_key]
		raise "Scenario for key \"#{spawn_key}\" is not found" unless scenario
		$stderr.puts "KEY #{spawn_key.inspect} going to execute preset scenario: #{scenario.inspect}"

		wait_by_args = {}

		prepare_mounts task['key'],task['parent_machine']['sshuser'],task['parent_machine']['host'],task['parent_machine']['root'],task['workdir']  do
			$stderr.puts "MOUNTS ARE OKAY!\n--------------"
		end
		$stderr.puts "END MOUNT"

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
			attempts = 1
			tl = 10
			while to_read > 0
				env_say_and_open3(call_env,@watcher,*args) do |cin, cout, cerr|
					while to_read > 0
						puts "FAKE WAITING for #{args.inspect}, #{to_read} more to go (test failed on hangup)"
						r = select([cout,cerr],nil,nil,tl)
						# nanosleep to let it flush output
						Kernel.sleep(0.1)
							# Try again if select has timed out
							unless r
								if attempts % 3
									$stderr.puts "I've been waiting for #{args.inspect} for #{attempts*tl} seconds.  Is it ok?"
									attempts += 1
								end
								next
							end
						if r[0].include? cerr
							begin
								$stderr.puts cerr.read_nonblock 10000
							rescue EOFError
								nil
							end
						end
						if r[0].include? cout
							begin
								if line = cout.readline
									to_read -= 1
									puts "FAKE WAIT RETURNS #{line.inspect}, #{to_read} left"
								end
							rescue EOFError
								raise "Unexpected termination"
							end
						end
					end
					puts "FAKE WAIT TERM #{args.inspect}"
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
	Task_availability_initial = { :ldv => ENV['LDV_NODE_LDVS'], :dscv => ENV['LDV_NODE_DSCVS'], :rcv => ENV['LDV_NODE_RCVS'] }

	def initialize
		puts "Setting status..."
		@status = Task_availability_default.dup
		# Merge statuses for environment
		Task_availability_initial.each { |task,val_s| if val_s ; @status[task] = val_s.to_i ; end }

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
		# We spawn a job and asynchronously call the callback after it finishes.  The callback should read its status
		# 	:finished - the job successfully finished (or failed, and made it clear)
		# 	:exception - the job has thrown an exception in ruby code
		# 	:rejected - this node can't afford this task due to its capabilities
		job_status = :finished
		# Ruby threads used in EventMachine, just silently die if they encounter an exception.  We should at least save the backtrace
		child_backtrace = nil
		child_exception = nil

		child_op = proc do
			# Update local status
			@status_update_mutex.synchronize do
				if @status[job_type] > 0
					@status[job_type] -= 1
				else
					job_status = :rejected
				end
			end
			unless job_status == :rejected
				begin
					spawner.spawn_child job_type,task,task['key']
					job_status = :finished
				rescue => e
					child_exception = e
					job_status = :exception
					child_backtrace = "#{e.message}\n#{e.backtrace.join("\n")}\n"
				end
			end
		end

		callback_op = proc do
			case job_status
			when :rejected
				# If the job's to be sent back, don't touch statuses, just send
				puts "A #{job_type} job rejected, sending back: #{task.inspect}"
				Nanite.push("/ldvqueue/redo", task)
			when :finished
				puts "The #{job_type} job completed, result should have been sent: #{task.inspect}"
				@status_update_mutex.synchronize do
					@status[job_type] += 1
				end
			when :exception
				$stderr.puts "Exception happened when processing #{task['key']}!  Job will be sent back."
				$stderr.puts child_backtrace
				Nanite.push("/ldvqueue/redo", task)
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

