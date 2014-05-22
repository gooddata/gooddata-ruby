# encoding: UTF-8

module GoodData
  # Project Not Found
  class ValidationError < RuntimeError
    DEFAULT_MSG = 'Validation has failed'

    def initialize(msg = DEFAULT_MSG)
      super(msg)
    end
  end
end
