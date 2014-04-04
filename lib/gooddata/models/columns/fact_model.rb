# encoding: UTF-8

require_relative '../metadata/column'

module GoodData
  module Model
    ##
    # GoodData fact abstraction
    #
    class Fact < Column
      def type_prefix;
        FACT_PREFIX;
      end

      def column_prefix;
        FACT_COLUMN_PREFIX;
      end

      def folder_prefix;
        FACT_FOLDER_PREFIX;
      end

      def table
        @schema.table
      end

      def column
        @column ||= table + '.' + column_prefix + name
      end

      def to_maql_create
        "CREATE FACT {#{self.identifier}} VISUAL (#{visual})" \
               + " AS {#{column}};\n"
      end

      def to_manifest_part(mode)
        {
          'populates' => [identifier],
          'mode' => mode,
          'columnName' => name
        }
      end

      def to_wire_model
        {
          'fact' => {
            'identifier' => identifier,
            'title' => title
          }
        }
      end
    end
  end
end
