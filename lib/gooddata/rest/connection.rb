# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'terminal-table'
require 'securerandom'
require 'monitor'
require 'concurrent'
require 'rest-client'

require_relative '../version'
require_relative '../exceptions/exceptions'

require_relative '../helpers/global_helpers'

module RestClient
  module AbstractResponse
    alias_method :old_follow_redirection, :follow_redirection
    def follow_redirection(request = nil, result = nil, &block)
      if RestClient::VERSION != '1.8.0'
        fail 'Using monkey patched version of RestClient::AbstractResponse#' \
             'follow_redirection which is guaranteed to be compatible only ' \
             'with RestClient 1.8.0'
      end

      new_args = @args.dup

      url = headers[:location]
      url = URI.parse(request.url).merge(url).to_s if url !~ /^http/

      new_args[:url] = url
      if request
        fail MaxRedirectsReached if request.max_redirects.zero?
        new_args[:password] = request.password
        new_args[:user] = request.user
        new_args[:headers] = request.headers
        new_args[:max_redirects] = request.max_redirects - 1

        # TODO: figure out what to do with original :cookie, :cookies values
        new_args[:cookies] = get_redirection_cookies(request, result, new_args)
      end

      Request.execute(new_args, &block)
    end

    # Returns cookies which should be passed when following redirect
    #
    # @param request [RestClient::Request] Original request
    # @param result [Net::HTTPResponse] Response
    # @param args [Hash] Original arguments
    # @return [Hash] Cookies to be passsed when following redirect
    def get_redirection_cookies(request, _result, _args)
      request.cookies
    end
  end
end

module GoodData
  module Rest
    # Wrapper of low-level HTTP/REST client/library
    class Connection
      include MonitorMixin

      DEFAULT_URL = 'https://secure.gooddata.com'
      LOGIN_PATH = '/gdc/account/login'
      TOKEN_PATH = '/gdc/account/token'
      KEYS_TO_SCRUB = [:password, :verifyPassword, :authorizationToken]

      ID_LENGTH = 16

      DEFAULT_HEADERS = {
        :content_type => :json,
        :accept => [:json, :zip],
        :user_agent => GoodData.gem_version_string
      }

      DEFAULT_WEBDAV_HEADERS = {
        :user_agent => GoodData.gem_version_string
      }

      DEFAULT_LOGIN_PAYLOAD = {
        :headers => DEFAULT_HEADERS,
        :verify_ssl => true
      }

      RETRYABLE_ERRORS = [
        Net::HTTPBadResponse,
        RestClient::InternalServerError,
        RestClient::RequestTimeout,
        RestClient::MethodNotAllowed,
        SystemCallError,
        Timeout::Error
      ]

      RETRIES_ON_TOO_MANY_REQUESTS_ERROR = 12
      RETRY_TIME_INITIAL_VALUE = 1
      RETRY_TIME_COEFFICIENT = 1.5
      RETRYABLE_ERRORS << Net::ReadTimeout if Net.const_defined?(:ReadTimeout)

      class << self
        def construct_login_payload(username, password)
          res = {
            'postUserLogin' => {
              'login' => username,
              'password' => password,
              'remember' => 1,
              'verify_level' => 2
            }
          }
          res
        end

        # Generate random string with URL safe base64 encoding
        #
        # @param [String] length Length of random string to be generated
        #
        # @return [String] Generated random string
        def generate_string(length = ID_LENGTH)
          SecureRandom.urlsafe_base64(length)
        end

        # Retry block if exception thrown
        def retryable(options = {}, &_block)
          opts = { :tries => 1, :on => RETRYABLE_ERRORS }.merge(options)

          retry_exception = opts[:on]
          retries = opts[:tries]
          too_many_requests_tries = RETRIES_ON_TOO_MANY_REQUESTS_ERROR

          unless retry_exception.is_a?(Array)
            retry_exception = [retry_exception]
          end

          retry_time = RETRY_TIME_INITIAL_VALUE
          begin
            return yield
          rescue RestClient::Unauthorized, RestClient::Forbidden => e # , RestClient::Unauthorized => e
            raise e unless options[:refresh_token]
            raise e if options[:dont_reauth]
            options[:refresh_token].call # (dont_reauth: true)
            retry if (retries -= 1) > 0
          rescue RestClient::TooManyRequests, RestClient::ServiceUnavailable
            GoodData.logger.warn "Too many requests, retrying in #{retry_time} seconds"
            sleep retry_time
            retry_time *= RETRY_TIME_COEFFICIENT
            # 10 requests with 1.5 coefficent should take ~ 3 mins to finish
            retry if (too_many_requests_tries -= 1) > 1
          rescue *retry_exception => e
            GoodData.logger.warn e.inspect
            retry if (retries -= 1) > 1
          end
          yield
        end
      end

      attr_reader :request_params

      # backward compatibility
      alias_method :cookies, :request_params
      alias_method :headers, :request_params
      attr_reader :server
      attr_reader :stats
      attr_reader :user
      attr_reader :verify_ssl

      def initialize(opts)
        super()
        @stats = Concurrent::Hash.new

        headers = opts[:headers] || {}
        @webdav_headers = DEFAULT_WEBDAV_HEADERS.merge(headers)

        @user = nil
        @server = nil
        @opts = opts
        @verify_ssl = @opts[:verify_ssl] == false || @opts[:verify_ssl] == OpenSSL::SSL::VERIFY_NONE ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER

        # Initialize headers
        reset_headers!

        @at_exit_handler_installed = nil
      end

      # Connect using username and password
      def connect(username, password, options = {})
        server = options[:server] || Helpers::AuthHelper.read_server
        options = DEFAULT_LOGIN_PAYLOAD.merge(options)
        headers = options[:headers] || {}

        options = options.merge(headers)
        @server = RestClient::Resource.new server, options

        # Install at_exit handler first
        unless @at_exit_handler_installed
          begin
            at_exit { disconnect if @user }
          rescue RestClient::Unauthorized
            GoodData.logger.info 'Already logged out'
          ensure
            @at_exit_handler_installed = true
          end
        end

        # Reset old cookies first
        if options[:sst_token]
          merge_headers!(:x_gdc_authsst => options[:sst_token])
          get('/gdc/account/token', @request_params)

          @user = get(get('/gdc/app/account/bootstrap')['bootstrapResource']['accountSetting']['links']['self'])
          GoodData.logger.info("Connected using SST to server #{@server.url} to profile \"#{@user['accountSetting']['login']}\"")
          @auth = {}
          refresh_token :dont_reauth => true
        else
          GoodData.logger.info("Connected using username \"#{username}\" to server #{@server.url}")
          credentials = Connection.construct_login_payload(username, password)
          generate_session_id
          @auth = post(LOGIN_PATH, credentials, :dont_reauth => true)['userLogin']

          refresh_token :dont_reauth => true
          @user = get(@auth['profile'])
        end
        GoodData.logger.info('Connection successful')
      rescue RestClient::Unauthorized => e
        GoodData.logger.info('Bad Login or Password')
        GoodData.logger.info('Connection failed')
        raise e
      rescue RestClient::Forbidden => e
        GoodData.logger.info('Connection failed')
        raise e
      end

      # Disconnect
      def disconnect
        # TODO: Wrap somehow
        url = @auth['state']

        begin
          clear_session_id
          delete(url, :x_gdc_authsst => sst_token) if url
        rescue RestClient::Unauthorized
          GoodData.logger.info 'Already disconnected'
        end

        @auth = nil
        @server = nil
        @user = nil

        reset_headers!
      end

      def download(what, where, options = {})
        # handle the path (directory) given in what
        ilast_slash = what.rindex('/')
        if ilast_slash.nil?
          what_dir = ''
        else
          # take the directory from the path
          what_dir = what[0..ilast_slash - 1]
          # take the filename from the path
          what = what[ilast_slash + 1..-1]
        end

        option_dir = options[:directory] || ''
        option_dir = option_dir[0..-2] if option_dir[-1] == '/'

        # join the otion dir with the what_dir
        # [option dir empty, what dir empty] => the joined dir
        dir_hash = {
          [true, true] => '',
          [true, false] => what_dir,
          [false, true] => option_dir,
          [false, false] => "#{what_dir}/#{option_dir}"
        }
        dir = dir_hash[[option_dir.empty?, what_dir.empty?]]

        staging_uri = options[:staging_url].to_s

        base_url = dir.empty? ? staging_uri : URI.join("#{server}", staging_uri, "#{dir}/").to_s
        url = URI.join("#{server}", base_url, CGI.escape(what)).to_s

        b = proc do |f|
          raw = {
            :headers => @webdav_headers.merge(:x_gdc_authtt => headers[:x_gdc_authtt]),
            :method => :get,
            :url => url,
            :verify_ssl => verify_ssl
          }
          RestClient::Request.execute(raw) do |chunk, _x, response|
            if response.code.to_s != '200'
              fail ArgumentError, "Error downloading #{url}. Got response: #{response.code} #{response} #{response.body}"
            end
            f.write chunk
          end
        end

        GoodData::Rest::Connection.retryable(:tries => Helpers::GD_MAX_RETRY, :refresh_token => proc { refresh_token }) do
          if where.is_a?(IO) || where.is_a?(StringIO)
            b.call(where)
          else
            # Assume it is a string or file
            File.open(where, 'w') do |f|
              b.call(f)
            end
          end
        end
      end

      def refresh_token(_options = {})
        begin # rubocop:disable RedundantBegin
          # avoid infinite loop GET fails with 401
          response = get(TOKEN_PATH, :x_gdc_authsst => sst_token, :dont_reauth => true)
          # Remove when TT sent in headers. Currently we need to parse from body
          merge_headers!(:x_gdc_authtt => GoodData::Helpers.get_path(response, %w(userToken token)))
        rescue Exception => e # rubocop:disable RescueException
          puts e.message
          raise e
        end
      end

      # Returns server URI
      #
      # @return [String] server uri
      def server_url
        @server && @server.url
      end

      # HTTP DELETE
      #
      # @param uri [String] Target URI
      def delete(uri, options = {})
        request(:delete, uri, nil, options)
      end

      # Helper for logging error
      #
      # @param e [RuntimeException] Exception to log
      # @param uri [String] Uri on which the request failed
      # @param params [Hash] Additional params
      def log_error(e, uri, params, options = {})
        return if e.response && e.response.code == 401 && !uri.include?('token') && !uri.include?('login')

        if options[:do_not_log].nil? || options[:do_not_log].index(e.class).nil?
          GoodData.logger.error(format_error(e, params))
        end
      end

      def request(method, uri, data, options = {}, &user_block)
        request_id = options[:request_id] || generate_request_id
        log_info(options.merge(request_id: request_id))
        payload = data.is_a?(Hash) ? data.to_json : data

        GoodData.rest_logger.info "#{method.to_s.upcase}: #{@server.url}#{uri}, #{scrub_params(data, KEYS_TO_SCRUB)}"
        profile "#{method.to_s.upcase} #{uri}" do
          b = proc do
            params = fresh_request_params(request_id).merge(options)
            begin
              case method
              when :get
                @server[uri].get(params, &user_block)
              when :put
                @server[uri].put(payload, params)
              when :delete
                @server[uri].delete(params)
              when :post
                @server[uri].post(payload, params)
              end
            rescue RestClient::Exception => e
              log_error(e, uri, params, options)
              raise e
            end
          end
          process_response(options, &b)
        end
      end

      # HTTP GET
      #
      # @param uri [String] Target URI
      def get(uri, options = {}, &user_block)
        request(:get, uri, nil, options, &user_block)
      end

      # HTTP PUT
      #
      # @param uri [String] Target URI
      def put(uri, data, options = {})
        request(:put, uri, data, options)
      end

      # HTTP POST
      #
      # @param uri [String] Target URI
      def post(uri, data = nil, options = {})
        request(:post, uri, data, options)
      end

      # Reader method for SST token
      #
      # @return uri [String] SST token
      def sst_token
        request_params[:x_gdc_authsst]
      end

      def stats_table(values = stats)
        sorted = values.sort_by { |_k, v| v[:avg] }
        Terminal::Table.new :headings => %w(title avg min max total calls) do |t|
          overall = {
            :avg => 0,
            :calls => 0,
            :total => 0
          }

          sorted.each do |l|
            avg = l[1][:avg]
            min = l[1][:min]
            max = l[1][:max]
            total = l[1][:total]
            calls = l[1][:calls]

            row = [
              l[0],
              sprintf('%.3f', avg),
              sprintf('%.3f', min),
              sprintf('%.3f', max),
              sprintf('%.3f', total),
              calls
            ]

            overall[:min] = min if overall[:min].nil? || min < overall[:min]
            overall[:max] = max if overall[:max].nil? || max > overall[:max]
            overall[:total] += total
            overall[:calls] += calls
            overall[:avg] += avg

            t.add_row row
          end

          overall[:avg] = overall[:avg] / sorted.length
          row = [
            'TOTAL',
            sprintf('%.3f', overall[:avg]),
            sprintf('%.3f', overall[:min]),
            sprintf('%.3f', overall[:max]),
            sprintf('%.3f', overall[:total]),
            overall[:calls]
          ]

          t.add_row :separator
          t.add_row row
        end
      end

      # Reader method for TT token
      #
      # @return uri [String] TT token
      def tt_token
        request_params[:x_gdc_authtt]
      end

      # Uploads a file to GoodData server

      def upload(file, options = {})
        dir = options[:directory] || ''
        staging_uri = options[:staging_url].to_s
        url = dir.empty? ? staging_uri : URI.join("#{server}", staging_uri, "#{dir}/").to_s
        # Make a directory, if needed
        create_webdav_dir_if_needed url unless dir.empty?

        webdav_filename = options[:filename] || File.basename(file)
        do_stream_file URI.join("#{server}", url, CGI.escape(webdav_filename)), file
      end

      def generate_request_id
        "#{session_id}:#{call_id}"
      end

      private

      def create_webdav_dir_if_needed(url)
        return if webdav_dir_exists?(url)

        method = :mkcol
        b = proc do
          raw = {
            :method => method,
            :url => url,
            :headers => @webdav_headers.merge(:x_gdc_authtt => headers[:x_gdc_authtt]),
            :verify_ssl => verify_ssl
          }
          RestClient::Request.execute(raw)
        end

        GoodData::Rest::Connection.retryable(:tries => Helpers::GD_MAX_RETRY, :refresh_token => proc { refresh_token }) do
          b.call
        end
      end

      def do_stream_file(uri, filename, _options = {})
        GoodData.logger.info "Uploading file user storage #{uri}"

        request = RestClient::Request.new(:method => :put,
                                          :url => uri.to_s,
                                          :verify_ssl => verify_ssl,
                                          :headers => @webdav_headers.merge(:x_gdc_authtt => headers[:x_gdc_authtt]),
                                          :payload => File.new(filename, 'rb'))

        begin
          request.execute
        rescue => e
          GoodData.logger.error("Error when uploading file #{filename}", e)
          raise e
        end
      end

      def format_error(e, params = {})
        return e unless e.respond_to?(:response)
        error = MultiJson.load(e.response)
        message = GoodData::Helpers.interpolate_error_message(error)
        if error && error['error'] && error['error']['errorClass'] == 'com.gooddata.security.authorization.AuthorizationFailedException'
          message = "#{message}, accessing with #{user['accountSetting']['login']}"
        end
        <<-ERR

#{e}: #{message}
Request ID: #{params[:x_gdc_request]}
Full response:
#{JSON.pretty_generate(error)}
Backtrace:\n#{e.backtrace.join("\n")}
ERR
      rescue MultiJson::ParseError
        "Failed to parse #{e}. Raw response: #{e.response}"
      end

      # generate session id to be passed as the first part to
      # x_gdc_request header
      def session_id
        @session_id ||= Connection.generate_string
      end

      def call_id
        Connection.generate_string
      end

      def generate_session_id
        @session_id = Connection.generate_string
      end

      def clear_session_id
        @session_id = nil
      end

      # log info_message given in options and make sure request_id is there
      def log_info(options)
        # if info_message given, log it with request_id (given or generated)
        if options[:info_message]
          GoodData.logger.info "#{options[:info_message]} Request id: #{options[:request_id]}"
        end
      end

      # request heders with freshly generated request id
      def fresh_request_params(request_id = nil)
        tt = { :x_gdc_authtt => tt_token }
        tt.merge(:x_gdc_request => request_id || generate_request_id)
      end

      def merge_headers!(headers)
        @request_params.merge! headers.slice(:x_gdc_authtt, :x_gdc_authsst)
      end

      def process_response(options = {}, &block)
        retries = options[:tries] || Helpers::GD_MAX_RETRY
        process = options[:process]
        dont_reauth = options[:dont_reauth]
        options = options.reject { |k, _| [:process, :dont_reauth].include?(k) }
        opts = { tries: retries, refresh_token: proc { refresh_token unless dont_reauth } }.merge(options)
        response = GoodData::Rest::Connection.retryable(opts) do
          block.call
        end
        merge_headers! response.headers
        content_type = response.headers[:content_type]
        return response if process == false

        if content_type == 'application/json' || content_type == 'application/json;charset=UTF-8'
          result = response.to_str == '""' ? {} : MultiJson.load(response.to_str)
          GoodData.rest_logger.debug "Request ID: #{response.headers[:x_gdc_request]} - Response: #{result.inspect}"
        elsif ['text/plain;charset=UTF-8', 'text/plain; charset=UTF-8', 'text/plain'].include?(content_type)
          result = response
          GoodData.rest_logger.debug 'Response: plain text'
        elsif content_type == 'application/zip'
          result = response
          GoodData.rest_logger.debug 'Response: a zipped stream'
        elsif response.headers[:content_length].to_s == '0'
          result = nil
          GoodData.rest_logger.debug 'Response: Empty response possibly 204'
        elsif response.code == 204
          result = nil
          GoodData.rest_logger.debug 'Response: 204 no content'
        else
          fail "Unsupported response content type '%s':\n%s" % [content_type, response.to_str[0..127]]
        end
        result
      rescue RestClient::Exception => e
        GoodData.logger.error "Response: #{e.response}"
        raise $ERROR_INFO
      end

      def profile(title, &block)
        t1 = Time.now
        res = block.call
        t2 = Time.now
        delta = t2 - t1

        update_stats title, delta
        res
      end

      def reset_headers!
        @request_params = {}
      end

      def scrub_params(params, keys)
        keys = keys.reduce([]) { |acc, elem| acc.concat([elem.to_s, elem.to_sym]) }

        new_params = GoodData::Helpers.deep_dup(params)
        GoodData::Helpers.hash_dfs(new_params) do |k, _key|
          keys.each do |key_to_scrub|
            k[key_to_scrub] = ('*' * k[key_to_scrub].length) if k && k.key?(key_to_scrub) && k[key_to_scrub]
          end
        end
        new_params
      end

      # TODO: Store PH_MAP for wildcarding of URLs in reports in separate file
      PH_MAP = [
        ['/gdc/account/profile/{id}', %r{/gdc/account/profile/[\w]+}],
        ['/gdc/account/login/{id}', %r{/gdc/account/login/[\w]+}],
        ['/gdc/account/domains/{id}/users?login={login}', %r{/gdc/account/domains/[\w\d-]+/users\?login=[^&$]+}],
        ['/gdc/account/domains/{id}', %r{/gdc/account/domains/[\w\d-]+}],

        ['/gdc/projects/{id}/execute', %r{/gdc/projects/[\w]+/execute}],

        ['/gdc/datawarehouse/instances/{id}', %r{/gdc/datawarehouse/instances/[\w]+}],
        ['/gdc/datawarehouse/executions/{id}', %r{/gdc/datawarehouse/executions/[\w]+}],

        ['/gdc/domains/{id}/segments/{segment}/synchronizeClients/results/{result}/details?offset={offset}&limit={limit}',
         %r{/gdc/domains/[\w-]+/segments/[\w-]+/synchronizeClients/results/[\w]+/details/\?offset=[\d]+&limit=[\d]+}],
        ['/gdc/domains/{id}/segments/{segment}/synchronizeClients/results/{result}',
         %r{/gdc/domains/[\w-]+/segments/[\w-]+/synchronizeClients/results/[\w]+}],
        ['/gdc/domains/{id}/segments/{segment}/', %r{/gdc/domains/[\w-]+/segments/[\w-]+/}],
        ['/gdc/domains/{id}/segments/{segment}', %r{/gdc/domains/[\w-]+/segments/[\w-]+}],
        ['/gdc/domains/{id}/clients?segment={segment}', %r{/gdc/domains/[\w-]+/clients\?segment=[\w-]+}],
        ['/gdc/domains/{id}/clients/{client_id}/settings/lcm.title', %r{/gdc/domains/[\w-]+/clients/[\w-]+/settings/lcm.title}],
        ['/gdc/domains/{id}/clients/{client_id}/settings/lcm.token', %r{/gdc/domains/[\w-]+/clients/[\w-]+/settings/lcm.token}],
        ['/gdc/domains/{id}/clients/{client_id}', %r{/gdc/domains/[\w-]+/clients/[\w-]+}],
        ['/gdc/domains/{id}/provisionClientProjects/results/{result}/details?offset={offset}&limit={limit}',
         %r{/gdc/domains/[\w-]+/provisionClientProjects/results/[\w]+/details/\?offset=[\d]+&limit=[\d]+}],
        ['/gdc/domains/{id}/provisionClientProjects/results/{result}', %r{/gdc/domains/[\w-]+/provisionClientProjects/results/[\w]+}],
        ['/gdc/domains/{id}/provisionClientProjects', %r{/gdc/domains/[\w-]+/provisionClientProjects}],
        ['/gdc/domains/{id}/updateClients', %r{/gdc/domains/[\w-]+/updateClients}],
        ['/gdc/domains/{id}/', %r{/gdc/domains/[\w-]+/}],

        ['/gdc/exporter/result/{id}/{id}', %r{/gdc/exporter/result/[\w]+/[\w]+}],

        ['/gdc/internal/lcm/domains/{id}/dataproducts/{data_product}/segments/{segment}/syncProcesses/{process}',
         %r{/gdc/internal/lcm/domains/[\w-]+/dataproducts/[\w-]+/segments/[\w-]+/syncProcesses/[\w]+}],
        ['/gdc/internal/lcm/domains/{id}/dataproducts/{data_product}/segments/{segment}/syncProcesses',
         %r{/gdc/internal/lcm/domains/[\w-]+/dataproducts/[\w-]+/segments/[\w-]+/syncProcesses}],

        ['/gdc/internal/projects/{id}/objects/setPermissions', %r{/gdc/internal/projects/[\w]+/objects/setPermissions}],

        ['/gdc/md/{id}/variables/item/{id}', %r{/gdc/md/[\w]+/variables/item/[\d]+}],
        ['/gdc/md/{id}/validate/task/{id}', %r{/gdc/md/[\w]+/validate/task/[\w]+}],
        ['/gdc/md/{id}/using2/{id}/{id}', %r{/gdc/md/[\w]+/using2/[\d]+/[\d]+}],
        ['/gdc/md/{id}/using2/{id}', %r{/gdc/md/[\w]+/using2/[\d]+}],
        ['/gdc/md/{id}/userfilters?users={users}', %r{/gdc/md/[\w]+/userfilters\?users=[/\w]+}],
        ['/gdc/md/{id}/userfilters?count={count}&offset={offset}', %r{/gdc/md/[\w]+/userfilters\?count=[\d]+&offset=[\d]+}],
        ['/gdc/md/{id}/usedby2/{id}/{id}', %r{/gdc/md/[\w]+/usedby2/[\d]+/[\d]+}],
        ['/gdc/md/{id}/usedby2/{id}', %r{/gdc/md/[\w]+/usedby2/[\d]+}],
        ['/gdc/md/{id}/tasks/{id}/status', %r{/gdc/md/[\w]+/tasks/[\w]+/status}],
        ['/gdc/md/{id}/obj/{id}/validElements', %r{/gdc/md/[\w]+/obj/[\d]+/validElements(/)?(\?.*)?}],
        ['/gdc/md/{id}/obj/{id}/elements', %r{/gdc/md/[\w]+/obj/[\d]+/elements(/)?(\?.*)?}],
        ['/gdc/md/{id}/obj/{id}', %r{/gdc/md/[\w]+/obj/[\d]+}],
        ['/gdc/md/{id}/etltask/{id}', %r{/gdc/md/[\w]+/etltask/[\w]+}],
        ['/gdc/md/{id}/dataResult/{id}', %r{/gdc/md/[\w]+/dataResult/[\d]+}],
        ['/gdc/md/{id}', %r{/gdc/md/[\w]+}],

        ['/gdc/projects/{id}/users/{id}/roles', %r{/gdc/projects/[\w]+/users/[\w]+/roles}],
        ['/gdc/projects/{id}/users/{id}/permissions', %r{/gdc/projects/[\w]+/users/[\w]+/permissions}],
        ['/gdc/projects/{id}/users', %r{/gdc/projects/[\w]+/users}],
        ['/gdc/projects/{id}/schedules/{id}/executions/{id}', %r{/gdc/projects/[\w]+/schedules/[\w]+/executions/[\w]+}],
        ['/gdc/projects/{id}/schedules/{id}', %r{/gdc/projects/[\w]+/schedules/[\w]+}],
        ['/gdc/projects/{id}/roles/{id}', %r{/gdc/projects/[\w]+/roles/[\d]+}],
        ['/gdc/projects/{id}/model/view/{id}', %r{/gdc/projects/[\w]+/model/view/[\w]+}],
        ['/gdc/projects/{id}/model/view', %r{/gdc/projects/[\w]+/model/view}],
        ['/gdc/projects/{id}/model/diff/{id}', %r{/gdc/projects/[\w]+/model/diff/[\w]+}],
        ['/gdc/projects/{id}/model/diff', %r{/gdc/projects/[\w]+/model/diff}],
        ['/gdc/projects/{id}/dataload/processes/{id}/executions/{id}', %r{/gdc/projects/[\w]+/dataload/processes/[\w-]+/executions/[\w-]+}],
        ['/gdc/projects/{id}/dataload/processes/{id}', %r{/gdc/projects/[\w]+/dataload/processes/[\w-]+}],
        ['/gdc/projects/{id}/', %r{/gdc/projects/[\w]+/}],
        ['/gdc/projects/{id}', %r{/gdc/projects/[\w]+}]
      ]

      def update_stats(title, delta)
        synchronize do
          orig_title = title

          placeholders = true

          if placeholders
            PH_MAP.each do |pm|
              break if title.gsub!(pm[1], pm[0])
            end
          end

          stat = stats[title]
          if stat.nil?
            stat = {
              :min => delta,
              :max => delta,
              :total => 0,
              :avg => 0,
              :calls => 0,
              :entries => []
            }
          end

          stat[:min] = delta if delta < stat[:min]
          stat[:max] = delta if delta > stat[:max]
          stat[:total] += delta
          stat[:calls] += 1
          stat[:avg] = stat[:total] / stat[:calls]

          stat[:entries] << orig_title if placeholders

          stats[title] = stat
        end
      end

      def webdav_dir_exists?(url)
        method = :get
        GoodData.logger.debug "#{method}: #{url}"

        GoodData::Rest::Connection.retryable(:tries => Helpers::GD_MAX_RETRY, :refresh_token => proc { refresh_token }) do
          raw = {
            :method => method,
            :url => url,
            :headers => @webdav_headers.merge(:x_gdc_authtt => headers[:x_gdc_authtt]),
            :verify_ssl => verify_ssl
          }.merge(headers)
          begin
            RestClient::Request.execute(raw)
          rescue RestClient::Exception => e
            false if e.http_code == 404
          end
        end
      end
    end
  end
end
