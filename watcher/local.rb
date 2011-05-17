# Local version of watcher.
# Stores data in a folder, queries it

require 'SysVIPC'
include SysVIPC


# A class to easily manage nested directories
class DirMaker
	attr_reader :current
	def initialize(root)
		@root = root
		@current = root
	end
	def push(*subdirs)
		subdirs.map! &:to_s
		prev = @current
		@current = File.join(@current,subdirs)
		begin
			yield
		ensure
			@current = prev
		end
	end
	def ensure(*subdirs)
		FileUtils.mkdir_p(File.join(@current,subdirs))
	end
	def join(*sub)
		sub.flatten!
		sub.map! &:to_s
		File.join(@current,sub)
	end
end

def keyfilestrip(from,what)
	from.sub(what,'').sub(/^\/*/,'').split(File::SEPARATOR)
end

def file_depth(fname)
	fname.count(File::SEPARATOR)
end

# A pool to allow atomic operations with integers, based on flocks
class FlockPool
	def initialize(fname)
		FileUtils.mkdir_p(File.dirname(fname))
		@lock_fname = fname
		$log.trace "Checking if exists #{@lock_fname}..."
		unless File.exists? @lock_fname
			$log.debug "Creating new pool at #{@lock_fname}"
			FileUtils.touch @lock_fname
			lock_and do |f|
				f.seek(0,IO::SEEK_SET)
				f.truncate(0)
				f.write("0\n")
			end
		end
	end
	# Safely increase key value and return it
	public; def get
		key = nil
		lock_and do |f|
			key = f.gets.to_i + 1
			f.seek(0,IO::SEEK_SET)
			f.truncate(0)
			f.write("#{key}\n")
		end
		key
	end
	# Safely decrease pool pointer value and return it
	public; def decrease_and_read
		key = nil
		lock_and do |f|
			key = f.gets.to_i - 1
			f.seek(0,IO::SEEK_SET)
			f.truncate(0)
			f.write("#{key}\n")
		end
		key
	end
	private; def lock_and
		begin
			f = File.new(@lock_fname,"r+")
			f.flock(File::LOCK_EX)
			yield(f)
		ensure
			f.close unless f.nil?
		end
	end
end

# Main class
# It will be an interface (for now it's just a local implementation)
class WatcherLocal < Watcher
# NOTE: All commands that take argument list shall have default value and accept no arguments as well!

	attr_accessor :server_address

	def ensure_server_init
		@dir = DirMaker.new(server_address)
		@dir.ensure

		# Set up reference counter (creates it unless exists)
		@server_instances_pool = FlockPool.new(@dir.join('instance_pool'))

		# Allocate pool for new key generation
		@key_pool = FlockPool.new(@dir.join('key_pool'))

		# Allocate SYSV semaphores
		# Semaphore "file" names
		@sem_fnames = { 'rcv' => @dir.join('rcv_pool'), 'dscv' => @dir.join('dscv_pool') }
		# Hash of semaphore objects
		@sem = {}
	end

	attr_reader :nokey

	# initialize control structures by the given server address
	def initialize(server_address)
		super({:host => server_address})
		@server_address = config[:host]

		# Make a note that we are supplied with a key, and we don't have to ask pools to give us a new one.
		# We should do it beore ensure_server_init
		@nokey = ! (ENV['LDV_SPAWN_KEY'].nil? || ENV['LDV_SPAWN_KEY'].empty?)

		ensure_server_init
	end

	# Stop server
	def shutdown
		@sem_fnames.keys.each {|pool| ensure_semaphore pool }
		$log.trace @sem.inspect
		@sem.values.compact.each &:ipc_rmid

		FileUtils.rm_r server_address
	end

	# Restart server: create the new state
	def restart(_ = [])
		shutdown
		ensure_server_init
	end

#	def rcv_query_fname(key)
#		rule_id, cmd_id, main_id = key
#		query_fname = File.join server_address, 'rcv', 'queried', "query.rule-#{rule_id}.cmd-#{cmd_id}.main-#{main_id}"
#		task_fname = File.join server_address, 'rcv', 'tasks', "query.rule-#{rule_id}.cmd-#{cmd_id}.main-#{main_id}.task"
#		finished_fname = File.join server_address, 'rcv', 'finished', "query.rule-#{rule_id}.cmd-#{cmd_id}.main-#{main_id}"
#		running_fname = File.join server_address, 'rcv', 'running', "query.rule-#{rule_id}.cmd-#{cmd_id}.main-#{main_id}"
#		[query_fname, task_fname, running_fname, finished_fname]
#	end

	# Ensure that semaphore is created and initialized
	def ensure_semaphore(pool,kill = false)
		pool_file = @sem_fnames[pool] or raise "Can't queue this kind of pools: #{pool}! Only #{@sem_fnames.keys.join(', ')} are supported!"
		FileUtils.touch pool_file
		$log.debug "Going to use semaphore #{pool_file}"
		sem_tok = ftok(pool_file,1)
		# WTF!  Binding doesn't support proper "exceptional" handling of ftok!
		raise "ftok(#{pool_file},1) failed" if sem_tok == -1 || sem_tok == (2**32-1)
		$log.trace "TOKEN: #{sem_tok} for #{pool_file}"
		@sem[pool] = Semaphore.new(sem_tok,1, 0666 | IPC_CREAT)
		# Initialize if a new one (we check if no operations were performed with the semaphore, in this case sem_otime will be 0, see BUGS section of semget(2)
		stats = @sem[pool].ipc_stat
		$log.trace "Semaphore otime: #{stats.sem_otime}"
		if stats.sem_otime == Time.at(0)
			$log.info "Created semaphore #{pool_file}."
			$log.debug "Initializing semaphore #{pool_file} with value #{config["max_#{pool}_pool".to_sym]}."
			@sem[pool].setall [config["max_#{pool}_pool".to_sym]]
		end
	end

	def queue_generic(pool,task,workdir,*key__files)
		# Extract the "key" part, and forget about "files" part: it's only for cluster processing
		key,files = separate_args key__files
		$log.info "Queueing to pool #{pool} task #{task} with wd=#{workdir} and key #{key.inspect}."
		@dir.push 'tasks' do
			query_fname,task_fname,running_fname,finished_fname = %w(queried data running finished).map {|w| @dir.ensure(w,key); @dir.join(w,key,'task')}
			(File.exists?(query_fname) || File.exists?(running_fname)) and raise "The task #{args.inspect} is already in queue"
			$log.debug "Putting workdir to: #{query_fname}"
			File.open(query_fname,'w') { |f| f.puts workdir }
			$log.debug "Copying taskfile to: #{task_fname} from #{task}"
			FileUtils.copy_file(task,task_fname,true)

			# Now run RCV with task file supplied
			$log.info "Forking process to run #{[ENV['RCV_FRONTEND_CMD'],"--rawcmdfile=#{task_fname}"].join(" ")}..."
			rcv_pid = fork do
				# Wait on global semaphore
				ensure_semaphore(pool)
				@sem[pool].op([Sembuf.new(0, -1)])
				# Spawn worker
				$log.info "Running #{pool} with task #{task_fname} right NOW!"
				FileUtils.move(query_fname,running_fname)
				$log.debug "Setting key for the processes spawned: #{key.join(',')}"
				ENV['LDV_SPAWN_KEY'] = key.join(',')
				fork {
					Kernel.exec(ENV['RCV_FRONTEND_CMD'],"--rawcmdfile=#{task_fname}")
					exit 1
				}
				Process.waitall
				FileUtils.move(running_fname,finished_fname)
				# Release global semaphore
				@sem[pool].op([Sembuf.new(0, +1)])
			end
			# If we block, then wait for child to finish
			if config[:block_queue]
				$log.info "Waiting for #{pool} call to finish..."
				Process.waitall
			else
				Process.detach rcv_pid
			end
		end
		nil
	end

	# Wait for the task with key specified by args
	# args may end with either '*' or '#'.  Asterisk means that we only search one level deeper, while sharp means that we search recursively.  If '*' or '#' is met in the other places, it's not traversed.
	def wait(what,*args)
		# we ignore "what" for now...
		$log.debug "Called wait with #{args.inspect}, ignored #{what.inspect}"

		# level to search in the directories for.  nil means infinite.
		level = nil
		case args.last
		when '#'
			level = nil
			args.pop
		when '*'
			level = 1
			args.pop
		else	#it's just a text string
			level = 0
		end #case args.last

		# Check if it's supported
		raise "* and # are only supported as the LAST element of args to be waited!  Use cluster instead!" if args.detect {|s| s == '*' || s == '#' }

		# We'll implement level limiting as traversing directories with infinite level, parsing the paths we traverse to see how many directoried deep we are.  Then, if this value exceeds the level given, we prune the rest of the traversal.
		# And no, we're not from Bangalore.  Really...  No, seriously, take a fucking look around: does it look like a monkey code?
		# Uh, yes, it does... nevertheless... oh, just fuck you.


		# This is not thread-safe, but in this prototype thread-safetyy while waiting is not very important
		@dir.push 'tasks' do
			running,queried,finished =  %w(running queried finished).map{ |w| @dir.join(w,args)}

			# Prepare stuff for level checks
			base_level = file_depth(running)
			level_check = proc {|path| level ? (file_depth(path) <= base_level + level + 1) : true }
			#$log.trace "Args: level=#{level.inspect} path=#{path.inspect} split=#{File.split(path).inspect} length=#{file_depth(path)} rhs=#{(level? (base_level + level + 1):nil).inspect}";

			$log.trace "Searching for files in #{running} and #{queried}"
			def eligible(level_check,*paths)
				paths.flatten!
				any = false
				paths.each do |path| ; Find.find(path) do |fname|
					Find.prune unless level_check.call(fname)
					if File.file? fname
						$log.trace "Eligible file: #{fname}"
						any = true
						break
					end
				end; end
				any
			end
			while eligible(level_check,running,queried,finished)
				$log.trace "Dirs are not empty"
				found_any = false
				waited_for = {}
				Find.find(finished) do |file|
					next unless File.file? file

					# check if the level's not deep enough
					#$log.trace "Level check #{level} for #{file}"
					Find.prune unless level_check.call(file)
					#$log.trace "passed!"

					$log.trace "ACKED #{file} when LEVEL IS #{level.inspect} for #{args.inspect}"; 
					key = keyfilestrip(file,@dir.join('finished'))
					$log.trace "Key is '#{key.inspect}'"
					key.pop
					$log.trace "Key is '#{key.inspect}'"
					# Read data
					waited_workdir = File.read(file).chomp
					$log.trace "Waited workdir is '#{waited_workdir}'"
					# Add to out
					waited_for[ key ] = { :workdir => waited_workdir }
					# Exit
					%w(running queried finished).map{ |w| @dir.join(w,key)}.each {|l| $log.trace "Removing #{l}"}
					FileUtils.rm_rf(%w(running queried finished).map{ |w| @dir.join(w,key)})
					found_any = true
					break
				end
				if found_any
					# Return list of strings, each string being
					# 	workdir,package,key...
					result = waited_for.to_a.map do |item|
					  k,v = item
						$log.debug "Writing key: #{([v[:workdir]] + [""] + k).join ","}"
						([v[:workdir]] + [""] + k).join ","
					end.join "\n"
					return result
				else
					# Nothing found, sleep and repeat
					Kernel.sleep 1
				end
			end
			# Waited for all
			$log.debug "Dirs are empty, return"
			exit 5
		end
	end

	# Add task to queue
	def queue(*args)
		what = args.shift
		queue_generic(what,*args)
	end

	def unpack(*args)
		$log.debug "Unpack does nothing in local mode."
		return nil # Suppress printing
	end

	def spawn(*args)
		@dir.ensure
		new_key = @key_pool.get
		File.open(@dir.join('key'),'w') { |f| f.puts(new_key) }
		File.open(@dir.join('status'),'w') { |f| f.puts('running') }
	end

	# Get key for current args.  If the process is not watched for, generate key from the pool
	def key(*args)
		$log.debug "Key requested for #{args.inspect}"

		# Increase reference counter
		$log.trace "Increasing reference counter..."
		total_refs = @server_instances_pool.get
		$log.debug "Serving #{total_refs} instances"

		# If key's passed from queue procedure, via an ENV variable (as in cluster mode), then return it.  Otherwise, get a new one
		return ENV['LDV_SPAWN_KEY'] if ENV['LDV_SPAWN_KEY']

		# Otherwise, we get a new key
		@dir.push 'keys',args,Process.ppid do
			fname = @dir.join 'key'
			begin
				$log.trace "Trying to read #{fname}..."
				(args + [File.read(fname).chomp]).join(',')
			rescue Errno::ENOENT => f
				$log.trace "key file #{fname} doesn't exist, creating..."
				spawn(args)
				retry
			end
		end
	end

	# Set status for a key (barely useful for local)
	private; def set_status(status,*_args)
		args = _args.flatten
		@dir.push 'keys',args do
			fname = @dir.join('status')
			$log.debug "Writing status '#{status}' to #{fname}..."
			File.open(fname,'w') { |f| f.puts(status) }
		end
	end

	private; def remove_data(*key)
		@sem_fnames.keys.each {|pool| ensure_semaphore pool }
		$log.trace @sem.inspect
		@sem.values.compact.each &:ipc_rmid
		key.flatten!
		to_rm = []
		to_rm += %w(queried data running finished).map {|w| @dir.join('tasks',w,key)}
		# Last item in "key" was generated by us.
		to_rm += [@dir.join('keys',key[0..-2],Process.ppid)]
		to_rm.each do |dir|
			$log.trace "Removing #{dir}"
			FileUtils.rm_rf dir
		end
		nil
	end

	# Decrease reference counter and return if there's no instances left.
	private; def decrease_refcounter_and_check
		references_left = @server_instances_pool.decrease_and_read
		# handling negative numbers as well just in case...
		references_left <= 0
	end

	# Doesn't accept empty args!
	# type is ignored for the local watcher
	public; def success(type,*key__files)
		args, files = separate_args key__files
		$log.info "Reported success for #{args.inspect}"
		#set_status('success',args,Process.ppid)
		remove_data(args) if decrease_refcounter_and_check
	end

	# Doesn't accept empty args!
	# type is ignored for the local watcher
	public; def fail(type,*key__files)
		args, files = separate_args key__files
		$log.info "Reported failure for #{args.inspect}"
		# set_status('fail',args)
		remove_data(args) if decrease_refcounter_and_check
	end
end

