# encoding: UTF-8

require_relative '../metadata/column'

module GoodData
  module Model
    ##
    # Reference to another data set
    #
    class Reference < Column
      attr_accessor :reference, :schema_ref

      def initialize(column, schema)
        super column, schema
        # pp column
        @name = column[:name]
        @reference = column[:reference]
        @schema_ref = column[:dataset]
        @schema = schema
      end

      ##
      # Generates an identifier of the referencing attribute using the
      # schema name derived from schemaReference and column name derived
      # from the reference key.
      #
      def identifier
        @identifier ||= "#{ATTRIBUTE_PREFIX}.#{@schema_ref}.#{@reference}"
      end

      def key
        "#{@name}_id"
      end

      def label_column
        "#{LABEL_PREFIX}.#{@schema_ref}.#{@reference}"
      end

      def to_maql_create
        "ALTER ATTRIBUTE {#{identifier}} ADD KEYS {#{@schema.table}.#{key}};\n"
      end

      def to_maql_drop
        "ALTER ATTRIBUTE {#{identifier} DROP KEYS {#{@schema.table}.#{key}};\n"
      end

      def to_manifest_part(mode)
        {
          'populates' => [label_column],
          'mode' => mode,
          'columnName' => name,
          'referenceKey' => 1
        }
      end
    end
  end
end
