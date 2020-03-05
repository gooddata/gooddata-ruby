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
  require file unless file.start_with?('lcm-bigquery-driver')
end

java_import 'com.google.auth.oauth2.ServiceAccountCredentials'
java_import 'com.google.cloud.bigquery.BigQuery'
java_import 'com.google.cloud.bigquery.BigQueryOptions'
java_import 'com.google.cloud.bigquery.FieldList'
java_import 'com.google.cloud.bigquery.FieldValue'
java_import 'com.google.cloud.bigquery.FieldValueList'
java_import 'com.google.cloud.bigquery.QueryJobConfiguration'
java_import 'com.google.cloud.bigquery.TableResult'
java_import 'org.apache.commons.text.StringEscapeUtils'

module GoodData
  module CloudResources
    class BigQueryClient < CloudResourceClient
      class << self
        def accept?(type)
          type == 'bigquery'
        end
      end

      def initialize(options = {})
        raise("Data Source needs a client to BigQuery to be able to query the storage but 'bigquery_client' is empty.") unless options['bigquery_client']

        if options['bigquery_client']['connection'].is_a?(Hash)
          @project = options['bigquery_client']['connection']['project']
          @schema = options['bigquery_client']['connection']['schema'] || 'public'
          @authentication = options['bigquery_client']['connection']['authentication']
        else
          raise('Missing connection info for BigQuery client')

        end
      end

      def realize_query(query, _params)
        GoodData.gd_logger.info("Realize SQL query: type=bigquery status=started")

        client = create_client
        filename = "#{SecureRandom.urlsafe_base64(6)}_#{Time.now.to_i}.csv"
        measure = Benchmark.measure do
          query_config = QueryJobConfiguration.newBuilder(query).setDefaultDataset(@schema).build
          table_result = client.query(query_config)

          if table_result.getTotalRows.positive?
            result = table_result.iterateAll
            field_list = table_result.getSchema.getFields
            col_count = field_list.size
            CSV.open(filename, 'wb') do |csv|
              csv << Array(1..col_count).map { |i| field_list.get(i - 1).getName } # build the header
              result.each do |row|
                csv << Array(1..col_count).map { |i| row.get(i - 1).getValue&.to_s }
              end
            end
          end
        end
        GoodData.gd_logger.info("Realize SQL query: type=bigquery status=finished duration=#{measure.real}")
        filename
      end

      private

      def create_client
        GoodData.logger.info "Setting up connection to BigQuery"
        client_email = @authentication['serviceAccount']['clientEmail']
        private_key = @authentication['serviceAccount']['privateKey']
        credentials = ServiceAccountCredentials.fromPkcs8(nil, client_email, StringEscapeUtils.unescapeJson(private_key), nil, nil)
        BigQueryOptions.newBuilder.setProjectId(@project).setCredentials(credentials).build.getService
      end
    end
  end
end
