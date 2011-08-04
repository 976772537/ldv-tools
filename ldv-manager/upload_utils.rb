require 'active_record'
require 'logger'

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

def ldv_report_link
	verifiers_add = ENV['RCV_VERIFIER'] ? 'profilename/rcv/' : ''
  "http://localhost:8999/stats/index/#{verifiers_add}name/#{ENV['LDVDB']}/host/#{(ENV['LDVDBHOST'] || 'localhost')}/user/#{ENV['LDVUSER']}/password/#{ENV['LDVDBPASSWD'] || 'no'}"
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

## Porting from REXML to LibXML stream parser
def ass
	raise "Assertion failed!" unless yield
end
def asseq(a,b)
	raise "Assertion failed: #{a.inspect} != #{b.inspect}!" unless a == b
end
def stats p
	$stderr.puts sprintf("%d %d %p %p %p",p.depth,p.node_type,p.name,p.empty_element?,p.value) if $debug
end
# monkey-patch xml nodes for compatibility
require 'xml'
class LibXML::XML::Reader
	# Make default read to print debug information and ignore whitespace
	alias_method :super_read, :read
	# Ignore whitespace and print stats
	def skipping_read
		super_read
		raw_read_whitespace
		# Print stats
		stats self
	end
	alias_method :read, :skipping_read

	def raw_read_whitespace
		while node_type == TYPE_WHITESPACE || node_type == TYPE_SIGNIFICANT_WHITESPACE
			# Read one more
			super_read
		end
	end

	# If the peeked data is whitespace, read until we encounter a meaningful tag
	def read_whitespace
		raw_read_whitespace
		# Print stats
		stats self
	end

	alias_method :super_next, :next
	def skipping_next
		self.super_next
		self.read_whitespace
	end
	alias_method :next, :skipping_next

	# Returns if this stream points to an end of a tag
	def end_of? tag
		node_type == XML::Reader::TYPE_END_ELEMENT && name == tag
	end

	# Returns if this stream points to a start of a tag
	def start_of? tag
		node_type == XML::Reader::TYPE_ELEMENT && name == tag
	end

	# If current node is a start of one of these tags, returns its name; otherwise, returns nil
	def start_of_these? *tags
		return nil if node_type != XML::Reader::TYPE_ELEMENT
		tags.flatten.index(name) ? name : nil
	end

	# Returns XML::Node of the current tag and reads up to the end of it.
	def consume
		# We copy the element recursively to remove LibXML's ownership from it, and so that it is available after the reader is advanced
		# See: https://github.com/xml4r/libxml-ruby/issues/28
		node = self.expand.copy(true)
		new_doc = XML::Document.new
		new_doc.root = node
		self.skipping_next
		node
	end

	# Consumes the content of the tag peeked, the tag is expected in form <tag>content</tag>
	def consume_contents
		was_empty = empty_element?
		read
		return nil if was_empty
		# If there was no text (but the element is not empty, e.g. <a></a>), then don't read twice
		if node_type != XML::Reader::TYPE_END_ELEMENT
			r = value
			read
		else
			r = ''
		end
		read
		r
	end
end

class LibXML::XML::Node
	# Get text of the first element statisfying xpath
	def field(xpath)
		if tag = find_first(xpath)
			tag.content
		else
			nil
		end
	end
	alias_method :/, :field
	# Get elements that match xpath, as a list
	def elements(xpath)
		find xpath
	end
	# Get first element that matches xpath, or nil if none do
	def element(xpath)
		find_first xpath
	end
end


