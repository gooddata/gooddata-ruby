# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'nil_logger'

module GoodData
  class << self
    attr_writer :logger
    attr_writer :stats

    # Turn logging on
    #
    # ### Example
    #
    #     GoodData.logging_on
    #
    def logging_on(level = nil)
      @logger = default_logger if logger.is_a? NilLogger
      @logger.level = level if level
      @logger
    end

    # Turn logging on with HTTP included
    #
    # ### Example
    #
    #     GoodData.logging_http_on
    #
    def logging_http_on
      logging_on(Logger::DEBUG)
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

    # Returns the logger instance. The default implementation
    # is a logger to stdout on INFO level
    # For some serious logging, set the logger instance using
    # the logger= method
    #
    # ### Example
    #
    #     require 'logger'
    #     GoodData.logger = Logger.new(STDOUT)
    #
    def logger
      @logger ||= default_logger
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

    private

    # The default logger - stdout and INFO level
    #
    def default_logger
      log = Logger.new(STDOUT)
      log.level = Logger::INFO
      log
    end
  end
end
