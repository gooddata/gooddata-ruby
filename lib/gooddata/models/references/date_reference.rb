# encoding: UTF-8

require_relative '../columns/reference'

module GoodData
  module Model
    ##
    # Date as a reference to a date dimension
    #
    class DateReference < Reference
      attr_accessor :format, :output_format, :urn

      def initialize(column, schema)
        super column, schema
        @output_format = column['format'] || 'dd/MM/yyyy'
        @format = @output_format.gsub('yyyy', '%Y').gsub('MM', '%m').gsub('dd', '%d')
        @urn = column[:urn] || 'URN:GOODDATA:DATE'
      end

      def identifier
        @identifier ||= "#{@schema_ref}.#{DATE_ATTRIBUTE}"
      end

      def to_manifest_part(mode)
        {
          'populates' => ["#{identifier}.#{DATE_ATTRIBUTE_DEFAULT_DISPLAY_FORM}"],
          'mode' => mode,
          'constraints' => { 'date' => output_format },
          'columnName' => name,
          'referenceKey' => 1
        }
      end

      # def to_maql_create
      #   # urn:chefs_warehouse_fiscal:date
      #   super_maql = super
      #   maql = ""
      #   # maql = "# Include date dimensions\n"
      #   # maql += "INCLUDE TEMPLATE \"#{urn}\" MODIFY (IDENTIFIER \"#{name}\", TITLE \"#{title || name}\");\n"
      #   maql += super_maql
      # end
    end
  end
end
