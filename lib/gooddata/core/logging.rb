# encoding: UTF-8

require_relative 'threaded'

module GoodData
  class << self
    # Turn logging on
    def logging_on
      if logger.is_a? NilLogger
        GoodData::logger = Logger.new(STDOUT)
      end
    end

    # Turn logging off
    def logging_off
      GoodData::logger = NilLogger.new
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

    # Sets the logger instance
    def logger=(logger)
      @logger = logger
    end
  end
end