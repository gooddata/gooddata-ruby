# encoding: utf-8

require_relative '../exceptions/exceptions'

module GoodData
  module Rest
    # Wrapper of low-level HTTP/REST client/library
    class Connection
      def initialize(opts)
      end

      # HTTP DELETE
      #
      # @param uri [String] Target URI
      def delete(uri)
        raise NotImplementedError "DELETE #{uri}"
      end

      # HTTP GET
      #
      # @param uri [String] Target URI
      def get(uri)
        raise NotImplementedError "GET #{uri}"
      end

      # HTTP PUT
      #
      # @param uri [String] Target URI
      def put(uri)
        raise NotImplementedError "PUT #{uri}"
      end

      # HTTP POST
      #
      # @param uri [String] Target URI
      def post(uri)
        raise NotImplementedError "POST #{uri}"
      end
    end
  end
end
