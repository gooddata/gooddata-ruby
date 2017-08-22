# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'object'

module GoodData
  module Rest
    # Bridge between Rest::Object and Rest::Connection
    #
    # MUST be Responsible for creating new Rest::Object instances using proper Rest::Connection
    # SHOULD be used for throttling, statistics, custom 'allocation strategies' ...
    class ObjectFactory
      attr_accessor :client
      attr_accessor :connection
      attr_accessor :objects
      attr_accessor :resources

      # Initializes instance of factory
      #
      # @param connection [GoodData::Rest::Connection] Connection used by factory
      # @return [GoodData::Rest::ObjectFactory] Factory instance
      def initialize(client)
        fail ArgumentError 'Invalid connection passed' if client.nil?

        @client = client

        # Set connection used by factory
        @connection = @client.connection
      end

      def create(type, data = {}, opts = {})
        res = type.new(data)
        res.client = client

        opts.each do |key, value|
          method = "#{key}="
          res.send(method, value) if res.respond_to?(method)
        end

        res
      end

      def find(type, opts = {})
        type.send('find', opts, @client)
      end
    end
  end
end
