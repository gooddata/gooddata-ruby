# encoding: UTF-8

module GoodData
  module Mixin
    module NotMetric
      # Returns true if the object is a metric false otherwise
      # @return [Boolean]
      def metric?
        false
      end

      alias_method :measure?, :metric?
    end
  end
end
