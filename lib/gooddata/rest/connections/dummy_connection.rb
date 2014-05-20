# encoding: utf-8

require_relative '../connection'

module GoodData
  module Rest
    module Connections
      # Implementation of GoodData::Rest::Connection using https://rubygems.org/gems/rest-client
      class DummyConnection < GoodData::Rest::Connection
        # HTTP DELETE
        #
        # @param uri [String] Target URI
        def delete(uri)
          puts "DELETE #{uri}"
        end

        # HTTP GET
        #
        # @param uri [String] Target URI
        def get(uri)
          puts "GET #{uri}"
        end

        # HTTP PUT
        #
        # @param uri [String] Target URI
        def put(uri)
          puts "PUT #{uri}"
        end

        # HTTP POST
        #
        # @param uri [String] Target URI
        def post(uri)
          puts "POST #{uri}"
        end
      end
    end
  end
end
