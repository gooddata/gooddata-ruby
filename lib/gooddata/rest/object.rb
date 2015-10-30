# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../mixins/data_property_reader'
require_relative '../mixins/data_property_writer'

require_relative '../mixins/content_getter'

require_relative '../mixins/meta_getter'

require_relative '../mixins/meta_property_reader'
require_relative '../mixins/meta_property_writer'

require_relative '../mixins/root_key_getter'

module GoodData
  module Rest
    # Base class dealing with REST endpoints
    #
    # MUST Be interface for objects dealing with REST endpoints
    # MUST provide way to work with remote REST-like API in unified manner.
    # MUST NOT create new connections.
    class Object
      extend Mixin::DataPropertyReader
      extend Mixin::DataPropertyWriter

      extend Mixin::MetaPropertyReader
      extend Mixin::MetaPropertyWriter

      include Mixin::ContentGetter
      include Mixin::RootKeyGetter
      include Mixin::DataGetter
      include Mixin::MetaGetter

      attr_accessor :json
      alias_method :raw_data, :json
      alias_method :to_hash, :json

      alias_method :to_json, :json

      attr_writer :client
      attr_accessor :project

      def initialize(_opts = {})
        @client = nil
      end

      def client(opts = {})
        @client || GoodData::Rest::Object.client(opts)
      end

      def saved?
        !uri.blank?
      end

      class << self
        def default_client
        end

        def client(opts = { :client => GoodData.connection })
          opts[:client] # || GoodData.client
        end
      end
    end
  end
end
