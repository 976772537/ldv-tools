require 'socket'
require 'utils/logging.rb'

# SSH parameters (for all options)
def ssh_opts
	["-o","StrictHostKeyChecking=no"]
end

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
require 'enhanced_open3'
require 'open3'

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
	lgr.trace "PATH=#{ENV['PATH']}"
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

	EnhancedOpen3.open3_linewise(nil,cout_handler,cerr_handler,*args)
end

# Run and log information to the logger supplied
def run_and_log(logger,*args_)
	args = args_.flatten
	logger.trace "PATH=#{ENV['PATH']}"
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
			else
				# Unknown severity; perhaps, this line is not about logging?
				# print it as an error in this case
				logger.error line.chomp
			end
		else
			# It's a strange line, print as error
			logger.error line.chomp
		end
	end

	retcode = EnhancedOpen3.open3_linewise(nil,cout_handler,cerr_handler,*args)

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

