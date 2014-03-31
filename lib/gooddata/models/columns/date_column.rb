# encoding: UTF-8

require_relative '../metadata/column'

module GoodData
  module Model
    ##
    # Date column. A container holding the following
    # parts: date fact, a date reference or attribute and an optional time component
    # that contains a time fact and a time reference or attribute.
    #
    class DateColumn < Column
      attr_reader :parts, :facts, :attributes, :references

      def initialize(column, schema)
        super column, schema
        @parts = {}; @facts = []; @attributes = []; @references = []

        # @facts << @parts[:date_fact] = DateFact.new(column, schema)
        if column[:dataset] then
          @parts[:date_ref] = DateReference.new column, schema
          @references << @parts[:date_ref]
        else
          @attributes << @parts[:date_attr] = DateAttribute.new(column, schema)
        end
        # if column['datetime'] then
        #   puts "*** datetime"
        #   @facts << @parts[:time_fact] = TimeFact.new(column, schema)
        #   if column['schema_reference'] then
        #     @parts[:time_ref] = TimeReference.new column, schema
        #   else
        #     @attributes << @parts[:time_attr] = TimeAttribute.new(column, schema)
        #   end
        # end
      end

      def to_maql_create
        @parts.values.map { |v| v.to_maql_create }.join "\n"
      end

      def to_maql_drop
        @parts.values.map { |v| v.to_maql_drop }.join "\n"
      end

      def to_csv_header(row)
        SKIP_FIELD
      end

      def to_csv_data(headers, row)
        SKIP_FIELD
      end

      def to_manifest_part(mode)
        nil
      end
    end
  end
end
