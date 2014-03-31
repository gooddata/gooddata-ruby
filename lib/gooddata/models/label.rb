# encoding: UTF-8

require_relative 'column'

module GoodData
  module Model
    ##
    # GoodData display form abstraction. Represents a default representation
    # of an attribute column or an additional representation defined in a LABEL
    # field
    #
    class Label < Column
      attr_accessor :attribute

      def type_prefix;
        'label';
      end

      # def initialize(hash, schema)
      def initialize(hash, attribute, schema)
        super hash, schema
        attribute = attribute.nil? ? schema.fields.find { |field| field.name === hash[:reference] } : attribute
        @attribute = attribute
        attribute.labels << self
      end

      def to_maql_create
        '# LABEL FROM LABEL'
        "ALTER ATTRIBUTE {#{@attribute.identifier}} ADD LABELS {#{identifier}}" \
              + " VISUAL (TITLE #{title.inspect}) AS {#{column}};\n"
      end

      def to_manifest_part(mode)
        {
          'populates' => [identifier],
          'mode' => mode,
          'columnName' => name
        }
      end

      def column
        "#{@attribute.table}.#{LABEL_COLUMN_PREFIX}#{name}"
      end

      alias :inspect_orig :inspect

      def inspect
        inspect_orig.sub(/>$/, " @attribute=#{@attribute.to_s.sub(/>$/, " @name=#{@attribute.name}")}>")
      end
    end
  end
end
