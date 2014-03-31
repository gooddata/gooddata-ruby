# encoding: UTF-8

require_relative 'folder'

module GoodData
  module Model
    ##
    # GoodData fact folder abstraction
    #
    class FactFolder < Folder
      def type;
        'FACT'
      end

      def type_prefix;
        'ffld'
      end
    end
  end
end
