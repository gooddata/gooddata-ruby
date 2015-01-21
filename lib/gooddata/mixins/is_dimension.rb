# encoding: UTF-8

module GoodData
  module Mixin
    module IsDimension
      # Returns true if the object is a dimension false otherwise
      # @return [Boolean]
      def dimension?
        true
      end
    end
  end
end
