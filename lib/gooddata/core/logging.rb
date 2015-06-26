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
      @logger = default_logger if logger.is_a? NilLogger
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

    def stats_on? # rubocop:disable Style/TrivialAccessors
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
