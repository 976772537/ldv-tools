register Ldvnode.new

# Disclose ping_time
self.registry.actors['ldvnode'].ping_time = lambda { self.options[:ping_time].to_i }

# Status of the current Agent is the status of its Ldvnode actor
self.status_proc = lambda {
	self.registry.actors['ldvnode'].status_for_cluster
}
