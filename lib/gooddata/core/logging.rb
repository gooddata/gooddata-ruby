# encoding: UTF-8

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

    def logging_on?
      !GoodData.logger.instance_of?(NilLogger)
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

    def stats_on
      @stats = true
    end

    def stats_on? # rubocop:disable Style/TrivialAccessors
      @stats
    end

    def stats_off
      @stats = false
    end
  end
end
