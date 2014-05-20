# encoding: utf-8

require_relative 'object'

module GoodData
  module Rest
    # Bridge between Rest::Object and Rest::Connection
    #
    # MUST be Responsible for creating new Rest::Object instances using proper Rest::Connection
    # SHOULD be used for throttling, statistics, custom 'allocation strategies' ...
    class ObjectFactory
      #################################
      # Class methods
      #################################
      class << self
        # Gets list of all GoodData::Rest::Object subclasses
        #
        # @return [Array<GoodData::Rest::Object>] Subclasses of GoodData::Rest::Object
        def objects
          ObjectSpace.each_object(Class).select { |klass| klass < GoodData::Rest::Object }
        end

        # Gets list of all GoodData::Rest::Resource subclasses
        #
        # @return [Array<GoodData::Rest::Resource>] Subclasses of GoodData::Rest::Resource
        def resources
          ObjectSpace.each_object(Class).select { |klass| klass < GoodData::Rest::Resource }
        end
      end

      # Initializes instance of factory
      #
      # @param connection [GoodData::Rest::Connection] Connection used by factory
      # @return [GoodData::Rest::ObjectFactory] Factory instance
      def initialize(connection)
        fail ArgumentError 'Invalid connection passed' if connection.nil?

        # Set connection used by factory
        @connection = connection

        # Initialize internal factory map of GoodData::Rest::Object instances
        @objects = ObjectFactory.objects

        # Initialize internal factory map of GoodData::Rest::Resource instances
        @resources = ObjectFactory.resources
      end

      def create(type, opts = {})
        type.new(opts)
      end
    end
  end
end
