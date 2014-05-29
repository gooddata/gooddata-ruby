# encoding: utf-8

require_relative 'object'

module GoodData
  module Rest
    # Bridge between Rest::Object and Rest::Connection
    #
    # MUST be Responsible for creating new Rest::Object instances using proper Rest::Connection
    # SHOULD be used for throttling, statistics, custom 'allocation strategies' ...
    class ObjectFactory
      attr_accessor :client
      attr_accessor :connection
      attr_accessor :objects
      attr_accessor :resources

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
      def initialize(client)
        fail ArgumentError 'Invalid connection passed' if client.nil?

        @client = client

        # Set connection used by factory
        @connection = @client.connection

        # Initialize internal factory map of GoodData::Rest::Object instances
        @objects = ObjectFactory.objects

        # Initialize internal factory map of GoodData::Rest::Resource instances
        @resources = ObjectFactory.resources
      end

      def create(type, opts = {})
        res = type.new(opts)
        res.client = client
        res
      end

      def find(type, opts = {})
        type.send('find', opts, @client)
      end
    end
  end
end
