# encoding: UTF-8

require_relative '../metadata/fact'

module GoodData
  module Model
    ##
    # Fact representation of a time of a day
    #
    class TimeFact < Fact
      def column_prefix
        TIME_COLUMN_PREFIX
      end

      def type_prefix
        TIME_FACT_PREFIX
      end
    end
  end
end
