class Ldvqueue

	include Nanite::Actor
	expose :queue, :redo, :announce, :remove, :result, :purge_task

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

	def initialize
		@status_update_mutex = Mutex.new
		@task_update_mutex = Mutex.new
		@nodes = {}
		@queued = Job_priority.inject(QueuedTasks.new({})) {|r,j| r[j]=[]; r}
		@running = Job_priority.inject({}) {|r,j| r[j]={}; r}

		# Waiter -- create its own AMQP queues and use them to implement waiting
		# Initialized after construction -- see waiter_new
		@waiter = nil

		# During a tick we'll serve exactly one job, according to the priorities
		EM.add_periodic_timer(10) do
			@task_update_mutex.synchronize do
				# Find job_type and an available node to route job of that type to 
				# If nothing found, find will return nils, and job and target will remain nils
				puts "finding avail node among #{@nodes.size}"
				job,target = nil,nil
				Job_priority.find do |job_type|
					if @queued[job_type].empty?
						false	#try job of next type
					else
						                                         # you may set this to -1 for debug
						node, availability = @nodes.find {|k,v| v[job_type] > 0}
						if node
							availability[job_type] -= 1
							# return job
							job,target = job_type,node
						else
							false
						end
					end
				end
				if target
					puts "Routing #{job} to #{target}"
					task = @queued[job].shift
					@running[job][target] ||= []
					@running[job][target] << task
					puts task.inspect
					Nanite.push("/ldvnode/#{job}", task, :target => target)
				end
			end
			#puts "Status: #{self.nodes.inspect}"
			puts "Tasks: #{self.queued.log}"
			puts "Running: #{self.running.inspect}"
		end

	end

	# Adds tasks to queue.  The payload should be a hash with the following attributes:
	# 	:type => dscv, rcv or ldv
	# 	:args => arguments (the taskfile)
	# 	:workdir => working directory for this task
	# 	:key => a string with a key for this task
	def queue(_task, where = :last)
		puts "Queueing #{_task.inspect}..."
		if Ldvqueue.task_correct? _task
			task = Ldvqueue.symbolize(_task)
			@task_update_mutex.synchronize do
				enqueue_task(task[:type],task,where)
			end
		else
			puts "Badly formed task #{_task.inspect}!"
		end
	end

	def redo(_task)
		puts "Node rejected task #{_task}!"
		# Remove from registry of running tasks
		task = Ldvqueue.symbolize _task
		remove_task(task)
		# put task into the beginning of the queue
		queue(_task,:first)
	end

	def announce(statuses)
		return unless statuses	#If something weird happened
		@status_update_mutex.synchronize do
			puts "Announced: #{statuses.inspect}"
			new_nodes = statuses.keys - @nodes.keys
			nodes_to_remove = @nodes.keys - statuses.keys

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
			puts "Node #{node} removed"
		end
	end

	def result(_task)
		task = Ldvqueue.symbolize(_task)
		# Remove result from the queue
		@task_update_mutex.synchronize do
			remove_task(task)
		end
		# Push result to the waiter
		waiter.job_done(task[:key],task)
		puts "\n ****************************************************** \n"
		puts "Result gotten of #{task.inspect}"
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
		node,tasks = node_task_map.find do |node,tasks|
			tasks.find { |queued_task| queued_task[:key] == task[:key] }
		end
		puts "Node: #{node.inspect}"
		puts "Task: #{task[:key].inspect}"
		# Remove this task from running tasks
		if node 
			tasks.reject! { |queued_task| queued_task[:key] == task[:key] } if node
			# If there's no tasks left, delete node from the registry
			puts tasks.inspect
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
		puts "Tasks for #{node_key} requeued"
	end

	# Adds node to a pool of available
	def add_node(node,status)
		nodes[node]=status
		puts "Node #{node} added to the pool"
	end

	Task_keys = %w(type args workdir key env).sort.freeze
	# Check if task is correct
	def self.task_correct?(task)
		task.keys.sort == Task_keys
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


	## Waiter
	
	def init_waiter(opts = {})
		@waiter = Waiter.new(opts)
	end

end
