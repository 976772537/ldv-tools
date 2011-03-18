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

# Open a stream with open3, and invoke a callback when a stream is ready for reading (but may be in EOF mode).  Waits till the process terminates, and returns its error code.
def open3_callbacks(cout_callback, cerr_callback, *args)
	code = nil
	MyOpen3.popen3(*args) do |cin,cout,cerr,thr|
		pid = thr[:pid]
		# Close input at once, as we don't use it
		cin.close_write
		# If the End-Of-File is reached on all of the streams, then the process might have already ended
		non_eof_streams = [cerr,cout]
		while non_eof_streams.length > 0
			timeout = 2
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
			#puts r.inspect
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
		code = thr.value
	end
	# Return code, either nil if something bad happened, or the actual return code if we were successful
	return code
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
	lgr = Logging.logger['Node']
	lgr.debug "Running: #{args.inspect}"
	if opts[:no_capture_stderr]
		cerr_handler = proc do |pid,cerr|
			# We should reap the contents of a stream anyway, or we'll loop forever
			cerr.readline
		end
	else
		cerr_handler = proc do |pid,cerr|
			line = cerr.readline
			lgr.debug line.chomp
		end
	end
	# Do not capture stdout if we're told not to
	if opts[:no_capture_stdout]
		cout_handler = proc do |pid,cout|
			# We should reap the contents of a stream anyway, or we'll loop forever
			cout.readline
		end
	else
		cout_handler = proc do |pid,cout|
			lgr.info cout.readline.chomp
		end
	end

	retcode = open3_callbacks(cout_handler,cerr_handler,*args)
	retcode
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
	cerr_handler = proc do |pid,cerr|
		line = cerr.readline.chomp
		if md = /([^:].*): ([A-Z]*): (.*)/.match(line)
			severity = md[2].downcase
			fixed_line = "#{md[1]}: #{md[3]}"
			logger.send(severity,fixed_line)
		else
			# It's a strange line, print as error
			logger.error line.chomp
		end
	end
	# Some tools in LDV print something to STDOUT.  This includes ldv-manager (wich is, essentially, makefile) and, perhaps, other tools.  We assign "Info" severity to these messages
	cout_handler = proc do |pid,cout|
		#logger.info cout.readline.chomp
		line = cout.readline
		if md = /([^:].*): ([A-Z]*): (.*)/.match(line)
			severity = md[2].downcase
			if Logging::Levels.include? severity
				fixed_line = "#{md[1]}: #{md[3]}"
				logger.send(severity,fixed_line)
				return
			end
			# Unknown severity; perhaps, this line is not about logging?
		end

		# It's a strange line, print as error
		logger.error line.chomp
	end
	#cerr_handler = proc do |pid,cerr|
		#line = cerr.readline
		#logger.debug line.chomp
	#end
	#cout_handler = proc do |pid,cout|
		#logger.info cout.readline.chomp
	#end

	retcode = open3_callbacks(cout_handler,cerr_handler,*args)

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

