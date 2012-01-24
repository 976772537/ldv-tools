require 'active_record'
require 'logger'

def ldv_db_connect
	ActiveRecord::Base.establish_connection(
		:adapter  => 'mysql',
		:database => ENV['LDVDB'],
		:username => ENV['LDVUSER'],
		:password => ENV['LDVDBPASSWD'],
		:host     => (ENV['LDVDBHOST'] || 'localhost')
	)
	ActiveRecord::Base.logger = Logger.new(STDERR)

	# Return collection object
	ActiveRecord::Base.connection()
end

def ldv_report_link
	verifiers_add = ENV['RCV_VERIFIER'] ? 'profilename/rcv/' : ''
  "http://localhost:8999/stats/index/#{verifiers_add}name/#{ENV['LDVDB']}/host/#{(ENV['LDVDBHOST'] || 'localhost')}/user/#{ENV['LDVUSER']}/password/#{ENV['LDVDBPASSWD'] || 'no'}"
end

## KB cache recalculator
# A process that recalcualtes KB cache.  It runs in a background and may be pushed a launch_id to recalculate.  The push interface doesn't block; to communicate the status to the parent process, recalcer should be polled occasionally if it has failed.
class Recalcer
	# Last argument may be a hash. For instance, :fork_callback => proc; unless nil, it's executed in the context of child process.
	def initialize(*args)
		# Result of the process
		@result = nil
		# Recalc's input pipe handler
		@input_pipe = nil
		# Mutex to disallow push before pipe is opened
		@pipe_guard = Mutex.new
		# Guard to ensure that watcher thread is started
		@init_guard = false
		# Abort the thread on exception
		Thread.abort_on_exception = true

		# Start a thread that will watch for KB recalc
		@thread = Thread.new do
			# Spawn recalcer and install handlers
			cerr_handler = proc do |line|
				$stderr.write "KB-RECALC: ERROR: #{line}\n"
			end
			cout_handler = proc do |line|
				$stdout.write "#{line}\n"
			end
			cin_handler = proc do |pid,cin|
				# Save pid (there's no other way to get it)
				@pid = pid
				# Save the input pipe and signal that it should not be waited for
				@input_pipe = cin
				# Unlock "write" call
				@pipe_guard.unlock
				# Transfer control over input pipe to this script
				:detach
			end

			# The mutex will block "write" until everything is initialized
			@pipe_guard.lock
			@init_guard = true
			@result = EnhancedOpen3.open3_linewise(cin_handler,cout_handler,cerr_handler,*args)
		end
		# Wait while watcher thread locks @pipe_guard
		while !@init_guard
			sleep 0.001
		end
	end

	def push(launch_id)
		@pipe_guard.synchronize do
			#If there's a lot of launch id's in the input already, this will block.  But that's OK, it will merely balance the load.
			@input_pipe.write "#{launch_id}\n";
			@input_pipe.flush
		end
	end

	# It's buggy.  Race conditions everywhere around it!
	def dead?
		return ! (@result.nil?)
	end

	def terminate
		# Stop the thread
		@thread.exit
		# There may be a small race condition if the process has been spawned, but the pipe and pid haven't got here.
		@input_pipe.close if @input_pipe
		@input_pipe = nil

		Process.kill('TERM',@pid) if @pid
		@pid = nil
	end

	def wait
		# Signal that there's no more input
		@input_pipe.close
		# Wait for thread termination (which is terminated after the cache recalc terminates)
		@thread.join
		# Reset status
		@input_pipe = nil
		@pid = nil
		# Return process status
		return @result
	end
end

## Convenience functions for REXML
class REXML::Element
	# Get text of the first element statisfying xpath
	def field(xpath)
		if tag = elements[xpath]
			tag.text
		else
			nil
		end
	end
	alias_method :/, :field
end

## Convenience functions for ActiveRecord
class ActiveRecord::Base
	def self.find_or_create(attributes)
		self.first(:conditions => attributes) || self.create(attributes)
	end
end

## Porting from REXML to LibXML stream parser
def ass
	raise "Assertion failed!" unless yield
end
def asseq(a,b)
	raise "Assertion failed: #{a.inspect} != #{b.inspect}!" unless a == b
end
def stats p
	$stderr.puts sprintf("%d %d %p %p %p",p.depth,p.node_type,p.name,p.empty_element?,p.value) if $debug
end
# monkey-patch xml nodes for compatibility
require 'xml'
class LibXML::XML::Reader
	# Make default read to print debug information and ignore whitespace
	alias_method :super_read, :read
	# Ignore whitespace and print stats
	def skipping_read
		super_read
		raw_read_whitespace
		# Print stats
		stats self
	end
	alias_method :read, :skipping_read

	def raw_read_whitespace
		while node_type == TYPE_WHITESPACE || node_type == TYPE_SIGNIFICANT_WHITESPACE
			# Read one more
			super_read
		end
	end

	# If the peeked data is whitespace, read until we encounter a meaningful tag
	def read_whitespace
		raw_read_whitespace
		# Print stats
		stats self
	end

	alias_method :super_next, :next
	def skipping_next
		self.super_next
		self.read_whitespace
	end
	alias_method :next, :skipping_next

	# Returns if this stream points to an end of a tag
	def end_of? tag
		node_type == XML::Reader::TYPE_END_ELEMENT && name == tag
	end

	# Returns if this stream points to a start of a tag
	def start_of? tag
		node_type == XML::Reader::TYPE_ELEMENT && name == tag
	end

	# If current node is a start of one of these tags, returns its name; otherwise, returns nil
	def start_of_these? *tags
		return nil if node_type != XML::Reader::TYPE_ELEMENT
		tags.flatten.index(name) ? name : nil
	end

	# Returns XML::Node of the current tag and reads up to the end of it.
	def consume
		# We copy the element recursively to remove LibXML's ownership from it, and so that it is available after the reader is advanced
		# See: https://github.com/xml4r/libxml-ruby/issues/28
		node = self.expand.copy(true)
		new_doc = XML::Document.new
		new_doc.root = node
		self.skipping_next
		node
	end

	# Consumes the content of the tag peeked, the tag is expected in form <tag>content</tag>
	def consume_contents
		was_empty = empty_element?
		read
		return nil if was_empty
		# If there was no text (but the element is not empty, e.g. <a></a>), then don't read twice
		if node_type != XML::Reader::TYPE_END_ELEMENT
			r = value
			read
		else
			r = ''
		end
		read
		r
	end
end

class LibXML::XML::Node
	# Get text of the first element statisfying xpath
	def field(xpath)
		if tag = find_first(xpath)
			tag.content
		else
			nil
		end
	end
	alias_method :/, :field
	# Get elements that match xpath, as a list
	def elements(xpath)
		find xpath
	end
	# Get first element that matches xpath, or nil if none do
	def element(xpath)
		find_first xpath
	end
end


