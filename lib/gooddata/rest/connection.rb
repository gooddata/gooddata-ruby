# encoding: utf-8

require_relative '../exceptions/exceptions'

module GoodData
  module Rest
    # Wrapper of low-level HTTP/REST client/library
    class Connection
      attr_reader :user

      def initialize(opts)
        @user = nil
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
        fail NotImplementedError "DELETE #{uri}"
      end

      # HTTP GET
      #
      # @param uri [String] Target URI
      def get(uri, options = {})
        fail NotImplementedError "GET #{uri}"
      end

      # HTTP PUT
      #
      # @param uri [String] Target URI
      def put(uri, data, options = {})
        fail NotImplementedError "PUT #{uri}"
      end

      # HTTP POST
      #
      # @param uri [String] Target URI
      def post(uri, data, options = {})
        fail NotImplementedError "POST #{uri}"
      end
    end
  end
end
