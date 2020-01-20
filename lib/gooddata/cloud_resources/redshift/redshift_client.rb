# encoding: UTF-8
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
        GoodData.logger.info "Setting up connection to Redshift #{options['redshift_client']['url']}"
        @url = options['redshift_client']['url'].chomp('/')
        @database = options['redshift_client']['database']
        @schema = options['redshift_client']['schema'] || 'public'
        @authentication = options['redshift_client']['authentication']
        @debug = options['debug'] == true || options['debug'] == 'true'

        Java.com.amazon.redshift.jdbc42.Driver
        base = Pathname(__FILE__).dirname
        org.apache.log4j.PropertyConfigurator.configure("#{base}/drivers/log4j.properties")
      end

      def realize_query(params)
        GoodData.gd_logger.info("Realize SQL query: type=redshift status=started")

        connect
        query = params['input_source']['query']
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
            File.open(filename, 'w') do |file|
              file.puts Array(1..col_count).map { |i| metadata.get_column_name(i) }.join(',') # build the header
              file.puts Array(1..col_count).map { |i| result.get_string(i) }.join(',') while result.next
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
        prop = java.util.Properties.new
        if @authentication['basic']
          prop.setProperty('UID', @authentication['basic']['userName'])
          prop.setProperty('PWD', @authentication['basic']['password'])
        else
          prop.setProperty('AccessKeyID', @authentication['iam']['accessKeyId'])
          prop.setProperty('SecretAccessKey', @authentication['iam']['secretAccessKey'])
          prop.setProperty('DbUser', @authentication['iam']['dbUser'])
        end
        @url += "/#{@database}" unless @url.ends_with?(@database)
        @connection = java.sql.DriverManager.getConnection(@url, prop)
      end
    end
  end
end
