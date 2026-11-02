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
  require file unless file.start_with?('lcm-redshift-driver')
end

module GoodData
  module CloudResources
    class RedshiftClient < CloudResourceClient
      class << self
        def accept?(type)
          type == 'redshift'
        end
      end

      def initialize(options = {})
        raise("Data Source needs a client to Redshift to be able to query the storage but 'redshift_client' is empty.") unless options['redshift_client']

        if options['redshift_client']['connection'].is_a?(Hash)
          @database = options['redshift_client']['connection']['database']
          @schema = options['redshift_client']['connection']['schema'] || 'public'
          @url = options['redshift_client']['connection']['url']
          @authentication = options['redshift_client']['connection']['authentication']
        else
          raise('Missing connection info for Redshift client')

        end
        @debug = options['debug'] == true || options['debug'] == 'true'

        # When update driver class then also updating driver class using in connection(..) method below
        Java.com.amazon.redshift.jdbc42.Driver
      end

      def realize_query(query, _params)
        GoodData.gd_logger.info("Realize SQL query: type=redshift status=started")

        connect
        filename = "#{SecureRandom.urlsafe_base64(6)}_#{Time.now.to_i}.csv"
        measure = Benchmark.measure do
          statement = @connection.create_statement
          schema_sql = "set search_path to #{@schema}"
          statement.execute(schema_sql)

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
        GoodData.gd_logger.info("Realize SQL query: type=redshift status=finished duration=#{measure.real}")
        filename
      ensure
        @connection.close unless @connection.nil?
        @connection = nil
      end

      def connect
        full_url = build_url(@url, @database)
        GoodData.logger.info "Setting up connection to Redshift #{full_url}"

        # The driver defaults 'user' to the JVM's user.name and reads it before UID,
        # so 'user' must be set explicitly or UID is ignored.
        prop = java.util.Properties.new
        if @authentication['basic']
          user = @authentication['basic']['userName']
          password = @authentication['basic']['password']
          prop.setProperty('user', user)
          prop.setProperty('UID', user)
          prop.setProperty('password', password)
          prop.setProperty('PWD', password)
        else
          db_user = @authentication['iam']['dbUser']
          prop.setProperty('AccessKeyID', @authentication['iam']['accessKeyId'])
          prop.setProperty('SecretAccessKey', @authentication['iam']['secretAccessKey'])
          prop.setProperty('DbUser', db_user)
          prop.setProperty('user', db_user)
          prop.setProperty('UID', db_user)
        end

        @connection = com.amazon.redshift.jdbc42.Driver.new.connect(full_url, prop)
      end

      private

      def build_url(url, database)
        url_parts = url.split('?')
        url_path = url_parts[0].chomp('/')
        url_path += "/#{database}" if database && !url_path.end_with?("/#{database}")
        url_parts.length > 1 ? url_path + '?' + url_parts[1] : url_path
      end
    end
  end
end
