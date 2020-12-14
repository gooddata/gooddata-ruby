# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2010-2020 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  class DataSource < Rest::Resource
    class << self
      # @param [Object] client The Rest Client object
      def get_gd_data_sources(client)
        uri = '/gdc/dataload/dataSources'
        data = client.get(uri)
        list_data_sources = data['dataSources']['items']
        list_data_sources.each_with_index { |element, index| list_data_sources[index] = element['dataSource'] }
        list_data_sources
      end

      # @param [String] data_source_id The data source ID
      # @param [Object] client The Rest Client object
      def look_up_data_source_alias_from_id(data_source_id, client)
        data_source_list = get_gd_data_sources(client)
        data_source_list.map do |data_source|
          return data_source['alias'] if data_source_id == data_source['id']
        end
      end

      # @param [String] data_source_alias The data source Alias
      # @param [Object] client The Rest Client object
      def look_up_data_source_id_from_alias(data_source_alias, client)
        data_source_list = get_gd_data_sources(client)
        data_source_list.map do |data_source|
          return data_source['id'] if data_source_alias == data_source['alias']
        end
      end

      # @param [Hash] data_source The data source json data
      # @param [Object] client The Rest Client object
      def deploy_data_source(data_source, client)
        uri = '/gdc/dataload/dataSources'
        request_value = {}
        request_value[:dataSource] = data_source
        client.post(uri, request_value)
      end

      # @param [Hash] data_source The data source json data
      # @param [Object] client The Rest Client object
      def redeploy_data_source(data_source, client)
        fail "The data source id is empty, check your data source configuration." unless data_source[:id]

        data_source_id = data_source[:id]
        uri = "gdc/dataload/dataSources/#{data_source_id}"
        data_source.delete(:id) if data_source.include?(:id)
        request_value = {}
        request_value[:dataSource] = data_source
        client.put(uri, request_value)
      end

      # @param [String] data_source_id The data source ID
      # @param [Object] client The Rest Client object
      def remove_data_source(data_source_id, client)
        uri = "/gdc/dataload/dataSources/#{data_source_id}"
        client.delete(uri)
      end

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
        fail "Unable to get information about the Data Source '#{ds_alias[:alias]}' in the domain '#{domain}'" unless res
        fail "Unable to find the #{ds_alias[:type]} Data Source '#{ds_alias[:alias]}' in the domain '#{domain}'" if res['availableAlias']['available']

        ds_type = res['availableAlias']['existingDataSource']['type']
        if ds_type && ds_type != ds_alias[:type]
          fail "Wrong Data Source type - the '#{ds_type}' type is expected but the Data Source '#{ds_alias[:alias]}' in the domain '#{domain}' has the '#{ds_alias[:type]}' type"
        else
          res['availableAlias']['existingDataSource']['id']
        end
      end
    end
  end
end
