
# Equivalent to a header guard in C/C++
# Used to prevent the class/module from being loaded more than once
unless defined? Logging

require File.expand_path('../logging/utils', __FILE__)

require 'yaml'
require 'stringio'
require 'fileutils'
require 'little-plugger'

HAVE_SYSLOG = require? 'syslog'

#
#
module Logging
  extend LittlePlugger

  # :stopdoc:
  LIBPATH = ::File.expand_path('..', __FILE__) + ::File::SEPARATOR
  PATH = ::File.expand_path('../..', __FILE__) + ::File::SEPARATOR
  LEVELS = {}
  LNAMES = []
  module Plugins; end
  # :startdoc:

  class << self

    # call-seq:
    #    Logging.configure( filename )
    #    Logging.configure { block }
    #
    # Configures the Logging framework using the configuration information
    # found in the given file. The file extension should be either '.yaml'
    # or '.yml' (XML configuration is not yet supported).
    #
    def configure( *args, &block )
      if block
        return ::Logging::Config::Configurator.process(&block)
      end

      filename = args.shift
      raise ArgumentError, 'a filename was not given' if filename.nil?

      case File.extname(filename)
      when '.yaml', '.yml'
        ::Logging::Config::YamlConfigurator.load(filename, *args)
      else raise ArgumentError, 'unknown configuration file format' end
    end

    # call-seq:
    #    Logging.logger( device, age = 7, size = 1048576 )
    #    Logging.logger( device, age = 'weekly' )
    #
    # This convenience method returns a Logger instance configured to behave
    # similarly to a core Ruby Logger instance.
    #
    # The _device_ is the logging destination. This can be a filename
    # (String) or an IO object (STDERR, STDOUT, an open File, etc.). The
    # _age_ is the number of old log files to keep or the frequency of
    # rotation (+daily+, +weekly+, or +monthly+). The _size_ is the maximum
    # logfile size and is only used when _age_ is a number.
    #
    # Using the same _device_ twice will result in the same Logger instance
    # being returned. For example, if a Logger is created using STDOUT then
    # the same Logger instance will be returned the next time STDOUT is
    # used. A new Logger instance can be obtained by closing the previous
    # logger instance.
    #
    #    log1 = Logging.logger(STDOUT)
    #    log2 = Logging.logger(STDOUT)
    #    log1.object_id == log2.object_id  #=> true
    #
    #    log1.close
    #    log2 = Logging.logger(STDOUT)
    #    log1.object_id == log2.object_id  #=> false
    #
    # The format of the log messages can be changed using a few optional
    # parameters. The <tt>:pattern</tt> can be used to change the log
    # message format. The <tt>:date_pattern</tt> can be used to change how
    # timestamps are formatted.
    #
    #    log = Logging.logger(STDOUT,
    #              :pattern => "[%d] %-5l : %m\n",
    #              :date_pattern => "%Y-%m-%d %H:%M:%S.%s")
    #
    # See the documentation for the Logging::Layouts::Pattern class for a
    # full description of the :pattern and :date_pattern formatting strings.
    #
    def logger( *args )
      return ::Logging::Logger if args.empty?

      opts = args.pop if args.last.instance_of?(Hash)
      opts ||= Hash.new

      dev = args.shift
      keep = age = args.shift
      size = args.shift

      name = case dev
             when String; dev
             when File; dev.path
             else dev.object_id.to_s end

      repo = ::Logging::Repository.instance
      return repo[name] if repo.has_logger? name

      l_opts = {
        :pattern => "%.1l, [%d #%p] %#{::Logging::MAX_LEVEL_LENGTH}l : %m\n",
        :date_pattern => '%Y-%m-%dT%H:%M:%S.%s'
      }
      [:pattern, :date_pattern, :date_method].each do |o|
        l_opts[o] = opts.delete(o) if opts.has_key? o
      end
      layout = ::Logging::Layouts::Pattern.new(l_opts)

      a_opts = Hash.new
      a_opts[:size] = size if size.instance_of?(Fixnum)
      a_opts[:age]  = age  if age.instance_of?(String)
      a_opts[:keep] = keep if keep.instance_of?(Fixnum)
      a_opts[:filename] = dev if dev.instance_of?(String)
      a_opts[:layout] = layout
      a_opts.merge! opts

      appender =
          case dev
          when String
            ::Logging::Appenders::RollingFile.new(name, a_opts)
          else
            ::Logging::Appenders::IO.new(name, dev, a_opts)
          end

      logger = ::Logging::Logger.new(name)
      logger.add_appenders appender
      logger.additive = false

      class << logger
        def close
          @appenders.each {|a| a.close}
          h = ::Logging::Repository.instance.instance_variable_get :@h
          h.delete(@name)
          class << self; undef :close; end
        end
      end

      logger
    end

    # Access to the layouts.
    #
    def layouts
      ::Logging::Layouts
    end

    # Access to the appenders.
    #
    def appenders
      ::Logging::Appenders
    end

    # Reopen all appenders. This method should be called immediately after a
    # fork to ensure no conflict with file descriptors and calls to fcntl or
    # flock.
    #
    def reopen
      log_internal {'re-opening all appenders'}
      ::Logging::Appenders.each {|appender| appender.reopen}
    end

    # call-seq:
    #    Logging.consolidate( 'First::Name', 'Second::Name', ... )
    #
    # Consolidate all loggers under the given namespace. All child loggers
    # in the namespace will use the "consolidated" namespace logger instead
    # of creating a new logger for each class or module.
    #
    # If the "root" logger name is passed to this method then all loggers
    # will consolidate to the root logger. In other words, only the root
    # logger will be created, and it will be used by all classes and moduels
    # in the applicaiton.
    #
    # ==== Example
    #
    #    Logging.consolidate( 'Foo' )
    #
    #    foo = Logging.logger['Foo']
    #    bar = Logging.logger['Foo::Bar']
    #    baz = Logging.logger['Baz']
    #
    #    foo.object_id == bar.object_id    #=> true
    #    foo.object_id == baz.object_id    #=> false
    #
    def consolidate( *args )
      ::Logging::Repository.instance.add_master(*args)
    end

    # call-seq:
    #    include Logging.globally
    #    include Logging.globally( :logger )
    #
    # Add a "logger" method to the including context. If included from
    # Object or Kernel, the logger method will be available to all objects.
    #
    # Optionally, a method name can be given and that will be used to
    # provided access to the logger:
    #
    #    include Logging.globally( :log )
    #    log.info "Just using a shorter method name"
    #
    # If you prefer to use the shorter "log" to access the logger.
    #
    # ==== Example
    #
    #   include Logging.globally
    #
    #   class Foo
    #     logger.debug "Loading the Foo class"
    #     def initialize
    #       logger.info "Creating some new foo"
    #     end
    #   end
    #
    #   logger.fatal "End of example"
    #
    def globally( name = :logger )
      Module.new {
        eval "def #{name}() @_logging_logger ||= ::Logging::Logger[self] end"
      }
    end

    # call-seq:
    #    Logging.init( levels )
    #
    # Defines the levels available to the loggers. The _levels_ is an array
    # of strings and symbols. Each element in the array is downcased and
    # converted to a symbol; these symbols are used to create the logging
    # methods in the loggers.
    #
    # The first element in the array is the lowest logging level. Setting the
    # logging level to this value will enable all log messages. The last
    # element in the array is the highest logging level. Setting the logging
    # level to this value will disable all log messages except this highest
    # level.
    #
    # This method should only be invoked once to configure the logging
    # levels. It is automatically invoked with the default logging levels
    # when the first logger is created.
    #
    # The levels "all" and "off" are reserved and will be ignored if passed
    # to this method.
    #
    # Example:
    #
    #    Logging.init :debug, :info, :warn, :error, :fatal
    #    log = Logging::Logger['my logger']
    #    log.level = :warn
    #    log.warn 'Danger! Danger! Will Robinson'
    #    log.info 'Just FYI'                        # => not logged
    #
    # or
    #
    #    Logging.init %w(DEBUG INFO NOTICE WARNING ERR CRIT ALERT EMERG)
    #    log = Logging::Logger['syslog']
    #    log.level = :notice
    #    log.warning 'This is your first warning'
    #    log.info 'Just FYI'                        # => not logged
    #
    def init( *args )
      args = %w(debug info warn error fatal) if args.empty?

      args.flatten!
      levels = LEVELS.clear
      names = LNAMES.clear

      id = 0
      args.each do |lvl|
        lvl = levelify lvl
        unless levels.has_key?(lvl) or lvl == 'all' or lvl == 'off'
          levels[lvl] = id
          names[id] = lvl.upcase
          id += 1
        end
      end

      longest = names.inject {|x,y| (x.length > y.length) ? x : y}
      longest = 'off' if longest.length < 3
      module_eval "MAX_LEVEL_LENGTH = #{longest.length}", __FILE__, __LINE__

      initialize_plugins

      levels.keys
    end

    # call-seq:
    #    Logging.format_as( obj_format )
    #
    # Defines the default _obj_format_ method to use when converting objects
    # into string representations for logging. _obj_format_ can be one of
    # <tt>:string</tt>, <tt>:inspect</tt>, or <tt>:yaml</tt>. These
    # formatting commands map to the following object methods
    #
    # * :string  => to_s
    # * :inspect => inspect
    # * :yaml    => to_yaml
    #
    # An +ArgumentError+ is raised if anything other than +:string+,
    # +:inspect+, +:yaml+ is passed to this method.
    #
    def format_as( f )
      f = f.intern if f.instance_of? String

      unless [:string, :inspect, :yaml].include? f
        raise ArgumentError, "unknown object format '#{f}'"
      end

      module_eval "OBJ_FORMAT = :#{f}", __FILE__, __LINE__
    end

    # call-seq:
    #    Logging.backtrace             #=> true or false
    #    Logging.backtrace( value )    #=> true or false
    #
    # Without any arguments, returns the global exception backtrace logging
    # value. When set to +true+ backtraces will be written to the logs; when
    # set to +false+ backtraces will be suppressed.
    #
    # When an argument is given the global exception backtrace setting will
    # be changed. Value values are <tt>"on"</tt>, <tt>:on<tt> and +true+ to
    # turn on backtraces and <tt>"off"</tt>, <tt>:off</tt> and +false+ to
    # turn off backtraces.
    #
    def backtrace( b = nil )
      @backtrace = true unless defined? @backtrace
      return @backtrace if b.nil?

      @backtrace = case b
          when :on, 'on', true;    true
          when :off, 'off', false; false
          else
            raise ArgumentError, "backtrace must be true or false"
          end
    end

    # Returns the version string for the library.
    #
    def version
      @version ||= File.read(path('version.txt')).strip
    end

    # Returns the library path for the module. If any arguments are given,
    # they will be joined to the end of the libray path using
    # <tt>File.join</tt>.
    #
    def libpath( *args, &block )
      rv = args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)
      if block
        begin
          $LOAD_PATH.unshift LIBPATH
          rv = block.call
        ensure
          $LOAD_PATH.shift
        end
      end
      return rv
    end

    # Returns the lpath for the module. If any arguments are given,
    # they will be joined to the end of the path using
    # <tt>File.join</tt>.
    #
    def path( *args, &block )
      rv = args.empty? ? PATH : ::File.join(PATH, args.flatten)
      if block
        begin
          $LOAD_PATH.unshift PATH
          rv = block.call
        ensure
          $LOAD_PATH.shift
        end
      end
      return rv
    end

    # call-seq:
    #    show_configuration( io = STDOUT, logger = 'root' )
    #
    # This method is used to show the configuration of the logging
    # framework. The information is written to the given _io_ stream
    # (defaulting to stdout). Normally the configuration is dumped starting
    # with the root logger, but any logger name can be given.
    #
    # Each line contains information for a single logger and it's appenders.
    # A child logger is indented two spaces from it's parent logger. Each
    # line contains the logger name, level, additivity, and trace settings.
    # Here is a brief example:
    #
    #    root  ...........................   *info      -T
    #      LoggerA  ......................    info  +A  -T
    #        LoggerA::LoggerB  ...........    info  +A  -T
    #        LoggerA::LoggerC  ...........  *debug  +A  -T
    #      LoggerD  ......................   *warn  -A  +T
    #
    # The lines can be deciphered as follows:
    #
    #    1) name       - the name of the logger
    #
    #    2) level      - the logger level; if it is preceeded by an
    #                    asterisk then the level was explicitly set for that
    #                    logger (as opposed to being inherited from the parent
    #                    logger)
    #
    #    3) additivity - a "+A" shows the logger is additive, and log events
    #                    will be passed up to the parent logger; "-A" shows
    #                    that the logger will *not* pass log events up to the
    #                    parent logger
    #
    #    4) trace      - a "+T" shows that the logger will include trace
    #                    information in generated log events (this includes
    #                    filename and line number of the log message; "-T"
    #                    shows that the logger does not include trace
    #                    information in the log events)
    #
    # If a logger has appenders then they are listed, one per line,
    # immediately below the logger. Appender lines are pre-pended with a
    # single dash:
    #
    #    root  ...........................   *info      -T
    #    - <Appenders::Stdout:0x8b02a4 name="stdout">
    #      LoggerA  ......................    info  +A  -T
    #        LoggerA::LoggerB  ...........    info  +A  -T
    #        LoggerA::LoggerC  ...........  *debug  +A  -T
    #      LoggerD  ......................   *warn  -A  +T
    #      - <Appenders::Stderr:0x8b04ca name="stderr">
    #
    # We can see in this configuration dump that all the loggers will append
    # to stdout via the Stdout appender configured in the root logger. All
    # the loggers are additive, and so their generated log events will be
    # passed up to the root logger.
    #
    # The exception in this configuration is LoggerD. Its additivity is set
    # to false. It uses its own appender to send messages to stderr.
    #
    def show_configuration( io = STDOUT, logger = 'root', indent = 0 )
      logger = ::Logging::Logger[logger] unless ::Logging::Logger === logger

      logger._dump_configuration(io, indent)

      indent += 2
      children = ::Logging::Repository.instance.children(logger.name)
      children.sort {|a,b| a.name <=> b.name}.each do |child|
        ::Logging.show_configuration(io, child, indent)
      end

      nil
    end

    # :stopdoc:
    # Convert the given level into a connaconical form - a lowercase string.
    def levelify( level )
      case level
      when String; level.downcase
      when Symbol; level.to_s.downcase
      else raise ArgumentError, "levels must be a String or Symbol" end
    end

    # Convert the given level into a level number.
    def level_num( level )
      l = levelify level
      case l
      when 'all'; 0
      when 'off'; LEVELS.length
      else begin; Integer(l); rescue ArgumentError; LEVELS[l] end end
    end

    # Internal logging method for use by the framework.
    def log_internal( level = 1, &block )
      ::Logging::Logger[::Logging].__send__(levelify(LNAMES[level]), &block)
    end

    # Close all appenders
    def shutdown
      log_internal {'shutdown called - closing all appenders'}
      ::Logging::Appenders.each {|appender| appender.close}
    end

    # Reset the logging framework to it's uninitialized state
    def reset
      ::Logging::Repository.reset
      ::Logging::Appenders.reset
      LEVELS.clear
      LNAMES.clear
      remove_instance_variable :@backtrace if defined? @backtrace
      remove_const :MAX_LEVEL_LENGTH if const_defined? :MAX_LEVEL_LENGTH
      remove_const :OBJ_FORMAT if const_defined? :OBJ_FORMAT
    end
    # :startdoc:
  end
end  # module Logging


Logging.libpath {
  require 'logging/appender'
  require 'logging/layout'
  require 'logging/log_event'
  require 'logging/logger'
  require 'logging/repository'
  require 'logging/root_logger'
  require 'logging/stats'
  require 'logging/appenders'
  require 'logging/layouts'
  require 'logging/proxy'

  require 'logging/config/configurator'
  require 'logging/config/yaml_configurator'
}


# This exit handler will close all the appenders that exist in the system.
# This is needed for closing IO streams and connections to the syslog server
# or e-mail servers, etc.
#
at_exit {Logging.shutdown}

end  # unless defined?

# EOF
