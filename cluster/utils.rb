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
	$stderr.puts "LOCAL IP of #{ip}: #{route_ip}"
	result = (route_ip =~ /^127\./) || (route_ip == 'localhost') || (route_ip == ENV['LDV_LOCAL_IP'])
	$stderr.puts "LOCAL IP of #{ip}? #{result}"
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


# Program run helpers

def say_and_run(*args_)
	args = args_.flatten
	$stderr.write "Running: #{args.inspect}\n"
	Kernel.system *args
end

def say_and_exec(*args)
	$stderr.write "Running (exec): #{args.inspect}\n"
	Kernel.exec *args
end

require 'open3'
def say_and_open3(*args)
	$stderr.write "Running: #{args.inspect}\n"
	Open3.popen3(*args) do |a,b,c|
		yield a,b,c
	end
end

