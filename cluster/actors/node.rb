require 'tempfile'
require 'fileutils'
require 'rubygems'
require 'nanite'

$:.unshift File.dirname(__FILE__)
require 'utils.rb'
require 'packer.rb'

class Spawner
	LOCAL_MOUNTS = File.join("mnt","local")
	SSH_MOUNTS = File.join("mnt","ssh")

	def initialize()
		# Determine the name of unionfs (in Ubuntu and SuSE it differs)
		if say_and_run('unionfs','--help',:no_capture_stdout => true, :no_capture_stderr => true) == 0
			@unionfs='unionfs'
		elsif say_and_run('unionfs-fuse','--help',:no_capture_stdout => true, :no_capture_stderr => true) == 0
			@unionfs='unionfs-fuse'
		else
			raise "Can't find a proper unionfs command..."
		end

		# Mutex to prevent race condition during mounting.
		# If several processes attempt to check and then mount at once, their checks may succeed, and the mounting may fail (already mounted).  However, that won't affect node much, since the failed tasks will be requeued and processed well.
		@mount_mutex = Mutex.new
	end

	# Check if +directory+ is already a mountpoint
	def self.mounted dir
		Logging.logger['Node'].trace "Check if #{dir} is mounted..."
		r = say_and_run("mountpoint",dir)
		raise "Your system doesn't have 'mountpoint' command!  Report this to the developers!" if r.nil?
		Logging.logger['Node'].debug r
		r == 0
	end

	# Returns the local mountpoint of a mirror of the remote directory +dir+ on the host specified.
	# If it's not mounted, creates a mount at the +dir+
	def ensure_mount(key,user,host,dir)
		mount_target = File.expand_path File.join(SSH_MOUNTS,dir)
		FileUtils.mkdir_p mount_target
		@nlog.trace "Ensuring mount in #{mount_target}"

		@mount_mutex.synchronize do
			already_mounted = Spawner.mounted mount_target
			@nlog.debug "Already mounted? #{already_mounted}"
			on_localhost = ip_localhost? host
			@nlog.debug "Is #{host} localhost? #{on_localhost}"
			unless already_mounted or on_localhost
				FileUtils.mkdir_p(mount_target)
				# We user "read-only" to mount from SSH as our workflow doesn't allow writes this way.  Perhaps, after debugging, we'll discard this option.
				@nlog.trace "Mounting remote filesystem"

				# We prevent password authentication because we explicitely want to use keys.  If SSH is going to prompt for a password (due to a hostile or wrong task specification) we don't want a cluster node to hang and to wait if a user is going to enter password.
				ssh_args = ["sshfs","-o","idmap=user","-o","ro","-o","PasswordAuthentication=no"]
				if ENV['LDV_SSHFS_OPTS']
					ENV['LDV_SSHFS_OPTS'].split(' ').each {|opt| ssh_args << opt}
				end
				ssh_args += [ "#{user}@#{host}:#{dir}",mount_target ]
				sshed = say_and_run(*ssh_args)
				unless sshed && sshed == 0
					raise "SSHFSing failed #{ssh_args.inspect}.  Did you install SSHFS?  Is the host reachable?"
				end
			end
		end #sync
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
	def prepare_mounts(key,user,host,root,_)
		@nlog.trace "call prepare_mounts: #{[key,user,host,root,_].inspect}"
		# We do this check regardless of whether root is mounted, since there's a FIXME bug in the way we use sshfs
		sshdir = ensure_mount(key,user,host,root)

		@mount_mutex.synchronize do
			unless Spawner.mounted root or ip_localhost? host
				workdir = ensure_workdir(key,host,nil,root)

				# Create a mountpoint unless it exists
				FileUtils.mkdir_p root

				# Do the union-mount and report failure unless succeeded
				# If remote host is actually a local host, tham means that we shouldn't mount, as it won't work, and, most likely, it's planned to be like this.
				unless ip_localhost? host
					# Ubuntu's unionfs doesn't work with relative paths... expand them!
					unionfs_args = [@unionfs,"-o","cow","#{File.expand_path workdir}=RW:#{File.expand_path sshdir}=RO",root]
					unioned = say_and_run(*unionfs_args)
					unless unioned && unioned == 0
						raise "UNION failed #{unionfs_args.inspect}.  Did you install unionfs-fuse?  Are all the folders created properly?"
					end
				else
					@nlog.trace "Host #{host} is local, do not make a unionfs-mount"
				end
			end
		end #sync

		root
	end
end

class RealSpawner < Spawner
	def initialize(ldv_home)
		super()
		@home = ldv_home
		@nlog = Logging.logger['Node']
	end

	def spawn_child(job_type,task,spawn_key)
		# Tempdir for local computation; will be wiped when the task finishes.
		# Sample folder:
		# 	tmp/ldv.101/ldv.101.dscv.500/
		local_tmpdir = File.expand_path File.join('tmp',task['global']['name'],task['key'])
		FileUtils.mkdir_p local_tmpdir
		@nlog.info "LOCAL TMPDIR: #{local_tmpdir}"

		# We don't set environment variables at once, because it would alter global environment, which is not thread-safe (for forked children).  Thus, we just create a proc, and call it in all the forked kids (to collect all the common code that sets ENV in one place).
		set_common_env = proc do
			# Notify children that we are in cluster
			ENV['LDV_IN_CLUSTER'] = '1'

			ENV['LDV_SPAWN_KEY'] = spawn_key
			# LDV_WATCHER_SRV is set in wrapper script that call set_env_from_opts in options.rb

			# Set information for packer that will read it when watcher is invoked from a child process
			ENV['LDV_FILESRV'] = task['global']['filesrv']
			ENV['LDV_NAMESPACE_ROOT'] = task['global']['root']

			# Set information about where to place files
			ENV['LDV_FILES_TMPDIR'] = local_tmpdir

			# Do not perform lock-based sainty checks.  They don't work for cluster and are potentially harmful for network FS-s
			ENV['LDV_DSCV_NO_SANITY'] = 'yes'

			# Set global environemnt in the namespace
			task['global']['env'].each { |var,val| ENV[var] = val.to_s }
			task['global']['env'].each { |var,val| @nlog.debug "Set global env: #{var} = '#{val.to_s}'" }
			# Set environment specified in the task (overrides that of namespace)
			task['env'].each { |var,val| ENV[var] = val.to_s }
			task['env'].each { |var,val| @nlog.debug "Set env: #{var} = '#{val.to_s}'" }
		end

		task_root = prepare_mounts task['key'],task['global']['sshuser'],task['global']['host'],task['global']['root'],nil

		FileUtils.mkdir_p File.join(local_tmpdir,'incoming')
		@packer = Packer.new(local_tmpdir,task['global']['filesrv'])
		# We should also unpack here, as the watcher API doesn't presuppose unpacking at startup.
		@packer.download_and_unpack spawn_key,:from_parent

		# Local logger for the current task.
		# We store its name to close it afterwards, as it consumes open filehandlers, and we may run out of their limit
		local_logger = Logging.logger_for(task['key'])

		# Run job-specific targets
		# NOTE that we don't need any asynchronous forking.  Here we can just synchronously call local processes, and wait for them to finish, because Nanite node can perform several jobs at once
		# However, we should watch TODO that eventmachine doesn't prevent from working in parallel!
		begin; case job_type
		when :ldv then
			workdir = task['global']['root']
			# ldv-manager gets all it needs from environment.  However, we should create a directory for it, and work inside it.
			@nlog.trace "Creating #{workdir} for LDV"
			# We should create logger outside of chdir, since it may contain relative paths
			ldv_logger = local_logger
			# PAX with results; created by ldv-manager
			# It's important for the filename to be key-specific, as results from a previous launch may get sent
			result_pax = File.join(local_tmpdir,"result.#{task['key']}.pax")

			fork_callback = proc do
				# NOTE that we do not set WORK_DIR here, since it may affect ldv-manager.
				set_common_env.call
				# Instruct LDV-manager to copy results to the file we specified, not just store a weirdly-named file in the results dir
				ENV['LDV_COPY_RESULTS_TO'] = result_pax
				Dir.chdir workdir
			end
			unless retcode = run_and_log(ldv_logger,'ldv-manager', :fork_callback => fork_callback)
				@nlog.error "Failed to run ldv-manager for key #{task['key']}."
			end
			@nlog.info "Child LDV exit with code #{retcode}"
			# Results are copied to result_pax, send them
			@packer.send_files [task['key']], :to_parent, [result_pax], :no_package => true
			@nlog.info "LDV package with results is sent!"
		when :dscv then
			# Dump taskfile to a temp file
			#tmpdir = local_tmpdir
			#@nlog.trace "Creating #{tmpdir} for DSCV"
			FileUtils.mkdir_p task['workdir']
			Tempfile.open("ldv-cluster-task-#{task['key']}",local_tmpdir) do |temp_file|
				temp_file.write task['args']
				temp_file.close
				@nlog.debug "Saved task to temporary file #{temp_file.path}"
				@nlog.trace task['args']

				fork_callback = proc do
					set_common_env.call
					FileUtils.mkdir_p task['workdir']
					ENV['WORK_DIR'] = task['workdir']
					ENV['LDV_RULE_DB'] ||= File.join(@home,'kernel-rules','model-db.xml')
					Dir.chdir task_root
				end
				unless retcode = run_and_log(local_logger,'dscv',"--rawcmdfile=#{temp_file.path}",:fork_callback => fork_callback)
					@nlog.error "Failed to run DSCV for key #{task['key']}."
				end
				@nlog.info "Child DSCV exit with code #{retcode}"
			end
		when :rcv then
			# Dump taskfile to a temp file
			#tmpdir = File.join(workdir,'tmp')
			#@nlog.trace "Creating #{tmpdir} for RCV"
			#FileUtils.mkdir_p tmpdir
			Tempfile.open("ldv-cluster-task-#{task['key']}",local_tmpdir) do |temp_file|
				temp_file.write task['args']
				temp_file.close
				@nlog.debug "Saved task to temporary file #{temp_file.path}"
				@nlog.trace task['args']

				fork_callback = proc do
					set_common_env.call
					FileUtils.mkdir_p task['workdir']
					ENV['WORK_DIR'] = task['workdir']
					ENV['DSCV_HOME'] = @home
					Dir.chdir task_root
				end
				unless retcode = run_and_log(local_logger,File.join(@home,'dscv','rcv','blast'),"--rawcmdfile=#{temp_file.path}",:fork_callback => fork_callback)
					@nlog.error "Failed to run RCV for key #{task['key']}."
				end
				@nlog.info "Child RCV exit with code #{retcode}"
			end
		end; ensure
			# Cleanups for this node

			# Close files that aren't needed anymore (watch out for open filehandlers limit!)
			Logging.cleanup_for task['key'] if task['key']

			# Remove packages for this node (those received have already been unpacked, and those sent are already on the file server)
			FileUtils.rm_rf local_tmpdir
		end
	end
end

# The scenario player reads text file, in which each line is of format
#     key: action arguments
# If it's requested to spawn a task with the key given, it executes watcher commands from this file in the order of their appearance, making a small pause between them.
# TODO: refactor its code... but anyway, you'll not use it in production, even for testing purposes.  Debugging won't be performed on the cluster, and checking if your AMQP setting is OK works well with any output.
class Player < Spawner
	def initialize(ldv_home,fname)
		super()
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

	# Not thread-safe, but whatever
	def env_say_and_run(env,*args)
		env.each {|k,v| ENV[k]=v }
		say_and_run(*args)
	end

	# Not thread-safe, but whatever
	def env_say_and_open3(env,*args,&block)
		env.each {|k,v| ENV[k]=v }
		say_and_open3(*args,&block)
	end

	def spawn_child(job_type,task,spawn_key)
		# LDV_NOREAD_TASKS instructs watcher not to try to pack tasks for queue tasks.  It should be non-empty for the scenario player
		call_env = { 'LDV_SPAWN_KEY' => spawn_key, 'LDV_NOREAD_TASKS' => 'aaa' }
		scenario = @scenarios[spawn_key]
		raise "Scenario for key \"#{spawn_key}\" is not found" unless scenario
		$stderr.puts "KEY #{spawn_key.inspect} going to execute preset scenario: #{scenario.inspect}"

		wait_by_args = {}

		prepare_mounts task['key'],task['global']['sshuser'],task['global']['host'],task['global']['root'],task['workdir']
		$stderr.puts "MOUNTS ARE OKAY!\n--------------"

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
	Task_availability_zero    = { :ldv => 0, :dscv => 0, :rcv => 0 }

	DEFAULT_OPTS = {:availability => Task_availability_default }

	def initialize
		# Set zero availability initially.  Nonzero availability will be set in reconfigure, which is necessary to pass options to the actor, as nanite doesn't support that
		@status = Task_availability_zero.dup

		@status_update_mutex = Mutex.new

		# NOTE that we should reconfigure at once, since we should announce the initial status
		reconfigure DEFAULT_OPTS

		# Temporary set max load
		@max_load = 5
		@max_load_need_reset = true
	end

	# Reconfigures the actor with the new config
	def reconfigure(opts)
		@opts = opts.dup

		# Set up loggers
		@nlog = Logging.logger['Node']

		# set up LDV_HOME
		@home = ENV['LDV_HOME'] || File.join(File.dirname(__FILE__),"..","..")
		@nlog.debug "LDV_HOME is #{@home}"

		# Set up max load (we'll reject tasks if our load is higher)
		# NOTE: we need this tricky way because we send our first ping _before_ reconfiguration (when agent is run), and we may send very large max_load and receive too many tasks if we want our load to be less than the default 1000.  So, we reset max_load to its default value only in reconfiguration, making it initially a very careful 5.
		if opts[:max_node_load]
			@max_load = opts[:max_node_load]
		else
			@max_load = 1000 if @max_load_need_reset
			@max_load_need_reset = true
		end


		# Initialize task spawner.
		# Should be performed before availability is relinquished!
		if fname = opts[:play_scenario]
			# Scenario will be played
			@spawner = Player.new(@home,fname)
		else
			# Real tasks will be run!
			@spawner = RealSpawner.new(@home)
		end

		# Merge options from command line and environment
		availability = { :ldv => ENV['LDV_NODE_LDVS'], :dscv => ENV['LDV_NODE_DSCVS'], :rcv => ENV['LDV_NODE_RCVS'] }
		(@opts[:availability] || Task_availability_default).each do |k,v|
			availability[k]=v unless availability[k]
		end
		# Start publishing statuses
		@status_update_mutex.synchronize do
			@nlog.info "Setting status to #{availability.inspect}"
			availability.each { |task,val_s| if val_s ; @status[task] = val_s.to_i ; end }
		end

		# Set up ping timer for user display
		if opts[:ping_time]
			@show_status.cancel if @show_status
			@show_status = EM.add_periodic_timer(opts[:ping_time].to_i) { show_status }
		end
		# TODO Force status announce after reconfiguration
	end

	def show_status
		@nlog.debug "Current status: #{status_for_cluster.inspect}"
	end

	# Logger for this particular job on the node
	def wlog(key)
		Logging.logger["Node::#{key}"]
	end

	# Return status for this node for cluster controller.  Based on this, the decision where to route tasks will be made
	def status_for_cluster
		st = status
		# Append node load to the usual availability status
		st[:load] = load_average
		st[:max_load] = @max_load
		@nlog.debug "Announcing status #{st.inspect}"
		st
	end

	def load_average
		`cat /proc/loadavg`.chomp.split[0].to_f
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
		@nlog.debug "Incoming #{job_type} with key #{task['key']}"
		@nlog.trace "Task gotten: #{task.inspect}"
		# We spawn a job and asynchronously call the callback after it finishes.  The callback should read its status
		# 	:finished - the job successfully finished (or failed, and made it clear)
		# 	:exception - the job has thrown an exception in ruby code
		# 	:rejected - this node can't afford this task due to its capabilities
		job_status = :finished
		# Ruby threads used in EventMachine, just silently die if they encounter an exception.  We should at least save the backtrace
		child_backtrace = nil
		child_exception = nil

		child_op = proc do
			@nlog.trace "EventMachine spawns child!"
			# Update local status
			@status_update_mutex.synchronize do
				if load_average > @max_load
					@nlog.debug "Load too high #{load_average}, should be less than #{@max_load}, rejecting"
					job_status = :rejected
				elsif @status[job_type] > 0
					@status[job_type] -= 1
				else
					job_status = :rejected
				end
			end
			unless job_status == :rejected
				begin
					@nlog.debug "Launching #{job_type} with key #{task['key']}"
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
			@nlog.trace "EventMachine calls child back!"
			case job_status
			when :rejected
				# If the job's to be sent back, don't touch statuses, just send
				@nlog.debug "The #{job_type} job with key #{task['key']} rejected!"
				show_status
				Nanite.push("/ldvqueue/redo", task)
				@nlog.trace "A #{job_type} job with key #{task['key']} reject sent."
			when :finished
				@status_update_mutex.synchronize do
					@status[job_type] += 1
					show_status
				end
				@nlog.debug "The #{job_type} job with key #{task['key']} finished!"
			when :exception
				@status_update_mutex.synchronize do
					@status[job_type] += 1
					show_status
				end
				@nlog.error "Exception happened when processing #{task['key']}!  Job will be sent back."
				# We do not try to split and make this look beautiful, because... because it's a fucking exception! 
				@nlog.error child_backtrace
				Nanite.push("/ldvqueue/redo", task)
			else
				@nlog.warn "Job status is strange: #{job_status}"
				@status_update_mutex.synchronize do
					@status[job_type] += 1
					show_status
				end
			end
			@nlog.trace "EventMachine ends child!"
		end

		EM.defer child_op, callback_op

		@nlog.trace "Defer #{job_type} with key #{task['key']} to EventMachine's background."
	end

end

