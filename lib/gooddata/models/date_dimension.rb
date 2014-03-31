# encoding: UTF-8

require_relative 'md_object'

module GoodData
  module Model
    class DateDimension < MdObject
      def initialize(spec={})
        super()
        @name = spec[:name]
        @title = spec[:title] || @name
        @urn = spec[:urn] || 'URN:GOODDATA:DATE'
      end

      def to_maql_create
        # urn = "urn:chefs_warehouse_fiscal:date"
        # title = "title"
        # name = "name"

        maql = ''
        maql += "INCLUDE TEMPLATE \"#{@urn}\" MODIFY (IDENTIFIER \"#{@name}\", TITLE \"#{@title}\");"
        maql
      end
    end
  end
end
