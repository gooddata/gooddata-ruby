# encoding: UTF-8

require_relative 'nil_logger'
require_relative 'threaded'

module GoodData
  class << self
    attr_writer :logger

    # Turn logging on
    #
    # ### Example
    #
    #     GoodData.logging_on
    #
    def logging_on
      GoodData.logger = Logger.new(STDOUT) if logger.is_a? NilLogger
    end

    # Turn logging on
    #
    # ### Example
    #
    #     GoodData.logging_off
    #
    def logging_off
      GoodData.logger = NilLogger.new
    end

    # Returns the logger instance. The default implementation
    # does not log anything
    # For some serious logging, set the logger instance using
    # the logger= method
    #
    # ### Example
    #
    #     require 'logger'
    #     GoodData.logger = Logger.new(STDOUT)
    #
    def logger
      @logger ||= NilLogger.new
    end
  end
end
