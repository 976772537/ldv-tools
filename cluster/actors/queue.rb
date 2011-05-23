require 'scheduler/tasks'

class Ldvqueue

	include Nanite::Actor
	expose :queue, :redo, :announce, :remove, :result, :purge_task, :get_unique_key

	attr_accessor :nodes, :queued, :running, :waiter, :tasks

	Job_priority = %w(rcv dscv ldv)

	DEFAULT_OPTIONS = { :route_time => 5 }

	def initialize
		# deadlock prevention: task can't be hold inside status's sync block
		@status_update_mutex = Mutex.new
		@task_update_mutex = Mutex.new
		@key_pool_mutex = Mutex.new

		# Node status notion
		@nodes = {}
		@discount = []
		@load_range = 60
		@load_start_coeff = 1
		@load_end_coeff = 1

		@tasks = TaskStorage.new(Job_priority,nil)

		# Default unique key (for new pools)
		@default_key = 100

		# Waiter -- create its own AMQP queues and use them to implement waiting
		# Initialized after construction -- see waiter_new
		@waiter = nil

		# Namespace
		initialize_namespace

		# Imbue the default configuration
		reconfigure DEFAULT_OPTIONS
	end

	# Reconfigures the queue with the options given.  Used for hot reconfiguration or just to configure it, since initialize doesn't accept any options.
	def reconfigure(opts = {})
		# Initialize loggers (they might have been reconfigured as well).  NOTE that loggers should be the first to initialize, since all the information on how well the reinitialization went goes there
		# Queue logger
		@qlog = Logging.logger['Task']
		tasks.qlog = @qlog
		# Cluster logger
		@clog = Logging.logger['Cluster']

		# TODO: This should hold all the mutexes (crucial when it will be performed on-line)

		# Serialization init
		@key_fname = File.expand_path File.join('data','max_key')
		deserialize(:all)

		# Node selection algorithm
		@max_load = opts[:max_node_load] || 100
		@select_node = lambda do |node_stats|
			return nil if node_stats.empty?

			# Get list of nodes that have a load low enough
			all_nodes = node_stats.keys
			capable_nodes = all_nodes.select {|node_key| !node_stats[node_key]['max_load'] || (node_stats[node_key]['load'].to_f < node_stats[node_key]['max_load'].to_f) }

			# Choose a least loaded node from the capable
			least_loaded_node = capable_nodes.min_by {|node_key| node_stats[node_key]['load'].to_f }
			# Check if the load is low enough
			if !least_loaded_node || node_stats[least_loaded_node]['load'].to_f > @max_load
				@qlog.debug "Couldn't find a capable node!"
				nil
			else
				@qlog.trace "OK, max load is #{node_stats[least_loaded_node]['load']}, less than #{@max_load} and node's #{node_stats[least_loaded_node]['max_load']}"
				least_loaded_node
			end
		end
		#@select_node = lambda {|node_stats| node_stats.keys.shuffle.first}
		# Discounting heuristic
		@load_range = opts[:disc_range] || 60
		@load_start_coeff = opts[:disc_start] || 1.0
		@load_end_coeff = opts[:disc_end] || 1.0

		# Restart route timer
		# During a tick we'll serve exactly one job, according to the priorities
		if route_timer_interval = opts[:route_time].to_f
			@qlog.debug "Reconfigure: route timer is #{route_timer_interval}"
			@route_timer.cancel if @route_timer
			@route_timer = EM.add_periodic_timer(route_timer_interval) { route_task }

			# Add timely loggers (each 5 queue iterations print node statuses)
			@nodestat_timer.cancel if @nodestat_timer
			@nodestat_timer = EM.add_periodic_timer(10) { @qlog.info "Node status: #{node_availability_info.or "<none>"}" }
			@queuestat_timer.cancel if @queuestat_timer
			@queuestat_timer = EM.add_periodic_timer(20) { @qlog.debug "Queue status: #{inspect_array_of tasks.queued(:all)}" }
			@runstat_timer.cancel if @runstat_timer
			@runstat_timer = EM.add_periodic_timer(60) { @qlog.info "Running tasks: #{inspect_array_of tasks.running_on(:all)}" }
			@qrstat_timer.cancel if @qrstat_timer
			@qrstat_timer = EM.add_periodic_timer(10) { @qlog.info "Queued: #{tasks.queued(:all).size}; running: #{tasks.running_on(:all).size}" }
		end

	end

	# Returns a string with a nice representation of array of tasks
	def inspect_array_of tasks_arr
		'[' + tasks_arr.map{|t| "{#{t.key} #{t.status} on #{n t.node}}"}.join("\t") + ']'
	end

	# Given a key prefix, returns a number to this key
	def get_unique_key(key_info)
		key_skel = key_info['key']
		reply_to = key_info['reply_to']

		@qlog.debug "Unique key requested for #{key_skel}"
		@key_pool_mutex.synchronize do
			@key_pool ||= {}
			@key_pool[key_skel] ||= @default_key
		end
		new_key = @key_pool[key_skel] += 1

		# Serialize as soon as possible
		serialize

		new_key_str = "#{key_skel}.#{new_key}"

		@qlog.info "Unique key requested for #{key_skel}.  Sending: #{new_key_str}"

		# Return the new key, and the requestor will get it
		new_key_str
	end

	# Fetch task from task queue, selects node to route it to, and pushes it to the cluster
	def route_task
		# Take a task from queue and launch it
		# The action performed is implemented as a callback
		as_a_result = proc { }
		@task_update_mutex.synchronize do

			# At this point, every task queued has never been finished in the cluster.

			# Find job_type and an available node to route job of that type to
			# If nothing found, find will return nils, and job and target will remain nils
			job,target = nil,nil
			Job_priority.find do |job_type|
				if tasks.queued(job_type).empty?
					false	#try job of next type
				else
					# Cluster info log
					@qlog.debug "Node status: #{node_availability_info.or "<none>"}"
					@qlog.trace "A #{job_type} found for queueing..."
																										 # you may set this to -1 for debug
					#node = @nodes.keys.shuffle.find {|k| @nodes[k][job_type] > 0}

					# Get list of nodes which have enough free slots to accept this job
					available_nodes = @nodes.inject({}) {|r,kv| r[kv[0]] = kv[1] if kv[1][job_type] > 0 ; r }
					@qlog.trace "available_nodes for #{job_type}: #{available_nodes.inspect}"
					# Apply discounting heuristic to the load of these nodes
					available_nodes_with_discount = discount available_nodes
					@qlog.trace "available_nodes (discounted) for #{job_type}: #{available_nodes_with_discount.inspect}"

					node = @select_node[available_nodes_with_discount]
					if node
						# Decrease our notion of node load
						availability = @nodes[node]
						# Node will absorb less jobs
						availability[job_type] -= 1
						# Node is more loaded
						add_discount(+1.0*@load_start_coeff*Task_discount[job_type],node)

						# return job
						job,target = job_type,node
					else
						@qlog.trace "No nodes were found to queue a #{job_type} job!"
						false
					end
				end
			end
			if target
				task = tasks.queued(job).first
				@qlog.trace "Moving task #{task.inspect} to running"
				task.dequeue
				task.run_on target
				as_a_result = proc {route_task_to job, task.raw, target}
			end
		end # task mutex sync
		as_a_result[]
	end

	# Route task to specific target.  Does not need a mutex
	private; def route_task_to job, raw_task, target
		@qlog.info "Routing #{job} with key #{raw_task['key']} to #{n target}."
		@qlog.trace "Routed task: #{raw_task.inspect}"

		Nanite.push("/ldvnode/#{job}", raw_task, :target => target)

		# Since queued and running is a hash of hashes, we use jobs[1] instead of jobs
		@qlog.info "Queued: #{tasks.queued(:all).size}; running: #{tasks.running_on(:all).size}"
		@qlog.debug "Queue task #{raw_task['key']}, Currently run: #{how_run}"
		@qlog.info "Node status: #{node_availability_info.or "<none>"}"
		# FIXME
		@qlog.debug "Keys left in queue: #{inspect_array_of tasks.queued(:all)}"
	end

	# Returns summary of queued and running tasks total
	#private; def running_stats
		#qu = queued.inject(0){|sum,jobs| jobs[1].length+sum}
		#ru = running.inject(0){|sum,jobs| sum + jobs[1].inject(0){|s,node_tasks| node_tasks[1].length+s}}
		#return qu,ru
	#end

	# Return string that describes distribution of tasks among nodes
	def how_run
		node_keys = {}
		tasks.running_on(:all).each do |k|
			node_keys[k.node] ||= {}
			node_keys[k.node][k.type] ||= []
			node_keys[k.node][k.type] << k.key
		end

		node_keys.inspect
	end

	# Adds tasks to queue.  The payload should be a hash with the following attributes:
	# 	:type => dscv, rcv or ldv
	# 	:args => arguments (the taskfile)
	# 	:workdir => working directory for this task
	# 	:key => a string with a key for this task
	public; def queue(_task, where = :last)
		@qlog.info "Incoming task: #{_task['key']}" if where
		@task_update_mutex.synchronize {do_queue(_task,where)}
	end

	# Should have mutex locked at the beginning!
	def do_queue(_task, where = :last)
		@qlog.warn "Mutex is not locked in do_queue!" unless @task_update_mutex.locked?
		begin
			task = tasks.queue(_task,where)
		rescue TaskExists => te
			task = te.task
			@qlog.trace "Task we wanted to queue already exists: #{task.inspect}"
			# If the task has already finished, but is queued again (we assume that it's due to a denial of its parent), we send result at once instead of queueing it.
			if task.finished?
				do_result task,false

			# Second, we do not queue if it's already queued or running.  If the task is running on an alive node, then it will finish, and the receiver will get the result anyway.  If the scheduler thinks the task is running on an alive node, but the node's actually dead, the announce from cluster controller will re-queue the task, and put it to the beginning of the queue.  So, any task will be executed at least once.
			elsif task.queued? || task.running?
				# do nothing

			# Otherwise the task is neither finished nor going to run.  Perhaps, something wrong is occured?  Let's remove the task and retry
			else
				tasks.purge task
				retry
			end
		end

		# Add information specific to the task's namespace for a node to read
		assign_namespace_data(task)
	end

	def redo(_task)
		@qlog.debug "Reject task: #{_task['key']}!"
		@qlog.trace "Reject task: #{_task}!"
		key = _task['key']

		@task_update_mutex.synchronize do
			# Remove from registry of running tasks
			task = tasks.task_of(key)
			task.requeue

			@qlog.debug "Redo task #{key}, Currently run: #{how_run}"
			# put task into the beginning of the queue
			do_queue(_task,:first)
		end

		# We might "want" to fix up our notion of node's status, and increase its availability, for instance.  But the thing is that doing a "redo" means that out notion of the status was incorrect in the first place!  So we don't invoke fixup_status here
		#fixup_status task

	end

	# Get "nice" name of the node.  We use node_name hash (node @nodes) since we'd like to see the names of already deceased ones, whild @nodes tracks "live" nodes.
	def n node
		return node unless @node_name
		@node_name[node] || node
	end

	# Announce statuses.  Keys MUST be strings, not syms!
	def announce(statuses)
		return unless statuses	#If something weird happened
		@task_update_mutex.synchronize do
			@clog.debug "Announced: #{statuses.inspect}"
			new_nodes = statuses.keys - @nodes.keys
			nodes_to_remove = @nodes.keys - statuses.keys
			@qlog.info "Node status: #{node_availability_info.or "<none>"} (announce)" unless new_nodes.empty? && nodes_to_remove.empty?

			# Store nice names
			@node_name ||= {}
			statuses.each do |node,st|
				@node_name[node] = st['node_name']
			end

			# Invoke special handlers for nodes being removed
			nodes_to_remove.each { |node| remove_node node }
			# Handlers for new nodes
			new_nodes.each {|node| add_node(node,statuses[node]) }
			# And casually switch statuses of nodes that didn't go anywhere
			(statuses.keys & @nodes.keys).each {|n| @nodes[n] = statuses[n] }

			# Fixup statuses: convert strings to floats
			@nodes.each do |node,st|
				st['load'] = st['load'].to_f if st['load']
				# Save real load to a separate variable (we'll discount loads based on this)
				st['real_load'] = st['load']
			end
			@clog.debug "Announced (discount): #{(discount @nodes).inspect}"
		end
	end

	def remove(node)
		@task_update_mutex.synchronize do
			remove_node node if nodes[node]	# No need to remove non-worker node
		end
	end

	def result(_task)
		@qlog.trace "Result with raw task #{_task.inspect}"
		task = tasks.task_of_raw _task

		unless task
			if data = find_in_namespaces(_task['key'])
				# NOTE: this block handles situations when preprocessing in DSCV failed.  This means that we haven't even issued an RCV command, and we know it will fail, so we just send its result without queueing it.  Smells like a hack, but it's easier to rewrite this than to clear that DSCV/RCV mess.
				@qlog.warn "Strange result with key #{_task['key']} arrived (perhaps, an error occured?).  Accepting it since it's from our namespace."
				# Queue and immediately do the result of task
				# But first, make task conforming to task spec
				_task['workdir'] ||= '/abrakadabra/'
				_task['type'] ||= 'rcv'
				_task['args'] ||= 'none'
				_task['env'] ||= []
				@task_update_mutex.synchronize do
					do_queue _task
					task = tasks.task_of_raw _task
					# Instantly remove it from queue
					task.dequeue
					# Save result to broker
					do_result task, false
				end
				return nil
			else
				@qlog.warn "Strange result with key #{_task['key']} arrived (perhaps, an error occured?).  Ignoring."
				return nil
			end
		else
			# If we found the task -- do its result then
			do_result task
		end
	end

	# do_results, unlike +result+, gets an "internal" task, not a raw one
	# When result is called from the outside, it needs to lock a task mutex.  However, some inside code already holds the mutex and wants to call result().  That's why need_lock is necessary here.
	def do_result(task,need_mutex_lock = true)
		@qlog.info "Task finished: #{task.key}"
		unsafe_work = proc do
			# Remove result from the queue
			task.finish

			# Alter our notion about node's status
			# As node first sends the result, and then performs local cleanups, we pause a bit for this status (WE DON'T)
			fixup_status(task)
		end
		if need_mutex_lock
			@task_update_mutex.synchronize &unsafe_work
		else
			unsafe_work[]
		end

		# Push result to the waiter
		waiter.job_done(task.key,task.raw)

		@qlog.trace "Result gotten of #{task.inspect}"

		true
	end

	# When task is removed from queue, we alter our notion its node availability.
	# Task is a taskhandler.
	def fixup_status(task)
		@clog.trace "Status fixup for node #{task.node} after result of #{task.inspect}"
		# Add a slot into our notion about that node
		if @nodes[task.node]
			@nodes[task.node][task.type] += 1
			# Add discount on status of nodes: pretend that it's less than the value the node tells us
			add_discount(-1.0*@load_end_coeff*Task_end_discount[task.type.to_s],task.node)
		end
	end

	# Discount stats given by stored discounts.  Remove old discounts.
	# When we send a task to a node, we increase the real load average for this node for 1 minute by value decreasing over this minute from 1 to 0. After 1 minute we consider the load established, and remove this discount
	# When a task finishes, we decrease the load average in the same way.
	def discount discounted
		@qlog.warn "Mutex is not locked in discount!" unless @task_update_mutex.locked?

		@qlog.trace "Current discounts: #{@discount.inspect}"
		# Save the current time (for consistency)
		nowtime = Time.now
		# Remove discounts for nodes older than a minute
		while @discount.first && (nowtime - @discount.first[:time] > @load_range)
			@qlog.trace "Discount drop #{@discount.first.inspect}"
			@discount.pop
		end
		# NOTE that we do not remove discounts if a task has started and finished in a minute.  If this happens, the total effect on the node's load will remain constant and negative for some time, and then will increase up to zero.  This should alleviate an increase in average load that took into account the task that has already finished, has contributed to the load average, but does not predict the future anymore.

		# Discount real load, not the current one!
		discounted.each do |k,v|
			v['load'] = v['real_load']
		end
		# Add discount to the stats of each node
		@discount.each do |d|
			if discounted[d[:node]]
				discounted[d[:node]]['load'] += d[:value]*(1 - (nowtime - d[:time]).to_f / @load_range)
			end
		end
		discounted
	end

	Task_discount = {'ldv' => 1, 'dscv' => 0.5, 'rcv' => 1 }
	Task_end_discount = {'ldv' => 1, 'dscv' => 0.7, 'rcv' => 1 }

	def add_discount value, node
		@qlog.warn "Mutex is not locked in remove_lock!" unless @task_update_mutex.locked?

		was = discount(@nodes)[node]['load']
		@discount << {:time=>Time.now, :value => value.to_f, :node => node}
		now = discount(@nodes)[node]['load']
		@qlog.trace "Discounted #{node} by #{value} from #{was} to #{now}"
	end

	# Development only!
	def purge_task(task)
		fail
		remove_task_from(task,self.queued)
	end

	# Requeues tasks assigned to node
	# Must be done under a mutex!
	def remove_node(node_key)
		@qlog.warn "Mutex is not locked in remove_node!" unless @task_update_mutex.locked?
		@clog.warn "Node #{node_key} (#{n node_key}) was shut down or stalled!"
		@nodes.delete node_key

		tasks.running_on(node_key).each do |k|
			@qlog.trace "Requeueing #{k.inspect}"
			k.requeue
		end
		@qlog.debug "Tasks for #{node_key} requeued"
	end

	# Adds node to a pool of available
	def add_node(node,status)
		@qlog.warn "Mutex is not locked in add_node!" unless @task_update_mutex.locked?
		nodes[node]=status
		@qlog.info "New node #{node} (#{n node}) connected!"
	end


	NODE_PRETTY = [['ldv','L'],['dscv','D'],['rcv','R']]
	# Print a nice string about availability of services on nodes.
	# The example is : ".DR ..R L..", where L,D and R stand for LDV, DSCV and RCV.
	def node_availability_info
		@nodes.values.inject([]) do |str_arr, node|
			str_arr.push(NODE_PRETTY.inject(""){|str,kv| str.concat(node[kv[0]] > 0 ? kv[1] : '.')})
		end.join(" ")
	end

	## Namespaces
	#
	# Namespaces is a mechanism for storing global data for certain tasks.
	# A namespace is an array of strings.  If it's a prefix of a task's key, the task is said to belong to the namespace.
	#
	# For tasks that belong to a namespace a special hash under ":global" key is attached to the tasks sent to nodes.  This information from nodes themselves is discarded.

	# Initializes namespace data
	def initialize_namespace
		@namespaces = {}
	end

	NAMESPACE_KEY = :global

	def find_in_namespaces(key)
		# We could use a sophisticated algorithm for this, but we'll just do it quick-and-dirty
		@namespaces.each do |namespace_key, data|
			# Determine if task's key belongs to the namespace
			belongs = (key[0,namespace_key.length] == namespace_key)
			# Assign data if necessary
			if belongs
				return data
			end
		end
		# Not found
		return nil
	end

	# Assign global information to the task
	def assign_namespace_data(task)
		key = task[:key]

		if data = find_in_namespaces(key)
			task[NAMESPACE_KEY] = data
		else
			# If data are not found in the local table, then create a new namespace!
			if task[NAMESPACE_KEY]
				@qlog.warn "Namespace data for #{key} are not found.  Creating a new namespace with #{task[NAMESPACE_KEY].inspect}."
				task[NAMESPACE_KEY] = add_to_namespace(key,task[NAMESPACE_KEY])
			end
		end
	end

	# Adds data under namespace_key to the namespace table
	def add_to_namespace(namespace_key,data)
		@namespaces[namespace_key] = data
		# Ensure that namespace name is added to data
		data[:name] ||= namespace_key
		data
	end

	## Waiter

	def init_waiter(opts = {})
		@waiter = Waiter.new(opts)
	end


	## SERIALIZATION
	# Serialization prototype.  Currently serializes keys to files.  Should be called synchronously.
	def serialize(what = :all)
		# Save key
		begin
			FileUtils.mkdir_p(File.dirname(@key_fname))
			File.open(@key_fname,'w') do |f|
				@qlog.trace "Serialize keys: #{@key_pool.inspect}"
				Marshal.dump(@key_pool,f)
			end
		rescue
			@qlog.error "Serialization failed"
		end
	end

	def deserialize(what = :all)
		begin
			File.open(@key_fname) do |f|
				@key_pool = Marshal.load(f)
			end
		rescue
			@key_pool = nil
		end
	end

end
