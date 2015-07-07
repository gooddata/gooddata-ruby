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
      DEFAULT_SLEEP_INTERVAL = 10
      DEFAULT_POLL_TIME_LIMIT = 5 * 60 * 60 # 5 hours

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
        def connect(username, password, opts = { verify_ssl: true })
          if username.nil? && password.nil?
            username = ENV['GD_GEM_USER']
            password = ENV['GD_GEM_PASSWORD']
          end

          username = username.symbolize_keys if username.is_a?(Hash)

          new_opts = opts.dup
          if username.is_a?(Hash) && username.key?(:sst_token)
            new_opts = username
          elsif username.is_a? Hash
            new_opts[:username] = username[:login] || username[:user] || username[:username]
            new_opts[:password] = username[:password]
            new_opts[:verify_ssl] = username[:verify_ssl] if username[:verify_ssl] == false || !username[:verify_ssl].blank?
          elsif username.nil? && password.nil? && (opts.nil? || opts.empty?)
            new_opts = Helpers::AuthHelper.read_credentials
          else
            new_opts[:username] = username
            new_opts[:password] = password
          end
          unless new_opts[:sst_token]
            fail ArgumentError, 'No username specified' if new_opts[:username].nil?
            fail ArgumentError, 'No password specified' if new_opts[:password].nil?
          end
          if username.is_a?(Hash) && username.key?(:server)
            new_opts[:server] = username[:server]
          end
          client = Client.new(new_opts)

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
          if @@instance # rubocop:disable Style/GuardClause
            @@instance.disconnect
            @@instance = nil # rubocop:disable ClassVars
          end
        end

        def connection
          @@instance
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

      def create_project(options = { title: 'Project' })
        GoodData::Project.create({ client: self }.merge(options))
      end

      def create_project_from_blueprint(blueprint, options = {})
        GoodData::Model::ProjectCreator.migrate(options.merge(spec: blueprint, client: self))
      end

      def domain(domain_name)
        GoodData::Domain[domain_name, :client => self]
      end

      def project_is_accessible?(id)
        projects(id) && true rescue false
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

      def stats_on?
        @stats
      end

      def generate_request_id
        @connection.generate_request_id
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

      def project_webdav_path(opts = { project: GoodData.project })
        p = opts[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, opts]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        url = project.links['uploads']
        fail 'Project WebDAV not supported in this Data Center' unless url
        url
      end

      def user_webdav_path(opts = { project: GoodData.project })
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
        process = options[:process]

        response = poll_on_response(link, options.merge(:process => false)) do |resp|
          resp.code == code
        end

        if process == false
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
        time_limit = options[:time_limit] || DEFAULT_POLL_TIME_LIMIT

        # get the first status and start the timer
        response = get(link, options)
        poll_start = Time.now

        while bl.call(response)
          limit_breached = time_limit && (Time.now - poll_start > time_limit)
          if limit_breached
            fail ExecutionLimitExceeded, "The time limit #{time_limit} secs for polling on #{link} is over"
          end
          sleep sleep_interval
          GoodData::Rest::Client.retryable(:tries => 3, :refresh_token => proc { connection.refresh_token }) do
            response = get(link, options)
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

      def download_from_user_webdav(source_relative_path, target_file_path, options = { client: GoodData.client, project: project })
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
