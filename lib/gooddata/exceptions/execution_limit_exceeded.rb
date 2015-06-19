# encoding: UTF-8

module GoodData
  class ExecutionLimitExceeded < RuntimeError
    def initialize(msg = 'The time limit #{time_limit} secs for polling on #{link} is over')
      super(msg)
    end
  end
end
