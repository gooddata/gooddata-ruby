# encoding: utf-8

require_relative '../connection'

module GoodData
  module Rest
    module Connections
      # Implementation of GoodData::Rest::Connection using https://rubygems.org/gems/rest-client
      class DummyConnection < GoodData::Rest::Connection
        def initialize(opts = {})
          super
        end

        # Connect using username and password
        def connect(username, password)
        end

        # Disconnect
        def disconnect
        end

        # HTTP DELETE
        #
        # @param uri [String] Target URI
        def delete(uri, options = {})
          puts "DELETE #{uri}"
        end

        # HTTP GET
        #
        # @param uri [String] Target URI
        def get(uri, options = {})
          puts "GET #{uri}"
        end

        # HTTP PUT
        #
        # @param uri [String] Target URI
        def put(uri, data, options = {})
          puts "PUT #{uri}"
        end

        # HTTP POST
        #
        # @param uri [String] Target URI
        def post(uri, data, options = {})
          puts "POST #{uri}"
        end
      end
    end
  end
end
