# Backport of the ruby 1.9's open3 to 1.8

module MyOpen3

	# Aside from a usual stuff, you may specify a :fork_callback option
	def popen3(*cmd, &block)
		if Hash === cmd.last
			opts = cmd.pop.dup
		else
			opts = {}
		end

		in_r, in_w = IO.pipe
		opts[:in] = in_r
		in_w.sync = true

		out_r, out_w = IO.pipe
		opts[:out] = out_w

		err_r, err_w = IO.pipe
		opts[:err] = err_w

		popen_run(cmd, opts, [in_r, out_w, err_w], [in_w, out_r, err_r], &block)
	end
	module_function :popen3

	def popen_run(cmd, opts, child_io, parent_io) # :nodoc:
		# Backport: merge opts and cmd
		cmop = cmd.dup.push opts 
		pid = fork{
			# Since we inherited all filehandlers, we should close those that belong to the parent
			parent_io.each {|io| io.close}
			# child
			STDIN.reopen(opts[:in])
			STDOUT.reopen(opts[:out])
			STDERR.reopen(opts[:err])

			opts[:fork_callback].call if opts[:fork_callback]

			exec(*cmd)
		}
		wait_thr = Process.detach(pid)
		# Save PID in thread to comply to Ruby1.9-like api.  Crazy, huh?
		wait_thr[:pid]=pid
		child_io.each {|io| io.close }
		result = parent_io.dup.push wait_thr
		if defined? yield
			begin
				return yield(*result)
			ensure
				parent_io.each{|io| io.close unless io.closed?}
				wait_thr.join
			end
		end
		result
	end
	module_function :popen_run
	class << self
		private :popen_run
	end

end
