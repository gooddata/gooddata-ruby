# encoding: UTF-8

module GoodData
  class UserInDifferentDomainError < RuntimeError
    DEFAULT_MSG = 'User is already in different domain'

    def initialize(msg = DEFAULT_MSG)
      super(msg)
    end
  end
end
