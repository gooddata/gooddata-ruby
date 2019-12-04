# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'rest-client'

require_relative '../helpers/auth_helpers'
require_relative '../helpers/global_helpers'

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
        def connect(username, password = 'aaaa', opts = {})
          execution_id = ""
          if username.is_a?(Hash) && username.key?(:execution_id)
            execution_id = username[:execution_id]
            username.delete(:execution_id)
          end

          if opts.key?(:execution_id)
            execution_id = opts[:execution_id]
            opts.delete(:execution_id)
          end

          if username.nil? && password.nil?
            username = ENV['GD_GEM_USER']
            password = ENV['GD_GEM_PASSWORD']
          end

          username = GoodData::Helpers.symbolize_keys(username) if username.is_a?(Hash)

          new_opts = opts.dup
          if username.is_a?(Hash) && username.key?(:sst_token)
            new_opts = new_opts.merge(username)
          elsif username.is_a? Hash
            new_opts = new_opts.merge(username)
            new_opts[:username] = username[:login] || username[:user] || username[:username]
            new_opts[:password] = username[:password]
          elsif username.nil? && password.nil? && opts.blank?
            new_opts = Helpers::AuthHelper.read_credentials
          else
            new_opts[:username] = username
            new_opts[:password] = password
          end

          new_opts = { verify_ssl: true, execution_id: execution_id }.merge(new_opts)
          if username.is_a?(Hash) && username[:cookies]
            new_opts[:sst_token] = username[:cookies]['GDCAuthSST']
            new_opts[:cookies] = username[:cookies]
          end

          unless new_opts[:sst_token]
            fail ArgumentError, 'No username specified' if new_opts[:username].nil?
            fail ArgumentError, 'No password specified' if new_opts[:password].nil?
          end

          if username.is_a?(Hash) && username.key?(:server)
            new_opts[:server] = username[:server]
          end

          client = Client.new(new_opts)
          GoodData.logger.info("Connected to server with webdav path #{client.user_webdav_path}")

          # HACK: This line assigns class instance # if not done yet
          @@instance = client # rubocop:disable ClassVars
        end

        def connect_sso(sso)
          @@instance = Client.new(sso) # rubocop:disable ClassVars
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
        GoodData.logger.warn 'Beware! project_is_accessible is deprecated and should not be used.'
        begin # rubocop:disable RedundantBegin TODO: remove this after droping JRuby which does not support rescue without begin
          projects(id)
        rescue RestClient::NotFound
          false
        end
      end

      def projects(id = :all, limit = nil, offset = 0)
        if limit.nil?
          GoodData::Project[id, client: self]
        else
          GoodData::Project.all({ client: self }, limit, offset)
        end
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
        if stats_on?
          GoodData.logger.info("API call statistics to server #{@connection.server}")
          GoodData.logger.info(@connection.stats_table.to_s)
        end
        @connection.disconnect
      end

      def warehouses(id = :all)
        GoodData::DataWarehouse[id, client: self]
      end

      def create_datawarehouse(opts = {})
        GoodData::DataWarehouse.create({ client: self }.merge(opts))
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
        GoodData.logger.info("Getting resource '#{res_name}'")
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
        @connection.delete uri, opts.merge(stats_on: stats_on?)
      end

      # HTTP GET
      #
      # @param uri [String] Target URI
      def get(uri, opts = {}, & block)
        @connection.get uri, opts.merge(stats_on: stats_on?), & block
      end

      def project_webdav_path(opts = { project: GoodData.project })
        p = opts[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, opts]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        url = project.links['uploads']
        fail 'Project WebDAV not supported in this Data Center' unless url

        GoodData.logger.warn 'Beware! Project webdav is deprecated and should not be used.'
        url
      end

      def user_webdav_path
        uri = if opts[:webdav_server]
                opts[:webdav_server]
              else
                links.find { |i| i['category'] == 'uploads' }['link']
              end
        res = uri.chomp('/') + '/'
        res[0] == '/' ? "#{connection.server}#{res}" : res
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
      # return either true (meaning sleep and repeat) or false (meaning we are done). It returns the
      # value of last poll. In majority of cases these are the data that you need
      #
      # @param link [String] Link for polling
      # @param options [Hash] Options
      # @return [Hash] Result of polling
      def poll_on_response(link, options = {}, &bl)
        time_limit = options[:time_limit] || DEFAULT_POLL_TIME_LIMIT
        process = options[:process] == false ? false : true

        # get the first status and start the timer
        response = get(link, process: process)
        poll_start = Time.now
        retry_time = GoodData::Rest::Connection::RETRY_TIME_INITIAL_VALUE
        while bl.call(response)
          limit_breached = time_limit && (Time.now - poll_start > time_limit)
          if limit_breached
            fail ExecutionLimitExceeded, "The time limit #{time_limit} secs for polling on #{link} is over"
          end
          sleep retry_time
          retry_time *= GoodData::Rest::Connection::RETRY_TIME_COEFFICIENT
          GoodData::Rest::Client.retryable(:tries => Helpers::GD_MAX_RETRY, :refresh_token => proc { connection.refresh_token }) do
            response = get(link, process: process)
          end
        end
        response
      end

      # HTTP PUT
      #
      # @param uri [String] Target URI
      def put(uri, data, opts = {})
        @connection.put uri, data, opts.merge(stats_on: stats_on?)
      end

      # HTTP POST
      #
      # @param uri [String] Target URI
      def post(uri, data, opts = {})
        @connection.post uri, data, opts.merge(stats_on: stats_on?)
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

      def download_from_user_webdav(source_relative_path, target_file_path, options = { client: GoodData.client })
        download(source_relative_path, target_file_path, options.merge(:directory => options[:directory],
                                                                       :staging_url => user_webdav_path))
      end

      def upload_to_user_webdav(file, options = {})
        upload(file, options.merge(:directory => options[:directory],
                                   :staging_url => user_webdav_path))
      end

      def with_project(pid, &block)
        GoodData.with_project(pid, client: self, &block)
      end

      def links
        GoodData::Helpers.get_path(get('/gdc'), %w(about links))
      end
    end
  end
end
