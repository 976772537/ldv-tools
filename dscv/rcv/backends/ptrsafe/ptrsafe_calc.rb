#!/usr/bin/ruby
require 'rubygems'
require 'active_record'
require 'optparse'

ENV['LDV_SRVHOME'] ||= File.expand_path("../../../../../",File.dirname(__FILE__))
manhome = File.join(ENV['LDV_SRVHOME'],"ldv-manager")
$:.unshift File.join(ENV['LDV_SRVHOME'],'shared','ruby','lib')

require File.join(manhome,"upload_utils.rb")
ldv_db_connect
# We should connect before we load our data model
require File.join(manhome,"results_model.rb")

class Ptr < ActiveRecord::Base
	has_and_belongs_to_many :launches, :uniq => true
end

class Launch < ActiveRecord::Base
	has_and_belongs_to_many :ptrs, :uniq => true
end

puts Launch.all.length

our_launches = Launch.all
our_launches.each do |l|
	next unless rcv = l.trace.rcv
	desc = rcv.description
	desc.split("\n").each do |line|
		if md = /(.*):(.*): Bad one: (.*)/.match(line)
			fname,line,expr = md[1],md[2],md[3]
			# Remove trash (heuristics)
			fname.gsub!(/.*\/drivers\//,'drivers/')
			fname.gsub!(/.common.c/,'')
			# Remove casts CIL adds
			expr.gsub!(/\(unsigned long \)/,'')
			puts "Found: #{line}"
			ptr = Ptr.find_or_create_by_fname_and_line_and_expr(fname,line,expr)
			l.ptrs << ptr unless l.ptrs.include? ptr
		end
	end
end

