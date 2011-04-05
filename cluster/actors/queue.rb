require 'scheduler/tasks'

class Ldvqueue

	include Nanite::Actor
	expose :queue, :redo, :announce, :remove, :result, :purge_task, :get_unique_key

	attr_accessor :nodes, :queued, :running, :waiter, :tasks

	Job_priority = %w(rcv dscv ldv)

	DEFAULT_OPTIONS = { :route_time => 5 }

	def initialize
		@status_update_mutex = Mutex.new
		@task_update_mutex = Mutex.new
		@nodes = {}

		@tasks = TaskStorage.new(Job_priority,nil)

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
			@queuestat_timer = EM.add_periodic_timer(20) { @qlog.debug "Queue status: #{tasks.queued(:all).inspect}" }
			@qrstat_timer.cancel if @qrstat_timer
			@qrstat_timer = EM.add_periodic_timer(10) { @qlog.info "Queued: #{tasks.queued(:all).size}; running: #{tasks.running_on(:all).size}" }
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
		# Take a task from queue and launch it
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
				task = tasks.queued(job).first
				@qlog.trace "Moving task #{task.inspect} to running"
				task.dequeue
				task.run_on target
				route_task_to job, task.raw, target
			end
		end

	end

	# Route task to specific target.  Does not hold a mutex
	private; def route_task_to job, raw_task, target
		@qlog.info "Routing #{job} with key #{raw_task['key']} to #{target}."
		@qlog.trace "Routed task: #{raw_task.inspect}"

		Nanite.push("/ldvnode/#{job}", raw_task, :target => target)

		# Since queued and running is a hash of hashes, we use jobs[1] instead of jobs
		@qlog.info "Queued: #{tasks.queued(:all).size}; running: #{tasks.running_on(:all).size}"
		@qlog.debug "Queue task #{raw_task['key']}, Currently run: #{how_run}"
		@qlog.info "Node status: #{node_availability_info.or "<none>"}"
		# FIXME
		@qlog.debug "Keys left in queue: #{tasks.queued(:all).inspect}"
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
		do_queue(_task,where)
	end

	def do_queue(_task, where = :last)
		begin
			task = tasks.queue(_task,where)
		rescue TaskExists => te
			task = te.task
			@qlog.trace "Task we wanted to queue already exists: #{task.inspect}"
			# If the task has already finished, but is queued again (we assume that it's due to a denial of its parent), we send result at once instead of queueing it.
			if task.finished?
				result task.raw

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
		# Remove from registry of running tasks
		key = _task['key']
		tasks.task_of(key).requeue
		@qlog.debug "Redo task #{key}, Currently run: #{how_run}"
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
		end if nodes[node]	# No need to remove non-worker node
	end

	def result(_task)
		@qlog.trace "Result with raw task #{_task.inspect}"
		task = tasks.task_of_raw _task

		unless task
			@qlog.warn "Strange result with key #{_task['key']} arrived (perhaps, from previous trash run?).  Ignoring."
			return nil
		end

		@qlog.info "Task finished: #{task.key}"
		# Remove result from the queue
		task.finish
		# Push result to the waiter
		waiter.job_done(task.key,task.raw)
		@qlog.trace "Result gotten of #{task.inspect}"
	end

	# Development only!
	def purge_task(task)
		fail
		remove_task_from(task,self.queued)
	end

	def remove_task(task)
		remove_task_from(task,self.running)
	end

	# Requeues tasks assigned to node
	def remove_node(node_key)
		@clog.warn "Node #{node_key} was shut down or stalled!"
		@nodes.delete node_key

		#@task_update_mutex.synchronize do

		tasks.running_on(node_key).each do |k|
			@qlog.trace "Requeueing #{k.inspect}"
			k.requeue
		end
		@qlog.debug "Tasks for #{node_key} requeued"
	end

	# Adds node to a pool of available
	def add_node(node,status)
		nodes[node]=status
		@qlog.info "New node #{node} connected!"
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
