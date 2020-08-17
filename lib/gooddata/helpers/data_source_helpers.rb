# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2010-2020 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.
# frozen_string_literal: false

module GoodData
  module Helpers
    class << self
      # Get a data source information from server by id
      #
      # @param [String] data_source_id The data source ID
      # @param [Object] client The Rest Client object
      # @return [Hash] Returns Data source
      def get_data_source_by_id(data_source_id, client)
        unless data_source_id.blank?
          uri = "/gdc/dataload/dataSources/#{data_source_id}"
          client.get(uri)
        end
      end

      # Verify to see if the data source exists in the domain using its alias
      #
      # @param [String] ds_alias The data source's alias
      # @param [Object] client The Rest Client object
      # @return [String] Id of the data source or failed with the reason
      def verify_data_source_alias(ds_alias, client)
        domain = client.connection.server.url
        fail "The data source alias is empty, check your data source configuration." unless ds_alias

        uri = "/gdc/dataload/dataSources/internal/availableAlias?alias=#{ds_alias[:alias]}"
        res = client.get(uri)
        fail "Unable to get information of data source has alias #{ds_alias} in the domain '#{domain}'" unless res
        fail "Unable to find the #{ds_alias[:type]} data source with the alias: '#{ds_alias[:alias]}' in the domain '#{domain}'" if res['availableAlias']['available']

        ds_type = res['availableAlias']['existingDataSource']['type']
        if ds_type && ds_type != ds_alias[:type]
          fail "The data source in the domain '#{domain}' is not type compatible, required '#{ds_alias[:type]}' but got #{ds_type}"
        else
          res['availableAlias']['existingDataSource']['id']
        end
      end
    end
  end
end
