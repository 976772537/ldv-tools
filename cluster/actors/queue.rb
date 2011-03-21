class Ldvqueue

	include Nanite::Actor
	expose :queue, :redo, :announce, :remove, :result, :purge_task, :get_unique_key

	attr_accessor :nodes, :queued, :running, :waiter

	Job_priority = %w(rcv dscv ldv)

	class QueuedTasks < Hash
		def initialize(hash = {})
			super hash
		end
		def log
			self.inject({}) {|r,pair| r[pair[0]] = pair[1].map{|task| task[:key]}; r }.inspect
		end
	end

	DEFAULT_OPTIONS = { :route_time => 5 }

	def initialize
		@status_update_mutex = Mutex.new
		@task_update_mutex = Mutex.new
		@nodes = {}
		@queued = Job_priority.inject(QueuedTasks.new({})) {|r,j| r[j]=[]; r}
		@running = Job_priority.inject({}) {|r,j| r[j]={}; r}

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
		# Cluster logger
		@clog = Logging.logger['Cluster']

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
			@queuestat_timer = EM.add_periodic_timer(20) { @qlog.debug "Queue status: #{@queued.log}" }
			@qrstat_timer.cancel if @qrstat_timer
			@qrstat_timer = EM.add_periodic_timer(10) { q,r = running_stats; @qlog.info "Queued: #{q}; running: #{r}" }
		end

	end

	# Given a key prefix, returns a number to this key
	def get_unique_key(key_info)
		key_skel = key_info['key']
		reply_to = key_info['reply_to']

		@qlog.debug "Unique key requested for #{key_skel}"
		# EventMachine calls handlers synchronously, so no mutex here.
		@key_pool ||= {}
		# FIXME: read this from file
		@key_pool[key_skel] ||= 100
		new_key = @key_pool[key_skel] += 1
		new_key_str = "#{key_skel}.#{new_key}"

		@qlog.info "Unique key requested for #{key_skel}.  Sending: #{new_key_str}"

		new_key_str

		# Launch the task on the node given
		#Nanite.push('/nodeui/take_unique_key',"#{key_skel}.#{new_key}",:target=>reply_to)
	end

	# Fetch task from task queue, selects node to route it to, and pushes it to the cluster
	def route_task
		@task_update_mutex.synchronize do

			# Find job_type and an available node to route job of that type to
			# If nothing found, find will return nils, and job and target will remain nils
			job,target = nil,nil
			Job_priority.find do |job_type|
				if @queued[job_type].empty?
					false	#try job of next type
				else
					# Cluster info log
					@qlog.debug "Node status: #{node_availability_info.or "<none>"}"
					@qlog.trace "A #{job_type} found for queueing..."
																										 # you may set this to -1 for debug
					node = @nodes.keys.shuffle.find {|k| @nodes[k][job_type] > 0}
					availability = @nodes[node]
					if node
						availability[job_type] -= 1
						# return job
						job,target = job_type,node
					else
						@qlog.trace "No nodes were found to queue a #{job_type} job!"
						false
					end
				end
			end
			if target
				task = @queued[job].shift
				@running[job][target] ||= []
				@running[job][target] << task

				@qlog.info "Routing #{job} with key #{task[:key]} to #{target}."
				@qlog.trace "Routed task: #{task.inspect}"

				Nanite.push("/ldvnode/#{job}", task, :target => target)

				# Since queued and running is a hash of hashes, we use jobs[1] instead of jobs
				q,r = running_stats
				@qlog.info "Queued: #{q}; running: #{r}"
				@qlog.debug "Queue task #{task[:key]}, Currently run: #{how_run}"
				@qlog.info "Node status: #{node_availability_info.or "<none>"}"
				@qlog.debug "Keys left in queue: #{queued.log}"
			end
		end
	end

	# Returns summary of queued and running tasks total
	def running_stats
		qu = queued.inject(0){|sum,jobs| jobs[1].length+sum}
		ru = running.inject(0){|sum,jobs| sum + jobs[1].inject(0){|s,node_tasks| node_tasks[1].length+s}}
		return qu,ru
	end

	# Return string that describes distribution of tasks among nodes
	def how_run
		node_keys = {}
		@running.each do |job_type,node_tasks|
			node_tasks.each do |node,tsk|
				node_keys[node] ||= {}
				node_keys[node][job_type] ||= []
				node_keys[node][job_type] = tsk.map{|t| t[:key]}
			end
		end

		node_keys.inspect
	end

	# Adds tasks to queue.  The payload should be a hash with the following attributes:
	# 	:type => dscv, rcv or ldv
	# 	:args => arguments (the taskfile)
	# 	:workdir => working directory for this task
	# 	:key => a string with a key for this task
	def queue(_task, where = :last)
		@qlog.info "Incoming task: #{_task['key']}" if where
		do_queue(_task,where)
	end

	def do_queue(_task, where = :last)
		@qlog.debug "Add to queue: #{_task['key']}"
		@qlog.trace "Queueing task #{_task.inspect}"
		if Ldvqueue.task_correct? _task
			task = Ldvqueue.symbolize(_task)

			# Add information specific to the task's namespace for a node to read
			assign_namespace_data(task)

			# Push the task into queue
			@task_update_mutex.synchronize do
				enqueue_task(task[:type],task,where)
			end

		else
			raise "Badly formed task #{_task.inspect}!"
		end
	end

	def redo(_task)
		@qlog.debug "Reject task: #{_task['key']}!"
		@qlog.trace "Reject task: #{_task}!"
		# Remove from registry of running tasks
		task = Ldvqueue.symbolize _task
		remove_task(task)
		@qlog.debug "Redo task #{_task['key']}, Currently run: #{how_run}"
		# put task into the beginning of the queue
		do_queue(_task,:first)
	end

	# Announce statuses.  Keys MUST be strings, not syms!
	def announce(statuses)
		return unless statuses	#If something weird happened
		@status_update_mutex.synchronize do
			@clog.debug "Announced: #{statuses.inspect}"
			new_nodes = statuses.keys - @nodes.keys
			nodes_to_remove = @nodes.keys - statuses.keys
			@qlog.info "Node status: #{node_availability_info.or "<none>"} (announce)" unless new_nodes.empty? && nodes_to_remove.empty?

			# Invoke special handlers for nodes being removed
			nodes_to_remove.each { |node| remove_node node }
			# Handlers for new nodes
			new_nodes.each {|node| add_node(node,statuses[node]) }
			# And casually switch statuses of nodes that didn't go anywhere
			(statuses.keys & @nodes.keys).each {|n| @nodes[n] = statuses[n] }
		end
	end

	def remove(node)
		@status_update_mutex.synchronize do
			remove_node node
			@clog.warn "Node #{node} was shut down or stalled!"
		end if nodes[node]	# No need to remove non-worker node
	end

	def result(_task)
		task = Ldvqueue.symbolize(_task)
		# Remove result from the queue
		@task_update_mutex.synchronize do
			remove_task(task)
		end
		# Push result to the waiter
		waiter.job_done(task[:key],task)
		@qlog.info "Task finished: #{task[:key]}"
		@qlog.trace "Result gotten of #{task.inspect}"
	end

	# Development only!
	def purge_task(task)
		remove_task_from(task,self.queued)
	end

	def remove_task(task)
		remove_task_from(task,self.running)
	end

	def remove_task_from(task,proper_queue)
		# Find the node, on which the task was running, and remove it from the list
		# FIXME: make it faster?

		node_task_map = proper_queue[task[:type]]
		raise "Task type (#{task[:type]}) is not supported!" unless node_task_map
		node,tasks = node_task_map.find do |node,tasks|
			tasks.find { |queued_task| queued_task[:key] == task[:key] }
		end
		@qlog.trace "remove_task_from Node: #{node.inspect}"
		@qlog.trace "remove_task_from Task: #{task[:key].inspect}"
		# Remove this task from running tasks
		if node
			tasks.reject! { |queued_task| queued_task[:key] == task[:key] } if node
			# If there's no tasks left, delete node from the registry
			@qlog.trace "remove_task_from: tasks left #{tasks.inspect}"
			node_task_map.delete node if tasks.empty?
		end
	end

	# Requeues tasks assigned to node
	def remove_node(node_key)
		@nodes.delete node_key
		@task_update_mutex.synchronize do
			@running.each do |k,v|
				# tasks currently running on the node being removed, for k job type
				node_tasks = v[node_key]
				if node_tasks && !node_tasks.empty?
					# Add at the beginning of the queue: since these tasks are already launched, they should be re-done asap
					node_tasks.each {|t| enqueue_task(k,t,:first) }
				end
				v.delete node_key
			end
		end
		@qlog.debug "Tasks for #{node_key} requeued"
	end

	# Adds node to a pool of available
	def add_node(node,status)
		nodes[node]=status
		@qlog.info "New node #{node} connected!"
	end

	# must - keys that every task should have
	# may  - keys that some tasks might have
	# Other keys are prohibited!
	Task_keys = {'type' => :must, 'args' => :must, 'workdir' => :must, 'key' => :must, 'env'=>:must, 'global' => :may}
	# Check if task is correct
	def self.task_correct?(task)
		task.keys.each do |item|
			raise unless Task_keys[item]
		end
		Task_keys.each do |item,req|
			return false if req == :must && !task[item]
		end
		return true
	end

	# Make hash "symbol->data" from "string->data"
	def self.symbolize(task)
		task.inject({}) {|r,kv| r[kv[0].to_sym]=kv[1];  r }
	end

	def enqueue_task(type,task,where = :last)
		self.queued[type] ||= []
		if where == :last
			self.queued[type] << task
		else
			self.queued[type].unshift task
		end
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

	# Assign global information to the task
	def assign_namespace_data(task)
		key = task[:key]

		# If we have found the global data for the given key
		data_found = false

		# We could use a sophisticated algorithm for this, but we'll just do it quick-and-dirty
		@namespaces.each do |namespace_key, data|
			# Determine if task's key belongs to the namespace
			belongs = (key[0,namespace_key.length] == namespace_key)
			# Assign data if necessary
			if belongs
				task[NAMESPACE_KEY] = data
				data_found = true
				break
			end
		end

		# If data are not found in the local table, then create a new namespace!
		if !data_found && task[NAMESPACE_KEY]
			@qlog.warn "Namespace data for #{key} are not found.  Creating a new namespace with #{task[NAMESPACE_KEY].inspect}."
			task[NAMESPACE_KEY] = add_to_namespace(key,task[NAMESPACE_KEY])
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

end
