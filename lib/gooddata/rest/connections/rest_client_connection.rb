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
          server = options[:server] || Helpers::AuthHelper.read_server
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
        def get(uri, options = {})
          GoodData.logger.debug "GET: #{@server.url}#{uri}"
          profile "GET #{uri}" do
            b = proc { @server[uri].get cookies }
            process_response(options, &b)
          end
        end

        # HTTP PUT
        #
        # @param uri [String] Target URI
        def put(uri, data, options = {})
          payload = data.is_a?(Hash) ? data.to_json : data
          GoodData.logger.debug "PUT: #{@server.url}#{uri}, #{scrub_params(data, [:password, :login, :authorizationToken, :verifyPassword])}"
          profile "PUT #{uri}" do
            b = proc { @server[uri].put payload, cookies }
            process_response(options, &b)
          end
        end

        # HTTP POST
        #
        # @param uri [String] Target URI
        def post(uri, data, options = {})
          GoodData.logger.debug "POST: #{@server.url}#{uri}, #{scrub_params(data, [:password, :login, :authorizationToken, :verifyPassword])}"
          profile "POST #{uri}" do
            payload = data.is_a?(Hash) ? data.to_json : data
            b = proc { @server[uri].post payload, cookies }
            process_response(options, &b)
          end
        end

        # Uploads a file to GoodData server
        # /uploads/ resources are special in that they use a different
        # host and a basic authentication.
        def upload(file, options = {})
          dir = options[:directory] || ''
          staging_uri = options[:staging_url].to_s
          url = dir.empty? ? staging_uri : URI.join(staging_uri, "#{dir}/").to_s

          # Make a directory, if needed
          unless dir.empty?
            method = :get
            GoodData.logger.debug "#{method}: #{url}"
            begin
              # first check if it does exits
              raw = {
                :method => method,
                :url => url,
                # :timeout => @options[:timeout],
                :headers => @headers
              }.merge(cookies)
              RestClient::Request.execute(raw)
            rescue RestClient::Exception => e
              if e.http_code == 404
                method = :mkcol
                GoodData.logger.debug "#{method}: #{url}"
                raw = {
                  :method => method,
                  :url => url,
                  # :timeout => @options[:timeout],
                  :headers => @headers
                }.merge(cookies)
                RestClient::Request.execute(raw)
              end
            end
          end

          payload = options[:stream] ? 'file' : File.read(file)
          filename = options[:filename] || options[:stream] ? 'randome-filename.txt' : File.basename(file)

          # Upload the file
          # puts "uploading the file #{URI.join(url, filename).to_s}"
          raw = {
            :method => :put,
            :url => URI.join(url, filename).to_s,
            # :timeout => @options[:timeout],
            :headers => {
              :user_agent => GoodData.gem_version_string
            },
            :payload => payload,
            :raw_response => true,
            # :user => @username,
            # :password => @password
          }.merge(cookies)
          RestClient::Request.execute(raw)
          true
        end

        private

        def process_response(options = {}, &block)
          begin
            response = block.call
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
            GoodData.logger.debug "Response: #{result.inspect}"
          elsif ['text/plain;charset=UTF-8', 'text/plain; charset=UTF-8', 'text/plain'].include?(content_type)
            result = response
            GoodData.logger.debug "Response: plain text - #{result[0..99]}"
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
