# encoding: utf-8

require_relative '../connection'

require 'multi_json'
require 'rest-client'

module GoodData
  module Rest
    module Connections
      # Implementation of GoodData::Rest::Connection using https://rubygems.org/gems/rest-client
      class RestClientConnection < GoodData::Rest::Connection
        def initialize(opts = {})
          super

          @headers = DEFAULT_HEADERS.dup
          @user = nil
          @server = nil

          @opts = opts
          headers = opts[:headers] || {}
          @headers.merge! headers
        end

        # Connect using username and password
        def connect(username, password, options = {})
          server = options[:server] || DEFAULT_URL
          @server = RestClient::Resource.new server, DEFAULT_LOGIN_PAYLOAD

          super
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
          GoodData.logger.debug "PUT: #{@server.url}#{uri}, #{scrub_params(data, [:password, :login, :authorizationToken])}"
          profile "PUT #{uri}" do
            b = proc { @server[uri].put payload, cookies }
            process_response(options, &b)
          end
        end

        # HTTP POST
        #
        # @param uri [String] Target URI
        def post(uri, data, options = {})
          GoodData.logger.debug "POST: #{@server.url}#{uri}, #{scrub_params(data, [:password, :login, :authorizationToken])}"
          profile "POST #{uri}" do
            payload = data.is_a?(Hash) ? data.to_json : data
            b = proc { @server[uri].post payload, cookies }
            process_response(options, &b)
          end
        end

        # Uploads a file to GoodData server
        def upload(file, options = {})
          def do_stream_file(uri, filename, options = {})
            puts "uploading the file #{uri}"

            to_upload = File.new(filename)
            cookies_str = cookies[:cookies].map { |cookie| "#{cookie[0]}=#{cookie[1]}" }.join(';')
            req = Net::HTTP::Put.new(uri.path, 'User-Agent' => GoodData.gem_version_string, 'Cookie' => cookies_str)
            req.content_length = to_upload.size
            req.body_stream = to_upload
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            response = http.start { |client| client.request(req) }
            case response
            when Net::HTTPSuccess then
              true
            when Net::HTTPUnauthorized
              refresh_token
              do_stream_file uri, filename, options
            else
              fail "Can't upload file to webdav. Path: #{uri}, response code: #{response.code}, response body: #{response.body}"
            end
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
              rescue  RestClient::Exception => e
                false if e.http_code == 404
              end
            end

            process_with_tt_refresh(&b)
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

            process_with_tt_refresh(&b)
          end

          dir = options[:directory] || ''
          staging_uri = options[:staging_url].to_s
          url = dir.empty? ? staging_uri : URI.join(staging_uri, "#{dir}/").to_s

          # Make a directory, if needed
          create_webdav_dir_if_needed url unless dir.empty?

          webdav_filename = options[:filename] || File.basename(file)
          do_stream_file URI.join(url, CGI.escape(webdav_filename)), file
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

          process_with_tt_refresh(&b)
        end

        private

        def process_with_tt_refresh(&block)
          block.call
        rescue RestClient::Unauthorized
          refresh_token
          block.call
        end

        private

        def process_response(options = {}, &block)
          begin
            # Simply try again when ConnectionReset, ConnectionRefused etc.. (see e.g. MSF-7591)
            response = GoodData::Rest::Client.retryable(:tries => 2, :on => SystemCallError) do
              block.call
            end
          rescue RestClient::Unauthorized
            raise $ERROR_INFO if options[:dont_reauth]
            refresh_token
            response = block.call
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
      end
    end
  end
end
