require 'active_record'

def ldv_db_connect
	ActiveRecord::Base.establish_connection(
		:adapter  => 'mysql',
		:database => ENV['LDVDB'],
		:username => ENV['LDVUSER'],
		:password => ENV['LDVDBPASSWD'],
		:host     => (ENV['LDVDBHOST'] || 'localhost')
	)
	ActiveRecord::Base.logger = Logger.new(STDERR)

	# Return collection object
	ActiveRecord::Base.connection()
end

## Convenience functions for REXML
class REXML::Element
	# Get text of the first element statisfying xpath
	def field(xpath)
		if tag = elements[xpath]
			tag.text
		else
			nil
		end
	end
	alias_method :/, :field
end

## Convenience functions for ActiveRecord
class ActiveRecord::Base
	def self.find_or_create(attributes)
		self.first(:conditions => attributes) || self.create(attributes)
	end
end


