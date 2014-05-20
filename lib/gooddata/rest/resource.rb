# encoding: utf-8

require_relative 'object'

module GoodData
  module Rest
    # Base class for REST resources implementing (at least 'somehow') full CRUD
    #
    # IS responsible for wrapping full CRUD interface
    class Resource < Object
      # Default constructor passing all arguments to parent
      def initialize(opts = {})
        super
      end
    end
  end
end
