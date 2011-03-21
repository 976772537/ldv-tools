# Infrastructure for LDV logging.
# Info about logging levels and initscript for a sample logger
#
require 'rubygems'
require 'logging'

module LDV
	module Logging
 		LEVELS = %w(trace debug info normal warn error fatal)

		LEVELS_MAP = {
			0   => :quiet,
			4   => :warn,
			10  => :normal,
			20  => :info,
			30  => :debug,
			40  => :trace,
			100 => :all
		}

		@@inited = false
		# Generic logger for printing to STDERR
		# FIXME: Doesn't support tool folding
		def generic(tool)
			# Init LDV-specific logging levels
			::Logging.init(LEVELS.map{|l| l.to_sym}) unless @@inited
			# Suppress warning about re-initialization of constant
			@@inited = true

			# Create the logger
			lgr = ::Logging.logger(STDERR, :pattern => "#{tool}: %5l: %m\n")
			# Set its level
			user_set_level = (ENV['LDV_DEBUG'] || '10').to_i
			lgr.level = LEVELS_MAP[LEVELS_MAP.keys.select{|l| l <= user_set_level}.max]

			return lgr
		end
		module_function :generic
	end
end

