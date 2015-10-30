# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/connection'

require_relative '../environment/environment'

GoodData::Environment.load

module GoodData::Helpers
  module ConnectionHelper
    include GoodData::Environment::ConnectionHelper

    class << self
      # Creates connection using default credentials or supplied one
      #
      # @param [String] username Optional username
      # @param [String] password Optional password
      def create_default_connection(username = GoodData::Environment::ConnectionHelper::DEFAULT_USERNAME, password = GoodData::Environment::ConnectionHelper::DEFAULT_PASSWORD)
        GoodData::connect(username, password, :server => GoodData::Environment::ConnectionHelper::DEFAULT_SERVER, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
      end

      def disconnect
        conn = GoodData.connection.connection
        GoodData.disconnect
        puts conn.stats_table
      end

      # Creates connection using environment varibles GD_GEM_USER and GD_GEM_PASSWORD
      def create_private_connection
        username = ENV['GD_GEM_USER'] || DEFAULT_USERNAME
        password = ENV['GD_GEM_PASSWORD'] || DEFAULT_PASSWORD

        GoodData::connect(username, password)
      end
    end
  end
end
