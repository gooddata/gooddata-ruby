# encoding: utf-8

require 'multi_json'
require 'typhoeus'

require_relative '../connection'

module GoodData
  module Rest
    module Connections
      class CookieJar < Hash
        class << self
          def stringify(hash)
            hash.map { |key, value| "#{key}=#{value}" }.join('; ')
          end
        end

        def to_s
          CookieJar.stringify(self)
        end

        def parse(cookie_strings)
          # pp cookie_strings

          cookie_strings ||= []
          cookie_strings = [cookie_strings] if cookie_strings.kind_of? String
          cookie_strings.each do |s|
            key, value = s.split('; ').first.split('=', 2)
            self[key] = value
          end
          self
        end
      end

      # Implementation of GoodData::Rest::Connection using https://rubygems.org/gems/rest-client
      class TyphoeusConnection < GoodData::Rest::Connection
        def initialize(opts = {})
          super

          @headers = {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
            'User-Agent' => GoodData.gem_version_string
          }

          # @headers = DEFAULT_HEADERS.dup

          @user = nil
          @server = nil

          headers = opts[:headers] || {}
          @headers.merge! headers
        end

        # HTTP DELETE
        #
        # @param uri [String] Target URI
        def delete(uri, options = {})
          url = "#{DEFAULT_URL}#{uri}"
          b = proc do
            req = Typhoeus::Request.new(
              url,
              method: :delete,
              headers: @headers.merge('Cookie' => CookieJar.stringify(cookies[:cookies]))
            )
            req.run
          end
          process_response(options, &b)
        end

        # HTTP GET
        #
        # @param uri [String] Target URI
        def get(uri, options = {})
          url = "#{DEFAULT_URL}#{uri}"
          b = proc do
            req = Typhoeus::Request.new(
              url,
              method: :get,
              headers: @headers.merge('Cookie' => CookieJar.stringify(cookies[:cookies]))
            )
            req.run
          end
          process_response(options, &b)
        end

        # HTTP PUT
        #
        # @param uri [String] Target URI
        def put(uri, data, options = {})
          url = "#{DEFAULT_URL}#{uri}"
          payload = data.is_a?(Hash) ? data.to_json : data
          b = proc do
            req = Typhoeus::Request.new(
              url,
              method: :put,
              headers: @headers.merge(Cookie: CookieJar.stringify(cookies[:cookies])),
              body: payload
            )
            req.run
          end
          process_response(options, &b)
        end

        # HTTP POST
        #
        # @param uri [String] Target URI
        def post(uri, data, options = {})
          # puts "POSTING: #{uri}"

          url = "#{DEFAULT_URL}#{uri}"
          payload = data.is_a?(Hash) ? data.to_json : data
          b = proc do
            req = Typhoeus::Request.new(
              url,
              method: :post,
              headers: @headers.merge(Cookie: CookieJar.stringify(cookies[:cookies])),
              body: payload
            )
            req.run
          end
          process_response(options, &b)
        end

        private

        def process_response(options = {}, &block)
          response = nil
          begin
            response = block.call
          rescue RestClient::Unauthorized
            refresh_token
            response = block.call
          end

          set_cookie = response.headers['Set-Cookie']
          cookies = CookieJar.new.parse(set_cookie)
          merge_cookies! cookies

          # return response if options[:process] == false
          #
          # content_type = response.headers[:content_type]
          # if content_type == 'application/json' || content_type == 'application/json;charset=UTF-8'
          #   result = response.to_str == '""' ? {} : MultiJson.load(response.to_str)
          #   GoodData.logger.debug "Response: #{result.inspect}"
          # elsif content_type == 'application/zip'
          #   result = response
          #   GoodData.logger.debug 'Response: a zipped stream'
          # elsif response.headers[:content_length].to_s == '0'
          #   result = nil
          #   GoodData.logger.debug 'Response: Empty response possibly 204'
          # elsif response.code == 204
          #   result = nil
          #   GoodData.logger.debug 'Response: 204 no content'
          # else
          #   fail "Unsupported response content type '%s':\n%s" % [content_type, response.to_str[0..127]]
          # end
          # result

          res = response.body.to_s

          begin
            return MultiJson.load(res)
          rescue MultiJson::ParseError => e
            puts e.to_s # => "{invalid json}"
            puts e.cause # => JSON::ParserError: 795: unexpected token at '{invalid json}'
          end

          # pp res

          res
        rescue Exception => e # rubocop:disable RescueException
          GoodData.logger.debug "Response: #{e}"
          raise $ERROR_INFO
        end
      end
    end
  end
end
