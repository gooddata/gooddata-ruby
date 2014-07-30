# encoding: UTF-8

module GoodData
  module Mixin
    module NotFact
      # Returns true if the object is a fact false otherwise
      # @return [Boolean]
      def fact?
        false
      end
    end
  end
end
