# encoding: UTF-8

module GoodData
  module Mixin
    module IsLabel
      # Returns true if the object is a label false otherwise
      # @return [Boolean]
      def label?
        true
      end

      alias_method :display_form?, :label?
    end
  end
end
