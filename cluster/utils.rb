require 'socket'
require 'utils/logging.rb'

# Get local IP of the interface, through which the request to the host supplied is routed to.
# If the host is not specified, uses 'google.com'
def local_ip(to_host = 'google.com')
  orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

  UDPSocket.open do |s|
    s.connect to_host, 1
    s.addr.last
  end
ensure
  Socket.do_not_reverse_lookup = orig
end

def ip_localhost?(ip)
	# First IP may be external, but the second will be definitely local
	route_ip = local_ip(local_ip(ip))
	Logging.logger['Nanite'].trace "Check if IP is local #{ip}.  Route_ip: #{route_ip}"
	result = (route_ip =~ /^127\./) || (route_ip == 'localhost') || (route_ip == ENV['LDV_LOCAL_IP'])
	Logging.logger['Nanite'].trace "Checked if IP is local #{ip}: #{result}"
	result
end

def select_read(streams)
	begin
		r = select(streams,nil,nil,1)
	end while not r
	streams.inject(nil) do |r,s|
		begin
			(r)?(r):([s,s.readline])
		rescue EOFError
			nil
		end
	end
end

# Perl-like "if string is empty then another value"
# For more info see http://coldattic.info/shvedsky/pro/blogs/a-foo-walks-into-a-bar/posts/51

class String
	def or str
		(self == '')? str : self
	end
end


# Program run helpers
require 'utils/open3'

# Open a stream with open3, and invoke a callback when a stream is ready for reading (but may be in EOF mode).  Waits till the process terminates, and returns its error code.  Callbacks should not block for FDs with data available.
def open3_callbacks(cout_callback, cerr_callback, *args)
	code = nil
	MyOpen3.popen3(*args) do |cin,cout,cerr,thr|
		pid = thr[:pid]
		# Close input at once, as we don't use it
		cin.close_write
		# If the End-Of-File is reached on all of the streams, then the process might have already ended
		non_eof_streams = [cerr,cout]
		# Progressive timeout.  We assume that probability of task to be shorter is greater than for it to be longer.  So we increase timeout interval of select, as with time it's less likely that a task will die in the fixed interval.
		sleeps = [ [0.05]*20,[0.1]*5,[0.5]*3,1,2,4].flatten
		while non_eof_streams.length > 0
			# Get next timeout value from sleeps array until none left
			timeout = sleeps.shift || timeout
			r = select(non_eof_streams,nil,nil,timeout)
			# If nothing happened during a timeout, check if the process is alive.
			# Perhaps, it's dead, but the pipes are still open,  This actually happened by sshfs process, which spawns a child and dies, but the child inherits the in-out-err streams, and does not close them.
			unless r
				if thr.alive?
					# The process is still running, no paniv
					next
				else
					# The process is dead.  We consider that it won't print anymore, and thus the further polling the pipes will only lead to a hangup.  Thus, breaking.
					break
				end
			end
			if r[0].include? cerr
				begin
					cerr_callback[pid,cerr]
				rescue EOFError
					non_eof_streams.delete_if {|s| s==cerr}
				end
			end
			if r[0].include? cout
				begin
					cout_callback[pid,cout]
				rescue EOFError
					non_eof_streams.delete_if {|s| s==cout}
				end
			end
		end
		# Reap process status
		# NOTE: in the ruby 1.8.7 I used this line may block for up to a second (due to internal thread scheduling machanism of Ruby).  In 1.9 this waitup is gone.  Upgrade your software if you encounter differences.
		code = thr.value
	end
	# Return code, either nil if something bad happened, or the actual return code if we were successful
	return code
end

# Read linewise and supply lines to callbacks
# Linewise read can not use "readline" because the following situation may (and did) happen.  The process spawned writes some data to stderr, but does not terminate it with a newline.  We run a callback for stderr, use readline and block.  The process spawned then writes a lot of data to stdout, reaches pipe limit, and blocks as well in a write(stdout) call.  Deadlock.  So, we use more low-level read.
def open3_linewise(cout_callback, cerr_callback, *args)
	# Read this number of bytes from stream per nonblocking read
	some = 4096

	# Standard output backend
	cout_buf = ''
	cout_backend = proc do |pid,cout|
		cout_buf += cout.readpartial some
		while md = /(.*)\n/.match(cout_buf)
			cout_callback[md[1]]
			cout_buf = md.post_match
		end
	end

	# standard error backend
	cerr_buf = ''
	cerr_backend = proc do |pid,cerr|
		cerr_buf += cerr.readpartial some
		while md = /(.*)\n/.match(cerr_buf)
			cerr_callback[md[1]]
			cerr_buf = md.post_match
		end
	end

	retcode = open3_callbacks(cout_backend,cerr_backend,*args)

	# Read the rest of buffers
	cout_callback[cout_buf] if cout_buf.length > 0
	cerr_callback[cerr_buf] if cerr_buf.length > 0

	return retcode
end

# Returns logging for this node
def ulog(_)
	if defined? Logging && Logging.in_LDV?
		Logging.logger['Node']
	else
		LDV::Logging.generic('system')
	end
end

# Print command line arguments in a copy-paste friendly way
def runspect(args)
	"[ #{args.map {|a| a.inspect}.join(" ")} ]"
end

# Say_and_run that uses open3 to write proper logs
def say_and_run(*args_)
	args = args_.flatten
	if Hash === args.last
		opts = args.pop
	else
		opts = {}
	end
	# FIXME : set up logger in a more documented way
	lgr = ulog('Node')
	lgr.debug "Running #{runspect args}"
	if opts[:no_capture_stderr]
		cerr_handler = proc { |line| }
	else
		cerr_handler = proc do |line|
			lgr.error line.chomp
		end
	end
	# Do not capture stdout if we're told not to
	if opts[:no_capture_stdout]
		cout_handler = proc { |line| }
	else
		cout_handler = proc do |line|
			lgr.info line.chomp
		end
	end

	open3_linewise(cout_handler,cerr_handler,*args)
end

# Run and log information to the logger supplied
def run_and_log(logger,*args_)
	args = args_.flatten
	logger.info "Running: #{args.inspect}"
	# Error handler reads from stderr stream of the process spawned.  LDV tools (hopefully) write information about their work there in the following format:
	#   tool: SEVERITY: message
	#   tool: SEVERITY: message
	#
	# etc.  Messages that don't comply are treated as errors by default.
	# We strip severity from these messages and print them to our logger with the same severity.
	cerr_handler = proc do |line|
		if md = /([^:]*):\s*([A-Z]*): (.*)/.match(line)
			severity = md[2].downcase
			fixed_line = "#{md[1]}: #{md[3]}"
			logger.send(severity,fixed_line)
		else
			# It's a strange line, print as error
			logger.error line.chomp
		end
	end
	cout_handler = proc do |line|
		if md = /([^:]*):\s*([A-Z]*): (.*)/.match(line)
			severity = md[2].downcase
			if logger.respond_to? severity
				fixed_line = "#{md[1]}: #{md[3]}"
				logger.send(severity,fixed_line)
				return
			else
				# Unknown severity; perhaps, this line is not about logging?
				# print it as an error in this case
				logger.error line.chomp
			end
		end

		# It's a strange line, print as error
		logger.error line.chomp
	end

	retcode = open3_linewise(cout_handler,cerr_handler,*args)

	logger.debug "Finished #{args.inspect} with code #{retcode}"

	retcode
end

# Sometimes open3 version of say_and_run doesn't work (because child doesn't close handlers, for instance).  This version won't log output, but will work, at least
def say_and_run_FIXME(*_args)
	args = _args.flatten
	$stderr.puts "Running: #{args.inspect}"
	Kernel.system *args
end

def say_and_exec(*args)
	Logging.logger['Node'].debug "Running (exec): #{args.inspect}"
	Kernel.exec *args
end

def say_and_open3(*args)
	$stderr.write "Running: #{args.inspect}\n"
	Open3.popen3(*args) do |a,b,c|
		yield a,b,c
	end
end

