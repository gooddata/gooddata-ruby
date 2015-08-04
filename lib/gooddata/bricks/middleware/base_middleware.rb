# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'hashie'

module GoodData
  module Bricks
    class Middleware
      attr_accessor :app

      include Bricks::Utils

      # Loads defaults to params from a json file in @config.
      #
      # The idea is to have a set of parameter defaults
      # for a middleware. The defaults are loaded from a json file.
      # If a brick user wants to override a default, they can
      # do that in runtime params which come to the method in 'params'.
      #
      # A deep merge is done on the params. Arrays and other
      # non-hash types are overwritten (params win).
      #
      # ### Examples
      #
      # A brick developer develops a SalesforceDownloaderMiddleware
      # with default preset 'gse' having a configuration preset
      # {"entities": ["Acount", "Event", "OpportunityLineItem", "Opportunity", "User"]}
      #
      # The brick user only wants to use Opportunity, so he passes
      # runtime parameter {"entities": ["Opportunity"]} which overrides
      # the default.
      # See spec/bricks/bricks_spec.rb for usage.
      def load_defaults(params)
        # if default params given, fill what's not given in runtime params
        if @config
          # load it from file and merge it
          defaults = { 'config' => MultiJson.load(File.read(@config)) }
          default_params = GoodData::Helpers::DeepMergeableHash[defaults]
          params = default_params.deep_merge(params)
        end
        params
      end

      def call(params)
        load_defaults(params)
      end

      def initialize(options = {})
        @app = options[:app]
      end
    end
  end
end
