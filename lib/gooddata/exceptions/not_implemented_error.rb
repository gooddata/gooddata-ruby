# encoding: UTF-8

module GoodData
  class NotImplementedError < RuntimeError
    DEFAULT_MSG = 'Not Implemented!'

    def initialize(msg = DEFAULT_MSG)
      super
    end
  end
end
