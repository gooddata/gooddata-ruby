# encoding: UTF-8

module GoodData
  module Mixin
    module NotLabel
      # Returns true if the object is a fact label otherwise
      # @return [Boolean]
      def label?
        false
      end
    end
  end
end
