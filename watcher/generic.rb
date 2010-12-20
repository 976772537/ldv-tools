
class Watcher
	
	attr_accessor :config

	DEFAULT_OPTS = {
		:max_rcv_pool => 1,
		:max_dscv_pool => 1,
		:block_queue => nil
	}

	def initialize(opts = {})
		@config = DEFAULT_OPTS.merge opts
		@config[:max_rcv_pool] = (ENV['LDV_MAX_RCVS'].to_i || 1)
		@config[:max_rcv_pool] = 1 if @config[:max_rcv_pool] < 1
		@config[:max_dscv_pool] = (ENV['LDV_MAX_DSCVS'].to_i || 1)
		@config[:max_dscv_pool] = 1 if @config[:max_dscv_pool] < 1
		# Whether we block queue call until the task is finished
		@config[:block_queue] = @config[:max_rcv_pool] == 1 if @config[:block_queue].nil?
	end

end

