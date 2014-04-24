# encoding: UTF-8

require_relative '../columns/attribute'

module GoodData
  module Model
    ##
    # A GoodData attribute that represents a data set's connection point or a data set
    # without a connection point
    #
    class Anchor < Attribute
      def initialize(column, schema)
        if column
          super
        else
          super({ :type => 'anchor', :name => 'id' }, schema)
          @labels = []
          @primary_label = nil
        end
      end

      def table
        @table ||= 'f_' + @schema.name
      end

      def to_maql_create
        maql = super
        maql += "\n# Connect '#{title}' to all attributes of this data set\n"
        @schema.attributes.values.each do |c|
          maql += "ALTER ATTRIBUTE {#{c.identifier}} ADD KEYS " \
                + "{#{table}.#{c.key}};\n"
        end
        maql
      end
    end
  end
end
