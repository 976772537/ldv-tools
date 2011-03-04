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
		# If the End-Of-File is reached on some of the streams, then the process might have already ended
		while !cout.eof? || !cerr.eof?
			r = select([cout,cerr],nil,nil,10)
			#puts r.inspect
			if r[0].include? cerr
				begin
					cerr_callback[pid,cerr]
				rescue EOFError
					#did_eof = true
				end
			end
			if r[0].include? cout
				begin
					cout_callback[pid,cout]
				rescue EOFError
					#did_eof = true
				end
			end
		end
		# FIXME: in stupid Ruby 1.8 we can't get exit status of the process... shit.
		code = thr.value
	end
	# Return code, either nil if something bad happened, or the actual return code if we were successful
	return code
end

def say_and_run(*args_)
	args = args_.flatten
	# FIXME : set up logger in a more documented way
	lgr = Logging.logger['Node']
	lgr.debug "Running: #{args.inspect}"
	cerr_handler = proc do |pid,cerr|
		line = cerr.readline
		lgr.debug line.chomp
	end
	cout_handler = proc do |pid,cout|
	  lgr.info cout.readline.chomp
	end

	retcode = open3_callbacks(cout_handler,cerr_handler,*args)
	retcode
end

# Run and log information to the logger supplied
def run_and_log(logger,*args_)
	args = args_.flatten
	logger.info "Running: #{args.inspect}"
	cerr_handler = proc do |pid,cerr|
		line = cerr.readline
	  logger.debug line.chomp
	end
	cout_handler = proc do |pid,cout|
	  logger.info cout.readline.chomp
	end

	retcode = open3_callbacks(cout_handler,cerr_handler,*args)

	logger.info "Finished with code #{retcode}"

	retcode
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

