# Base appender
#
#   Abstract base class for appenders
#
#   Implements common behavior such as default text formatter etc
#
#   Note: Do not create instances of this class directly
#
module SemanticLogger
  module Appender
    class Base < SemanticLogger::Base
      attr_accessor :formatter

      # Default log formatter
      #  Replace this formatter by supplying a Block to the initializer
      #  Generates logs of the form:
      #    2011-07-19 14:36:15.660 D [1149:ScriptThreadProcess] Rails -- Hello World
      def default_formatter
        Proc.new do |log|
          tags = log.tags.collect { |tag| "[#{tag}]" }.join(" ") + " " if log.tags && (log.tags.size > 0)

          message = log.message.to_s
          message << " -- " << log.payload.inspect if log.payload
          message << " -- " << "#{log.exception.class}: #{log.exception.message}\n#{(log.exception.backtrace || []).join("\n")}" if log.exception

          duration_str = log.duration ? "(#{'%.1f' % log.duration}ms) " : ''

          "#{SemanticLogger::Appender::Base.formatted_time(log.time)} #{log.level.to_s[0..0].upcase} [#{$$}:#{log.thread_name}] #{tags}#{duration_str}#{log.name} -- #{message}"
        end
      end

      ############################################################################
      protected

      # By default the appender should log everything that is sent to it by
      # the loggers. That way the loggers control the log level
      # By setting the log level to a higher value the appender can be setup
      # to log for example only :warn or higher while other appenders
      # are able to log lower level information
      def initialize(level, &block)
        # Set the formatter to the supplied block
        @formatter = block || default_formatter

        # Appenders don't take a class name, so use this class name if an appender
        # is logged to directly
        super(self.class, level || :trace)
      end

      # For JRuby include the Thread name rather than its id
      if defined? Java
        # Return the Time as a formatted string
        # JRuby only supports time in ms
        def self.formatted_time(time)
          "#{time.strftime("%Y-%m-%d %H:%M:%S")}.#{"%03d" % (time.usec/1000)}"
        end
      else
        # Return the Time as a formatted string
        # Ruby MRI supports micro seconds
        def self.formatted_time(time)
          "#{time.strftime("%Y-%m-%d %H:%M:%S")}.#{"%06d" % (time.usec)}"
        end
      end

    end
  end
end