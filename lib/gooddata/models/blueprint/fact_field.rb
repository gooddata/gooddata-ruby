# encoding: UTF-8

require_relative 'blueprint_field'

module GoodData
  module Model
    class FactBlueprintField < BlueprintField
      # Returns gd_data_type
      #
      # @return [String] returns gd_data_type of the fact
      def gd_data_type
        data[:gd_data_type] || Model::DEFAULT_FACT_DATATYPE
      end
    end
  end
end
