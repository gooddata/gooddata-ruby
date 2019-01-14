# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'logger'
require 'gooddata/bricks/middleware/context_manager'
require 'gooddata/rest/rest_aggregator'

module GoodData
  # This class delegates messages to multiple loggers
  # By usage of [ContextManager] and [Rest::Aggregator] it stores information about context of execution
  class GdLogger
    severity_map = {
      debug: Logger::DEBUG,
      info: Logger::INFO,
      warn: Logger::WARN,
      error: Logger::ERROR,
      fatal: Logger::FATAL,
      unknown: Logger::UNKNOWN
    }

    attr_accessor :loggers

    include ContextManager
    include GoodData::Rest::Aggregator

    def initialize
      @loggers = {}
      initialize_context
      initialize_store
    end

    def logging_on(logger_id, logger)
      loggers[logger_id] = logger
    end

    def logging_off(logger_id)
      loggers[logger_id] = NilLogger.new
    end

    def logging_on?(logger_id)
      loggers.key?(logger_id) && !loggers[logger_id].is_a?(NilLogger)
    end

    # Implementation of common logger methods
    %i[debug error fatal info unknown warn].each do |severity|
      # GdLogger delegates all records to all loggers
      define_method severity do |progname = nil, &block|
        add(severity_map[severity], nil, progname, &block)
      end

      # Returns [True] if any logger satisfies severity level
      define_method severity.to_s + "?" do
        test_severity severity
      end
    end

    def test_severity(severity)
      (loggers.values.map do |logger|
        logger.send severity.to_s + "?"
      end).any?
    end

    # Pass message to multiple loggers. By parameters some loggers might be filtered out and the message might be modified.
    #
    # @param severity, severity of record
    # @param message, message to be logged
    # @param progname, progname to be logged
    def add(severity, message, progname, &block)
      loggers.each do |_, logger|
        logger.add(severity, message, progname, &block)
      end
    end

    # Set logger level for specified logger
    #
    # @param level, severity level
    # @param [Symbol] logger_name, logger which severity level should be changed
    def level(level, logger_name)
      loggers[logger_name].level = level
    end

    # Set logger level for all loggers
    #
    # @param level, severity level
    def level=(level)
      loggers.values.each do |logger|
        logger.level = level
      end
    end
  end
end
