# encoding: UTF-8

require_relative '../columns/attribute'

module GoodData
  module Model
    ##
    # Time field that's not connected to a time-of-a-day dimension
    #
    class TimeAttribute < Attribute
      def type_prefix;
        TIME_ATTRIBUTE_PREFIX;
      end

      def key;
        "#{TIME_COLUMN_PREFIX}#{super}";
      end

      def table;
        @table ||= "#{super}_tm";
      end
    end
  end
end
