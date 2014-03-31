# encoding: UTF-8

require_relative '../metadata/column'
require_relative 'label'

module GoodData
  module Model
    ##
    # GoodData attribute abstraction
    #
    class Attribute < Column
      attr_reader :primary_label, :labels

      def type_prefix;
        ATTRIBUTE_PREFIX;
      end

      def folder_prefix;
        ATTRIBUTE_FOLDER_PREFIX;
      end

      def initialize(hash, schema)
        super hash, schema
        @labels = []
        @primary_label = GoodData::Model::Label.new hash, self, schema
      end

      def table
        @table ||= 'd_' + @schema.name + '_' + name
      end

      def key;
        "#{@name}#{FK_SUFFIX}";
      end

      def to_maql_create
        maql = "CREATE ATTRIBUTE {#{identifier}} VISUAL (#{visual})" \
               + " AS KEYS {#{table}.#{Model::FIELD_PK}} FULLSET;\n"
        maql += @primary_label.to_maql_create if @primary_label
        maql
      end

      def to_manifest_part(mode)
        {
          'referenceKey' => 1,
          'populates' => [@primary_label.identifier],
          'mode' => mode,
          'columnName' => name
        }
      end

      def to_wire_model
        {
          'attribute' => {
            'identifier' => identifier,
            'title' => title,
            'labels' => labels.map do |l|
              {
                'label' => {
                  'identifier' => l.identifier,
                  'title' => l.title,
                  'type' => 'GDC.text'
                }
              }
            end
          }
        }
      end
    end
  end
end
