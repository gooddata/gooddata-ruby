# encoding: UTF-8

module GoodData
  module Threaded
    # Used internally for thread safety
    def threaded
      Thread.current[:goooddata] ||= {}
    end
  end

  class << self
    include Threaded
  end
end
