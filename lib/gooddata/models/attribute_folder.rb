# encoding: UTF-8

require_relative 'folder'

module GoodData
  module Model
    ##
    # GoodData attribute folder abstraction
    #
    class AttributeFolder < Folder
      def type;
        'ATTRIBUTE'
      end

      def type_prefix;
        'dim'
      end
    end
  end
end
