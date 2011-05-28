# Implementation of task storage in scheduler

require 'find'

class TaskExists < Exception
	attr_accessor :task
	def initialize(_task)
		super
		@task = _task
	end
end

class TaskStorage
	attr_accessor :qlog

	# Initialize an empty task storage.
	public; def initialize(_types,_logger)

		@types = _types
		# Task storage (with certain queries optimized)
		@store = {}

		@qlog = _logger

		@queue = []
		@running = []
	end

	# Populate the pool of finished tasks from file server folder.  It is a hack used when the scheduler fails, and we need to re-use its results.  We only populate the storage for the specific key (to avoid loading useless tasks)
	public; def populate_from_filesrv(folder,key)
		Find.find folder do |f|
			fname = File.basename f
			if fname =~ /^(#{key}.*)-to-parent.pax/
				_new_task = { 'key' => $1 }
				_new_task['workdir'] = '/abrakadabra/'
				_new_task['type'] = 'rcv'
				_new_task['args'] = 'none'
				_new_task['env'] = []
				yield _new_task
			end
		end
	end

	# QUERYING STORAGE

	# returns task descriptor given a raw task
	def task_of_raw raw
		return nil unless !raw.nil? && raw.respond_to?(:[])
		task_of raw['key']
	end

	# returns task descriptor given a key
	def task_of key
		@store[key]
	end

	# QUEUEING TASKS

	# Queues a new task raw task, and returns the wrapped task for it.
	# If a task for this raw task already exists, throws an exception with the existing task
	public; def queue(_task, where = :last)
		qlog.trace "Queueing task #{_task.inspect}"

		# Create a new record for this task (but still do not add it to the storage!)
		task = TaskDescriptor.new _task,self
		key = task.key

		existing_task = @store[key]
		raise TaskExists.new(existing_task) if existing_task

		qlog.debug "Add to queue: #{key}"

		# Add task to the storage
		@store[key] = task
		# Push the task into queue
		enqueue_raw(task,where)
		# Return the newly added task descriptor
		return task
	end

	# Returns enumeration of the queued tasks of the job specified (or on all tasks) 
	public; def queued(job_type = :all)
		if job_type == :all
			@queue.dup
		elsif @types.include? job_type
			@queue.select {|q| q.type == job_type }
		else
			raise "Unrecognized type: '#{job_type.to_s}'"
		end
	end

	# Remove the task from queued (not running) if it's there
	public; def dequeue key
		@queue.delete_if {|k| k.key == key }
	end

	# Returns list of tasks running on a certain node (or on all nodes)
	public; def running_on(node_key = :all)
		if node_key == :all
			@running.dup
		else
			@running.select {|k| k.node == node_key }
		end
	end

	public; def enqueue_raw(task,where = :last)
		task.status = :queued
		if where == :last
			@queue << task
		else
			@queue.unshift task
		end
	end

	# RUNNING/STOPPING

	# Remove the task from running (not queued) if it's there.  Return the task record for the key given.
	public; def stop key
		removing = nil
		@running.delete_if {|k| do_it = k.key == key;  removing = k if do_it ; do_it  }
		removing
	end

	public; def run_on task,node
		@running << task
	end

	public; def pruge task
		@store.delete task.key
	end
end

# Descriptor of task, a small structure that contains an information about task relevant to the scheduler.  On demand, may yield the task itself, which is to be sent over the cluster to the other nodes.
class TaskDescriptor
	attr_reader :storage,:key,:node,:type
	attr_accessor :status

	# CORRECTNESS OF TASKS
	#
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
	# Make hash "string->data" from "symbol->data"
	def self.desymbolize(task)
		task.inject({}) {|r,kv| r[kv[0].to_s]=kv[1];  r }
	end


	def initialize(_raw,_storage)
		raise "Badly formed task #{_raw.inspect}!" unless TaskDescriptor.task_correct? _raw

		# Symbolize keys and check if task has already been added
		sym_task = TaskDescriptor.symbolize(_raw)

		@storage = _storage
		@key = sym_task[:key]
		@status = :unknown
		@payload = {}
		@node = nil
		@payload = sym_task
		@type = @payload[:type]
	end

	def to_s
		inspect
	end
	def inspect
		node_desc = node ? " @node=#{node}":""
		"#<TaskDesc @key=#{key.inspect}, @status=#{status.inspect}, @type=#{type.inspect}#{node_desc}>"
	end

	def running?
		@status == :running
	end

	def queued?
		@status == :queued
	end

	def finished?
		@status == :finished
	end

	def dequeue
		@storage.dequeue key
	end

	def raw
		TaskDescriptor.desymbolize @payload
	end

	def [] k
		@payload[k]
	end
	def []= k,v
		@payload[k] = v
	end

	# Make task run on the node
	def run_on node
		@status = :running
		dequeue
		@node = node
		@storage.run_on self,node
	end

	# Remove the task from set of running tasks and mark it as finished
	def finish
		@storage.stop key
		@status = :finished
	end

	# Requeue into the beginning of the queue
	def requeue
		stop
		@storage.enqueue_raw self, :first
	end

	private
	# Remove task from set of running tasks
	def stop
		@storage.stop key
		@status = :stopped
	end

end

