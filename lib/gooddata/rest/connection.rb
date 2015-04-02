# encoding: utf-8

require 'terminal-table'

require_relative '../version'
require_relative '../exceptions/exceptions'

module GoodData
  module Rest
    # Wrapper of low-level HTTP/REST client/library
    class Connection
      DEFAULT_URL = 'https://secure.gooddata.com'
      LOGIN_PATH = '/gdc/account/login'
      TOKEN_PATH = '/gdc/account/token'
      KEYS_TO_SCRUB = [:password, :verifyPassword, :authorizationToken]

      DEFAULT_HEADERS = {
        :content_type => :json,
        :accept => [:json, :zip],
        :user_agent => GoodData.gem_version_string
      }

      DEFAULT_LOGIN_PAYLOAD = {
        :headers => DEFAULT_HEADERS,
        :verify_ssl => OpenSSL::SSL::VERIFY_NONE
      }

      RETRYABLE_ERRORS = [
        RestClient::InternalServerError,
        RestClient::RequestTimeout,
        RestClient::MethodNotAllowed,
        SystemCallError,
        Timeout::Error
      ]

      RETRYABLE_ERRORS << Net::ReadTimeout if Net.const_defined?(:ReadTimeout)

      class << self
        def construct_login_payload(username, password)
          res = {
            'postUserLogin' => {
              'login' => username,
              'password' => password,
              'remember' => 1
            }
          }
          res
        end

        # Retry block if exception thrown
        def retryable(options = {}, &_block)
          opts = { :tries => 1, :on => RETRYABLE_ERRORS }.merge(options)

          retry_exception, retries = opts[:on], opts[:tries]

          unless retry_exception.is_a?(Array)
            retry_exception = [retry_exception]
          end

          retry_time = 1
          begin
            return yield
          rescue RestClient::Unauthorized, RestClient::Forbidden => e # , RestClient::Unauthorized => e
            raise e unless options[:refresh_token]
            raise e if options[:dont_reauth]
            options[:refresh_token].call # (dont_reauth: true)
            retry if (retries -= 1) > 0
          rescue RestClient::TooManyRequests
            GoodData.logger.warn "Too many requests, retrying in #{retry_time} seconds"
            sleep retry_time
            retry_time *= 1.5
            retry
          rescue *retry_exception => e
            GoodData.logger.warn e.inspect
            retry if (retries -= 1) > 0
          end

          yield
        end
      end

      attr_reader :cookies
      attr_reader :stats
      attr_reader :user

      def initialize(opts)
        @stats = {}
        @opts = opts

        @headers = DEFAULT_HEADERS.dup
        @user = nil
        @server = nil

        @opts = opts
        headers = opts[:headers] || {}
        @headers.merge! headers

        # Initialize cookies
        reset_cookies!

        @at_exit_handler_installed = nil
      end

      # Connect using username and password
      def connect(username, password, options = {})
        server = options[:server] || DEFAULT_URL
        @server = RestClient::Resource.new server, DEFAULT_LOGIN_PAYLOAD

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
          merge_cookies!('GDCAuthSST' => options[:sst_token])
          @user = get(get('/gdc/app/account/bootstrap')['bootstrapResource']['accountSetting']['links']['self'])
          @auth = {}
          refresh_token :dont_reauth => true
        else
          credentials = Connection.construct_login_payload(username, password)
          @auth = post(LOGIN_PATH, credentials)['userLogin']

          refresh_token :dont_reauth => true
          @user = get(@auth['profile'])
        end
      end

      # Disconnect
      def disconnect
        # TODO: Wrap somehow
        url = @auth['state']

        begin
          delete url if url
        rescue RestClient::Unauthorized
          GoodData.logger.info 'Already disconnected'
        end

        @auth = nil
        @server = nil
        @user = nil

        reset_cookies!
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

        base_url = dir.empty? ? staging_uri : URI.join(staging_uri, "#{dir}/").to_s
        url = URI.join(base_url, CGI.escape(what)).to_s

        b = proc do
          raw = {
            :headers => {
              :user_agent => GoodData.gem_version_string
            },
            :method => :get,
            :url => url
          }.merge(cookies)

          if where.is_a?(IO)
            RestClient::Request.execute(raw) do |chunk, _x, response|
              if response.code.to_s != '200'
                fail ArgumentError, "Error downloading #{url}. Got response: #{response.code} #{response} #{response.body}"
              end
              where.write chunk
            end
          else
            # Assume it is a string or file
            File.open(where, 'w') do |f|
              RestClient::Request.execute(raw) do |chunk, _x, response|
                if response.code.to_s != '200'
                  fail ArgumentError, "Error downloading #{url}. Got response: #{response.code} #{response} #{response.body}"
                end
                f.write chunk
              end
            end
          end
        end

        res = nil
        GoodData::Rest::Connection.retryable(:tries => 2, :refresh_token => proc { refresh_token }) do
          res = b.call
        end
        res
      end

      def refresh_token(_options = {})
        begin # rubocop:disable RedundantBegin
          get TOKEN_PATH, :dont_reauth => true # avoid infinite loop GET fails with 401
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
        GoodData.logger.debug "DELETE: #{@server.url}#{uri}"
        profile "DELETE #{uri}" do
          b = proc { @server[uri].delete cookies }
          process_response(options, &b)
        end
      end

      # HTTP GET
      #
      # @param uri [String] Target URI
      def get(uri, options = {}, &user_block)
        GoodData.logger.debug "GET: #{@server.url}#{uri}"
        profile "GET #{uri}" do
          b = proc { @server[uri].get(cookies, &user_block) }
          process_response(options, &b)
        end
      end

      # HTTP PUT
      #
      # @param uri [String] Target URI
      def put(uri, data, options = {})
        payload = data.is_a?(Hash) ? data.to_json : data
        GoodData.logger.debug "PUT: #{@server.url}#{uri}, #{scrub_params(data, KEYS_TO_SCRUB)}"
        profile "PUT #{uri}" do
          b = proc { @server[uri].put payload, cookies }
          process_response(options, &b)
        end
      end

      # HTTP POST
      #
      # @param uri [String] Target URI
      def post(uri, data, options = {})
        GoodData.logger.debug "POST: #{@server.url}#{uri}, #{scrub_params(data, KEYS_TO_SCRUB)}"
        profile "POST #{uri}" do
          payload = data.is_a?(Hash) ? data.to_json : data
          b = proc { @server[uri].post payload, cookies }
          process_response(options, &b)
        end
      end

      # Reader method for SST token
      #
      # @return uri [String] SST token
      def sst_token
        cookies[:cookies]['GDCAuthSST']
      end

      def stats_table(values = stats)
        sorted = values.sort_by { |_k, v| v[:avg] }
        Terminal::Table.new :headings => %w(title avg min max total calls) do |t|
          sorted.each do |l|
            row = [
              l[0],
              sprintf('%.3f', l[1][:avg]),
              sprintf('%.3f', l[1][:min]),
              sprintf('%.3f', l[1][:max]),
              sprintf('%.3f', l[1][:total]),
              l[1][:calls]
            ]
            t.add_row row
          end
        end
      end

      # Reader method for TT token
      #
      # @return uri [String] TT token
      def tt_token
        cookies[:cookies]['GDCAuthTT']
      end

      # Uploads a file to GoodData server
      def upload(file, options = {})
        def do_stream_file(uri, filename, _options = {})
          puts "uploading the file #{uri}"

          to_upload = File.new(filename)
          cookies_str = cookies[:cookies].map { |cookie| "#{cookie[0]}=#{cookie[1]}" }.join(';')
          req = Net::HTTP::Put.new(uri.path, 'User-Agent' => GoodData.gem_version_string, 'Cookie' => cookies_str)
          req.content_length = to_upload.size
          req.body_stream = to_upload
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE

          response = nil
          GoodData::Rest::Connection.retryable(:tries => 2, :refresh_token => proc { refresh_token }) do
            response = http.start { |client| client.request(req) }
          end
          response
        end

        def webdav_dir_exists?(url)
          method = :get
          GoodData.logger.debug "#{method}: #{url}"

          b = proc do
            raw = {
              :method => method,
              :url => url,
              :headers => @headers
            }
            begin
              RestClient::Request.execute(raw.merge(cookies))
            rescue RestClient::Exception => e
              false if e.http_code == 404
            end
          end

          res = nil
          GoodData::Rest::Connection.retryable(:tries => 2, :refresh_token => proc { refresh_token }) do
            res = b.call
          end
          res
        end

        def create_webdav_dir_if_needed(url)
          return if webdav_dir_exists?(url)

          method = :mkcol
          GoodData.logger.debug "#{method}: #{url}"
          b = proc do
            raw = {
              :method => method,
              :url => url,
              :headers => @headers
            }.merge(cookies)
            RestClient::Request.execute(raw)
          end

          GoodData::Rest::Connection.retryable(:tries => 2, :refresh_token => proc { refresh_token }) do
            b.call
          end
        end

        dir = options[:directory] || ''
        staging_uri = options[:staging_url].to_s
        url = dir.empty? ? staging_uri : URI.join(staging_uri, "#{dir}/").to_s

        # Make a directory, if needed
        create_webdav_dir_if_needed url unless dir.empty?

        webdav_filename = options[:filename] || File.basename(file)
        do_stream_file URI.join(url, CGI.escape(webdav_filename)), file
      end

      private

      def merge_cookies!(cookies)
        @cookies[:cookies].merge! cookies
      end

      def process_response(options = {}, &block)
        # begin
        #   # Simply try again when ConnectionReset, ConnectionRefused etc.. (see e.g. MSF-7591)
        #   response = GoodData::Rest::Connection.retryable(:tries => 2, :refresh_token => Proc.new { refresh_token }) do
        #     block.call
        #   end
        # rescue RestClient::Unauthorized
        #   raise $ERROR_INFO if options[:dont_reauth]
        #   GoodData::Rest::Connection.retryable(:tries => 2) do
        #     refresh_token
        #     response = block.call
        #   end
        # end

        response = GoodData::Rest::Connection.retryable(:tries => 2, :refresh_token => proc { refresh_token unless options[:dont_reauth] }) do
          block.call
        end

        merge_cookies! response.cookies
        content_type = response.headers[:content_type]
        return response if options[:process] == false

        if content_type == 'application/json' || content_type == 'application/json;charset=UTF-8'
          result = response.to_str == '""' ? {} : MultiJson.load(response.to_str)
          GoodData.logger.debug "Request ID: #{response.headers[:x_gdc_request]} - Response: #{result.inspect}"
        elsif ['text/plain;charset=UTF-8', 'text/plain; charset=UTF-8', 'text/plain'].include?(content_type)
          result = response
          GoodData.logger.debug 'Response: plain text'
        elsif content_type == 'application/zip'
          result = response
          GoodData.logger.debug 'Response: a zipped stream'
        elsif response.headers[:content_length].to_s == '0'
          result = nil
          GoodData.logger.debug 'Response: Empty response possibly 204'
        elsif response.code == 204
          result = nil
          GoodData.logger.debug 'Response: 204 no content'
        else
          fail "Unsupported response content type '%s':\n%s" % [content_type, response.to_str[0..127]]
        end
        result
      rescue RestClient::Exception => e
        GoodData.logger.debug "Response: #{e.response}"
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

      def reset_cookies!
        @cookies = { :cookies => {} }
      end

      def scrub_params(params, keys)
        keys = keys.reduce([]) { |a, e| a.concat([e.to_s, e.to_sym]) }

        new_params = params.deep_dup
        GoodData::Helpers.hash_dfs(new_params) do |k, _key|
          keys.each do |key_to_scrub|
            k[key_to_scrub] = ('*' * k[key_to_scrub].length) if k && k.key?(key_to_scrub) && k[key_to_scrub]
          end
        end
        new_params
      end

      # TODO: Store PH_MAP for wildcarding of URLs in reports in separate file
      PH_MAP = [
        ['/gdc/projects/{id}/users/{id}/permissions', %r{/gdc/projects/[\w]+/users/[\w]+/permissions}],
        ['/gdc/projects/{id}/roles/{id}', %r{/gdc/projects/[\w]+/roles/[\d]+}],
        ['/gdc/projects/{id}/model/diff/{id}', %r{/gdc/projects/[\w]+/model/diff/[\w]+}],
        ['/gdc/projects/{id}/', %r{/gdc/projects/[\w]+/}],
        ['/gdc/projects/{id}', %r{/gdc/projects/[\w]+}],
        ['/gdc/md/{id}/using2/{id}/{id}', %r{/gdc/md/[\w]+/using2/[\d]+/[\d]+}],
        ['/gdc/md/{id}/usedby2/{id}/{id}', %r{/gdc/md/[\w]+/usedby2/[\d]+/[\d]+}],
        ['/gdc/md/{id}/tasks/{id}/status', %r{/gdc/md/[\w]+/tasks/[\w]+/status}],
        ['/gdc/md/{id}/obj/{id}/validElements', %r{/gdc/md/[\w]+/obj/[\d]+/validElements(/)?(\?.*)?}],
        ['/gdc/md/{id}/obj/{id}/elements', %r{/gdc/md/[\w]+/obj/[\d]+/elements(/)?(\?.*)?}],
        ['/gdc/md/{id}/obj/{id}', %r{/gdc/md/[\w]+/obj/[\d]+}],
        ['/gdc/md/{id}/etl/task/{id}', %r{/gdc/md/[\w]+/etl/task/[\d]+}],
        ['/gdc/md/{id}/dataResult/{id}', %r{/gdc/md/[\w]+/dataResult/[\d]+}],
        ['/gdc/md/{id}', %r{/gdc/md/[\w]+}],
        ['/gdc/app/projects/{id}/execute', %r{/gdc/app/projects/[\w]+/execute}],
        ['/gdc/account/profile/{id}', %r{/gdc/account/profile/[\w]+}],
        ['/gdc/account/login/{id}', %r{/gdc/account/login/[\w]+}],
        ['/gdc/account/domains/{id}', %r{/gdc/account/domains/[\w\d-]+}]
      ]

      def update_stats(title, delta)
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
  end
end
