# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'rest-client'

require_relative 'nil_logger'
require_relative 'splunk_logger'
require_relative 'gd_logger'

module GoodData
  DEFAULT_LOG_LEVEL = Logger::INFO
  DEFAULT_LOG_OUTPUT = STDOUT
  DEFAULT_LOGGER_CLASS = GDLogger

  DEFAULT_RESTLOG_LEVEL = Logger::DEBUG
  DEFAULT_RESTLOG_OUTPUT = STDOUT
  DEFAULT_RESTLOGGER_CLASS = GDLogger

  DEFAULT_SPLUNKLOG_LEVEL = Logger::INFO
  DEFAULT_SPLUNKLOG_OUTPUT = STDERR
  DEFAULT_SPLUNKLOGGER_CLASS = SplunkLogger
  DEFAULT_SPLUNKLOG_MODE = {:file_output => true, :buffering => true}

  class << self
    attr_accessor :logger, :rest_logger, :splunk_logger
    attr_writer :stats

    # Turn logging on
    #
    # ### Example
    #
    #     # Turn of default logging
    #     GoodData.logging_on
    #
    #     # Log only WARN and higher
    #     GoodData.logging_on(Logger::WARN)
    #
    #     # Log DEBUG and above to file
    #     GoodData.logging_on(Logger::DEBUG, 'log.txt')
    #
    def logging_on(level = DEFAULT_LOG_LEVEL, output = DEFAULT_LOG_OUTPUT, klass = DEFAULT_LOGGER_CLASS)
      @logger = klass.new(output)
      @logger.level = level
      @logger
    end

    # Turn logging on
    #
    # ### Example
    #
    #     GoodData.logging_off
    #
    def logging_off
      @logger = NilLogger.new
    end

    def logging_on?
      !@logger.instance_of?(NilLogger)
    end

    # Turn logging on with HTTP included
    #
    # ### Example
    #
    #     GoodData.logging_http_on
    #
    def logging_http_on(level = DEFAULT_RESTLOG_LEVEL, output = DEFAULT_SPLUNKLOG_OUTPUT, klass = DEFAULT_SPLUNKLOGGER_CLASS)
      @rest_logger = klass.new(output)
      @rest_logger.level = level
      @rest_logger
    end

    # Turn logging on
    #
    # ### Example
    #
    #     GoodData.logging_http_off
    #
    def logging_http_off
      @rest_logger = NilLogger.new
    end

    def logging_http_on?
      !@rest_logger.instance_of?(NilLogger)
    end

    def logging_splunk_on(level = DEFAULT_SPLUNKLOG_LEVEL, output = DEFAULT_SPLUNKLOG_OUTPUT, klass = DEFAULT_SPLUNKLOGGER_CLASS, mode = DEFAULT_SPLUNKLOG_MODE)
      @splunk_logger = klass.new(output, mode)
      @splunk_logger.level = level
      @splunk_logger
    end

    def logging_splunk_off
      @splunk_logger = NilLogger.new
      @splunk_logger
    end

    def logging_splunk_on?
      !@splunk_logger.instance_of?(NilLogger)
    end

    def stats_on
      @stats = true
    end

    def stats_on?
      @stats
    end

    def stats_off
      @stats = false
    end

    # Initial setup of logger
    GoodData.logger = GoodData.logging_on

    # Initial setup of rest logger
    GoodData.rest_logger = GoodData.logging_http_on(
      nil,
      DEFAULT_RESTLOG_OUTPUT,
      NilLogger
    )

    # Initial setup of splunk logger
    GoodData.splunk_logger = GoodData.logging_splunk_off
  end
end
