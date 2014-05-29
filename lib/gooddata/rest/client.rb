# encoding: utf-8

require_relative 'connections/connections'
require_relative 'object_factory'

module GoodData
  module Rest
    # User's interface to GoodData Platform.
    #
    # MUST provide way to use - DELETE, GET, POST, PUT
    # SHOULD provide way to use - HEAD, Bulk GET ...
    # SHOULD wrap some existing library/gem - RestClient, Typhoeus
    class Client
      #################################
      # Constants
      #################################
      DEFAULT_CONNECTION_IMPLEMENTATION = Connections::RestClientConnection # Connections::TyphoeusConnection # Connections::DummyConnection

      #################################
      # Class variables
      #################################
      @@instance = nil

      #################################
      # Getters/Setters
      #################################

      # Decide if we need provide direct access to connection
      attr_reader :connection

      # TODO: Decide if we need provide direct access to factory
      attr_reader :factory

      #################################
      # Class methods
      #################################
      class << self
        # Globally available way to connect (and create client and set global instance)
        #
        # ## HACK
        # To make transition from old implementation to new one following HACK IS TEMPORARILY ENGAGED!
        #
        # 1. First call of #connect sets the GoodData::Rest::Client.instance (static, singleton instance)
        # 2. There are METHOD functions with same signature as their CLASS counterparts using singleton instance
        #
        # ## Example
        #
        # client = GoodData.connect('jon.smith@goodddata.com', 's3cr3tp4sw0rd')
        #
        # @param username [String] Username to be used for authentication
        # @param password [String] Password to be used for authentication
        # @return [GoodData::Rest::Client] Client
        def connect(username, password, opts = {})
          new_opts = opts.dup
          if username.is_a? Hash
            new_opts[:username] = username[:login]
            new_opts[:password] = username[:password]
          else
            new_opts[:username] = username
            new_opts[:password] = password
          end

          # new_opts = new_opts.merge(Hash.new({}))
          res = Client.new(new_opts)

          # HACK: This line assigns class instance # if not done yet
          @@instance = res # if res.nil?
          res
        end

        def disconnect
          if @@instance
            @@instance.disconnect
            @@instance = nil
          end
        end

        def connection
          @@instance
        end

        alias_method :client, :connection
      end

      # Constructor of client
      # @param opts [Hash] Client options
      # @option opts [String] :username Username used for authentication
      # @option opts [String] :password Password used for authentication
      # @option opts :connection_factory Object able to create new instances of GoodData::Rest::Connection
      # @option opts [GoodData::Rest::Connection] :connection Existing GoodData::Rest::Connection
      def initialize(opts)
        # TODO: Decide if we want to pass the options directly or not
        @opts = opts

        @connection_factory = @opts[:connection_factory] || DEFAULT_CONNECTION_IMPLEMENTATION

        # TODO: See previous TODO
        # Create connection
        @connection = opts[:connection] || @connection_factory.new(opts)

        # Connect
        connect

        # Create factory bound to previously created connection
        @factory = ObjectFactory.new(self)
      end

      def connect
        username = @opts[:username]
        password = @opts[:password]

        @connection.connect(username, password)
      end

      def disconnect
        @connection.disconnect
      end

      #######################
      # Factory stuff
      ######################
      def create(klass, opts = {})
        @factory.create(klass, opts)
      end

      def find(klass, opts = {})
        @factory.find(klass, opts)
      end

      # Gets resource by name
      def resource(res_name)
        puts "Getting resource '#{res_name}'"
        nil
      end

      def user
        create(GoodData::Profile, @connection.user)
      end

      #######################
      # Rest
      #######################
      # HTTP DELETE
      #
      # @param uri [String] Target URI
      def delete(uri, opts = {})
        @connection.delete uri, opts
      end

      # HTTP GET
      #
      # @param uri [String] Target URI
      def get(uri, opts = {})
        @connection.get uri, opts
      end

      # HTTP PUT
      #
      # @param uri [String] Target URI
      def put(uri, data, opts = {})
        @connection.put uri, data, opts
      end

      # HTTP POST
      #
      # @param uri [String] Target URI
      def post(uri, data, opts = {})
        @connection.post uri, data, opts
      end

      # Retry blok if exception thrown
      def retryable(options = {}, &block)
        opts = { :tries => 1, :on => Exception }.merge(options)

        retry_exception, retries = opts[:on], opts[:tries]

        begin
          return yield
        rescue retry_exception
          retry if (retries -= 1) > 0
        end

        yield
      end

      # Uploads file
      def upload(file, options = {})
        @connection.upload file, options
      end
    end
  end
end
