# encoding: utf-8

require 'rest-client'

require_relative '../helpers/auth_helpers'

require_relative 'connection'
require_relative 'object_factory'

require_relative '../mixins/inspector'

module GoodData
  module Rest
    # User's interface to GoodData Platform.
    #
    # MUST provide way to use - DELETE, GET, POST, PUT
    # SHOULD provide way to use - HEAD, Bulk GET ...
    class Client
      #################################
      # Constants
      #################################
      DEFAULT_CONNECTION_IMPLEMENTATION = GoodData::Rest::Connection

      #################################
      # Class variables
      #################################
      @@instance = nil # rubocop:disable ClassVars

      #################################
      # Getters/Setters
      #################################

      # Decide if we need provide direct access to connection
      attr_reader :connection

      # TODO: Decide if we need provide direct access to factory
      attr_reader :factory
      attr_reader :opts

      include Mixin::Inspector
      inspector :object_id

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
        def connect(username = nil, password = nil, opts = { :verify_ssl => true })
          if username.is_a?(Hash)
            opts = opts.merge(username.symbolize_keys)
          else
            opts[:username] = username
            opts[:password] = password
          end

          # if username/password not set, try load ENV variables
          if opts[:username].nil? && opts[:password].nil?
            opts[:username] = ENV['GD_GEM_USER']
            opts[:password] = ENV['GD_GEM_PASSWORD']
          end

          # if username/password still not set, try load .gooddata file
          if opts[:username].nil? && opts[:password].nil?
            tmp_opts = Helpers::AuthHelper.read_credentials
            opts = opts.merge(tmp_opts)
          end

          unless opts[:sst_token]
            fail ArgumentError, 'No username specified' if opts[:username].nil?
            fail ArgumentError, 'No password specified' if opts[:password].nil?
          end

          client = Client.new(opts)

          if client
            at_exit do
              puts client.connection.stats_table if client && client.connection && (GoodData.stats_on? || client.stats_on?)
            end
          end

          # HACK: This line assigns class instance # if not done yet
          @@instance = client # rubocop:disable ClassVars
          client
        end

        def disconnect
          if @@instance # rubocop:disable ClassVars, Style/GuardClause
            @@instance.disconnect # rubocop:disable ClassVars
            @@instance = nil # rubocop:disable ClassVars
          end
        end

        def connection
          @@instance # rubocop:disable ClassVars
        end

        # Retry block if exception thrown
        def retryable(options = {}, &block)
          GoodData::Rest::Connection.retryable(options, &block)
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

      def create_project(options = { title: 'Project', auth_token: ENV['GD_PROJECT_TOKEN'] })
        GoodData::Project.create({ client: self }.merge(options))
      end

      def create_project_from_blueprint(blueprint, options = {})
        GoodData::Model::ProjectCreator.migrate(spec: blueprint, token: options[:auth_token], client: self)
      end

      def domain(domain_name)
        GoodData::Domain[domain_name, :client => self]
      end

      def projects(id = :all)
        GoodData::Project[id, client: self]
      end

      def processes(id = :all)
        GoodData::Process[id, client: self]
      end

      def connect
        username = @opts[:username]
        password = @opts[:password]

        @connection.connect(username, password, @opts)
      end

      def disconnect
        @connection.disconnect
      end

      #######################
      # Factory stuff
      ######################
      def create(klass, data = {}, opts = {})
        @factory.create(klass, data, opts)
      end

      def find(klass, opts = {})
        @factory.find(klass, opts)
      end

      # Gets resource by name
      def resource(res_name)
        puts "Getting resource '#{res_name}'"
        nil
      end

      def user(id = nil)
        if id
          create(GoodData::Profile, get(id))
        else
          create(GoodData::Profile, @connection.user)
        end
      end

      def stats_off
        @stats = false
      end

      def stats_on
        @stats = true
      end

      def stats_on? # rubocop:disable Style/TrivialAccessors
        @stats
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
      def get(uri, opts = {}, & block)
        @connection.get uri, opts, & block
      end

      # FIXME: Invstigate _file argument
      def get_project_webdav_path(_file, opts = { :project => GoodData.project })
        p = opts[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, opts]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        u = URI(project.links['uploads'])
        URI.join(u.to_s.chomp(u.path.to_s), '/project-uploads/', "#{project.pid}/")
      end

      # FIXME: Invstigate _file argument
      def get_user_webdav_path(_file, opts = { :project => GoodData.project })
        p = opts[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, opts]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        u = URI(project.links['uploads'])
        URI.join(u.to_s.chomp(u.path.to_s), '/uploads/')
      end

      # Generalizaton of poller. Since we have quite a variation of how async proceses are handled
      # this is a helper that should help you with resources where the information about "Are we done"
      # is the http code of response. By default we repeat as long as the code == 202. You can
      # change the code if necessary. It expects the URI as an input where it can poll. It returns the
      # value of last poll. In majority of cases these are the data that you need.
      #
      # @param link [String] Link for polling
      # @param options [Hash] Options
      # @return [Hash] Result of polling
      def poll_on_code(link, options = {})
        code = options[:code] || 202
        sleep_interval = options[:sleep_interval] || DEFAULT_SLEEP_INTERVAL
        response = get(link, :process => false)

        while response.code == code
          sleep sleep_interval
          GoodData::Rest::Client.retryable(:tries => 3, :refresh_token => proc { connection.refresh_token }) do
            sleep sleep_interval
            response = get(link, :process => false)
          end
        end
        if options[:process] == false
          response
        else
          get(link)
        end
      end

      # Generalizaton of poller. Since we have quite a variation of how async proceses are handled
      # this is a helper that should help you with resources where the information about "Are we done"
      # is inside the response. It expects the URI as an input where it can poll and a block that should
      # return either true -> 'meaning we are done' or false -> meaning sleep and repeat. It returns the
      # value of last poll. In majority of cases these are the data that you need
      #
      # @param link [String] Link for polling
      # @param options [Hash] Options
      # @return [Hash] Result of polling
      def poll_on_response(link, options = {}, &bl)
        sleep_interval = options[:sleep_interval] || DEFAULT_SLEEP_INTERVAL
        response = get(link)
        while bl.call(response)
          sleep sleep_interval
          GoodData::Rest::Client.retryable(:tries => 3, :refresh_token => proc { connection.refresh_token }) do
            sleep sleep_interval
            response = get(link)
          end
        end
        response
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

      # Uploads file to staging
      #
      # @param file [String] file to be uploaded
      # @param options [Hash] must contain :staging_url key (file will be uploaded to :staging_url + File.basename(file))
      def upload(file, options = {})
        @connection.upload file, options
      end

      # Downloads file from staging
      #
      # @param source_relative_path [String] path relative to @param options[:staging_url]
      # @param target_file_path [String] path to be downloaded to
      # @param options [Hash] must contain :staging_url key (file will be downloaded from :staging_url + source_relative_path)
      def download(source_relative_path, target_file_path, options = {})
        @connection.download source_relative_path, target_file_path, options
      end

      def download_from_user_webdav(source_relative_path, target_file_path, options = { :client => GoodData.client, :project => project })
        download(source_relative_path, target_file_path, options.merge(:directory => options[:directory],
                                                                       :staging_url => get_user_webdav_url(options)))
      end

      def upload_to_user_webdav(file, options = {})
        upload(file, options.merge(:directory => options[:directory],
                                   :staging_url => get_user_webdav_url(options)))
      end

      def with_project(pid, &block)
        GoodData.with_project(pid, client: self, &block)
      end

      ###################### PRIVATE ######################

      private

      def get_user_webdav_url(options = {})
        p = options[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = options[:project] || GoodData::Project[p, options]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        u = URI(project.links['uploads'])
        us = u.to_s
        ws = options[:client].opts[:webdav_server]
        if !us.empty? && !us.downcase.start_with?('http') && !ws.empty?
          u = URI.join(ws, us)
        end

        URI.join(u.to_s.chomp(u.path.to_s), '/uploads/')
      end
    end
  end
end
