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

          headers = opts[:headers] || {}
          @headers.merge! headers
        end

        # Connect using username and password
        def connect(username, password, options = {})
          credentials = {
            'postUserLogin' => {
              'login' => username,
              'password' => password,
              'remember' => 1
            }
          }

          data = {
            :timeout => options[:timeout],
            :headers => {
              :content_type => :json,
              :accept => [:json, :zip],
              :user_agent => GoodData.gem_version_string
            }
          }

          @server = RestClient::Resource.new DEFAULT_URL, data

          res = post(LOGIN_PATH, credentials, :dont_reauth => true)['userLogin']

          @user = get(res['profile'])

          refresh_token :dont_reauth => true
        end

        def cookies
          @cookies ||= {:cookies => {}}
        end

        # Disconnect
        def disconnect
        end

        def refresh_token(options = {})
          begin
            get TOKEN_PATH, :dont_reauth => true # avoid infinite loop GET fails with 401
          rescue Exception => e
            puts e.message
          end
        end

        # HTTP DELETE
        #
        # @param uri [String] Target URI
        def delete(uri, options = {})
          b = proc { @server[path].delete cookies }
          process_response(options, &b)
        end

        # HTTP GET
        #
        # @param uri [String] Target URI
        def get(uri, options = {})
          b = proc { @server[uri].get cookies }
          process_response(options, &b)
        end

        # HTTP PUT
        #
        # @param uri [String] Target URI
        def put(uri, data, options = {})
          payload = data.is_a?(Hash) ? data.to_json : data
          b = proc { @server[path].put payload, cookies }
          process_response(options, &b)
        end

        # HTTP POST
        #
        # @param uri [String] Target URI
        def post(uri, data, options = {})
          payload = data.is_a?(Hash) ? data.to_json : data
          b = proc { @server[uri].post payload, cookies }
          process_response(options, &b)
        end

        private

        def merge_cookies!(cookies)
          @cookies[:cookies].merge! cookies
        end

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
