# encoding: UTF-8

module GoodData
  module Mixin
    module NotAttribute
      # Returns true if the object is a fact false otherwise
      # @return [Boolean]
      def attribute?
        false
      end
    end
  end
end
