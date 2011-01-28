require 'socket'

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


