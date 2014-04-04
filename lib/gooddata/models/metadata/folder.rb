# encoding: UTF-8

require_relative '../md_object'

module GoodData
  module Model
    ##
    # Base class for GoodData attribute and fact folder abstractions
    #
    class Folder < MdObject
      def initialize(title)
        # TODO: should a super be here?
        # how to deal with name vs title?
        @title = title
        @name = GoodData::Helpers.sanitize_string(title)
      end

      def to_maql_create
        "CREATE FOLDER {#{type_prefix}.#{name}}" \
            + " VISUAL (#{visual}) TYPE #{type};\n"
      end
    end
  end
end
