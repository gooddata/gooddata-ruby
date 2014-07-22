# encoding: UTF-8

module GoodData
  # Project Not Found
  class AttributeElementNotFound < RuntimeError
    DEFAULT_MSG = 'Attribute element "%s" was not found'

    def initialize(value, msg = DEFAULT_MSG)
      super(sprintf(DEFAULT_MSG, value))
    end
  end
end
