# encoding: UTF-8

module GoodData
  # Project Not Found
  class ValidationError < RuntimeError
    DEFAULT_MSG = 'Validation has failed. Run validate method on blueprint to learn more about the errors.'

    def initialize(msg = DEFAULT_MSG)
      super(msg)
    end
  end
end
