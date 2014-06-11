# encoding: UTF-8

require_relative '../md_object'
require_relative '../../helpers/helpers'

module GoodData
  module Model
    ##
    # This is a base class for server-side LDM elements such as attributes, labels and
    # facts
    #
    class Column < MdObject
      attr_accessor :folder, :name, :title, :schema

      def initialize(hash, schema)
        super()
        fail(ArgumentError, "Schema must be provided, got #{schema.class}") unless schema.is_a? Schema
        fail('Data set fields must have their names defined') if hash[:name].nil?

        @name = hash[:name]
        @title = hash[:title] || hash[:name].humanize
        @folder = hash[:folder]
        @schema = schema
      end

      ##
      # Generates an identifier from the object name by transliterating
      # non-Latin character and then dropping non-alphanumerical characters.
      #
      def identifier
        @identifier ||= "#{type_prefix}.#{@schema.name}.#{name}"
      end

      def to_maql_drop
        "DROP {#{identifier}};\n"
      end

      def visual
        visual = super
        visual += ", FOLDER {#{folder_prefix}.#{(folder)}}" if folder
        visual
      end

      def to_csv_header(row)
        name
      end

      def to_csv_data(headers, row)
        row[name]
      end

      # Overriden to prevent long strings caused by the @schema attribute
      #
      def inspect
        to_s.sub(/>$/, " @title=#{@title.inspect}, @name=#{@name.inspect}, @folder=#{@folder.inspect}," \
                       " @schema=#{@schema.to_s.sub(/>$/, ' @title=' + @schema.name.inspect + '>')}" \
                       ">")
      end
    end
  end
end
