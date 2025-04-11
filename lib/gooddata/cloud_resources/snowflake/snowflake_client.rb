# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2010-2019 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'securerandom'
require 'java'
require 'pathname'
require_relative '../cloud_resource_client'

base = Pathname(__FILE__).dirname.expand_path
Dir.glob(base + 'drivers/*.jar').each do |file|
  require file unless file.start_with?('lcm-snowflake-driver')
end

module GoodData
  module CloudResources
    class SnowflakeClient < CloudResourceClient
      SNOWFLAKE_GDC_APPLICATION_PARAMETER = 'application=gooddata_platform'
      SNOWFLAKE_SEPARATOR_PARAM = '?'

      class << self
        def accept?(type)
          type == 'snowflake'
        end
      end

      def initialize(options = {})
        raise("Data Source needs a client to Snowflake to be able to query the storage but 'snowflake_client' is empty.") unless options['snowflake_client']

        if options['snowflake_client']['connection'].is_a?(Hash)
          @database = options['snowflake_client']['connection']['database']
          @schema = options['snowflake_client']['connection']['schema'] || 'public'
          @warehouse = options['snowflake_client']['connection']['warehouse']
          @url = build_url(options['snowflake_client']['connection']['url'])
          @authentication = options['snowflake_client']['connection']['authentication']
        else
          raise('Missing connection info for Snowflake client')

        end

        # When update driver class then also updating driver class using in connection(..) method below
        Java.net.snowflake.client.jdbc.SnowflakeDriver
      end

      def realize_query(query, _params)
        GoodData.gd_logger.info("Realize SQL query: type=snowflake status=started")

        connect
        filename = "#{SecureRandom.urlsafe_base64(6)}_#{Time.now.to_i}.csv"
        measure = Benchmark.measure do
          statement = @connection.create_statement

          has_result = statement.execute(query)
          if has_result
            result = statement.get_result_set
            metadata = result.get_meta_data
            col_count = metadata.column_count
            CSV.open(filename, 'wb') do |csv|
              csv << Array(1..col_count).map { |i| metadata.get_column_name(i) } # build the header
              csv << Array(1..col_count).map { |i| result.get_string(i)&.to_s } while result.next
            end
          end
        end
        GoodData.gd_logger.info("Realize SQL query: type=snowflake status=finished duration=#{measure.real}")
        filename
      ensure
        @connection&.close
        @connection = nil
      end

      def connect
        GoodData.logger.info "Setting up connection to Snowflake #{@url}"

        prop = java.util.Properties.new
        prop.setProperty('user', @authentication['basic']['userName'])
        prop.setProperty('password', @authentication['basic']['password'])
        prop.setProperty('schema', @schema)
        prop.setProperty('warehouse', @warehouse)
        prop.setProperty('db', @database)
        # Add JDBC_QUERY_RESULT_FORMAT parameter to fix unsafe memory issue of Snowflake JDBC driver
        prop.setProperty('JDBC_QUERY_RESULT_FORMAT', 'JSON')

        @connection = com.snowflake.client.jdbc.SnowflakeDriver.new.connect(@url, prop)
      end

      def build_url(url)
        is_contain = url.include?(SNOWFLAKE_GDC_APPLICATION_PARAMETER)
        unless is_contain
          if url.include?(SNOWFLAKE_SEPARATOR_PARAM)
            url.concat("&")
          else
            url.concat(SNOWFLAKE_SEPARATOR_PARAM)
          end
          url.concat(SNOWFLAKE_GDC_APPLICATION_PARAMETER)
        end

        url
      end
    end
  end
end
