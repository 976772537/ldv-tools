
class Environment < ActiveRecord::Base
end

class Driver < ActiveRecord::Base
end

class Rule_Model < ActiveRecord::Base
end

class Toolset < ActiveRecord::Base
end

class Scenario < ActiveRecord::Base
	belongs_to :driver
end

class Launch < ActiveRecord::Base
	belongs_to :driver, :autosave => true
	belongs_to :toolset, :autosave => true
	belongs_to :environment, :autosave => true
	belongs_to :rule_model, :class_name=>'Rule_Model', :autosave => true
	belongs_to :scenario, :autosave => true

	validates_associated :driver, :toolset, :environment, :rule_model, :scenario

	# Loads existing record if there exists one with the same primary key
	def load_on_duplicate_key
		if record = Launch.find_by_driver_id_and_toolset_id_and_environment_id_and_rule_model_id_and_scenario_id_and_task_id(driver,toolset,environment,rule_model,scenario,task)
			record
		else
			self
		end
	end

	belongs_to :task, :autosave => true
	belongs_to :trace, :autosave => true
	validates_associated :task, :trace

	validate :trace_vs_status

	# Check that trace is here iff result is 'finished'
	def trace_vs_status
		!trace.nil? && status == 'finished'
	end
end

class Task < ActiveRecord::Base
end

# We have to create a class named Processe, because "Process" is a name of a standard Ruby module >_<
class Processe < ActiveRecord::Base
	belongs_to :trace
end

class Trace < ActiveRecord::Base
	has_one :launch

	belongs_to :build, :class_name => 'Stats', :autosave => true
	belongs_to :maingen, :class_name => 'Stats', :autosave => true
	belongs_to :dscv, :class_name => 'Stats', :autosave => true
	belongs_to :ri, :class_name => 'Stats', :autosave => true
	belongs_to :rcv, :class_name => 'Stats', :autosave => true

	has_many :sources, :autosave => true, :uniq => true
	has_many :processe, :autosave => true

	#Tool nicknames -> XML names
	def self.tools ; {
		'build' => 'build',
		'maingen' => 'drv-env-gen',
		'dscv' => 'dscv',
		'ri' => 'rule-instrumentor',
		'rcv' => 'rcv',
	}
	end

	# Validate that whether tools worked is OK (i.e. if maingenerator fails then all other tools should fail too).
	validate do |trace|
		 valid_sequence = [:build,:maingen,:dscv,:ri,:rcv]
		 # Let's get pairs of tools to verify
		 shift_seq = [nil] + valid_sequence
		 pairs = shift_seq.zip(valid_sequence)[1..-2]

		 # The following chains are forbidden: failed->ok and failed->nil
		 pairs.each do |pre,post|
			  pre_success,post_success = [pre,post].map{|x|  !trace.send(x).nil? && trace.send(x).success? }
			  trace.errors.add post,"is ok, but the calling tool, #{pre.to_s}, failed!" if !pre_success && post_success
		 end
	end

	# MySQL doesn't enforce constraints on ENUM.  So we need a separate validation.
	validates_format_of :result, :with => /safe|unsafe|unknown/, :on => :save
end

class Stats < ActiveRecord::Base
	has_and_belongs_to_many :problems, :uniq => true

	# Calculate and apply problems for this trace
	def calc_problems(scripts_dir)
		# Ruby 1.9 doesn't want nonexisting paths in Find.find!
		return nil unless FileTest.exists? scripts_dir
		Find.find(scripts_dir) do |file|
			if !FileTest.directory?(file) && FileTest.executable?(file)
				# Run the script and get its output
				Open3.popen3(file) do |cin,cout,cerr|
					# Send description to the checker
					cin.write( description )
					cin.close
					# This should be very sumple, but somehow has_and_belongs_to_many :uniq doesn't work! O_o
					cout.each {|line| p = Problem.find_or_create_by_name(line.chomp); problems << p unless problems.include? p }
					cerr.each {|errln| $stderr.puts errln}
				end
			end
		end
	end

	# 0 - ???, 1 - detailed, 2 - average
	def self.split_time timestr
		timestr.split(':')
	end
end

class Source < ActiveRecord::Base
	validates_uniqueness_of :name, :scope => :trace_id
	belongs_to :trace
end

class Problem < ActiveRecord::Base
	has_and_belongs_to_many :stats, :uniq => true

	# Removes all associations between problems and Stats
	def self.clear_all(sql)
		sql.execute('DELETE FROM problems_stats')
	end
end

