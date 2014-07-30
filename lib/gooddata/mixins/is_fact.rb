# encoding: UTF-8

module GoodData
  module Mixin
    module IsAttribute
      # Returns true if the object is a fact false otherwise
      # @return [Boolean]
      def fact?
        true
      end
    end
  end
end
