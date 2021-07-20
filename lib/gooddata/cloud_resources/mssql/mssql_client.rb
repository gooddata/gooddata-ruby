# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'securerandom'
require 'java'
require 'pathname'
require_relative '../cloud_resource_client'

base = Pathname(__FILE__).dirname.expand_path
Dir.glob(base + 'drivers/*.jar').each do |file|
  require file unless file.start_with?('lcm-mssql-driver')
end

module GoodData
  module CloudResources
    class MSSQLClient < CloudResourceClient
      MSSQL_SEPARATOR_PARAM = ";"
      MSSQL_URL_PATTERN = %r{jdbc:sqlserver://([^:]+)(:([0-9]+))?(/)?}
      MSSQL_DEFAULT_PORT = 1433
      LOGIN_TIME_OUT = 30
      MSSQL_FETCH_SIZE = 10_000
      VERIFY_FULL = 'verify-full'
      PREFER = 'prefer'
      REQUIRE = 'require'

      class << self
        def accept?(type)
          type == 'mssql'
        end
      end

      def initialize(options = {})
        raise("Data Source needs a client to MSSQL to be able to query the storage but 'mssql_client' is empty.") unless options['mssql_client']

        connection = options['mssql_client']['connection']
        if connection.is_a?(Hash)
          @database = connection['database']
          @schema = connection['schema']
          @authentication = connection['authentication']
          @ssl_mode = connection['sslMode']
          @url = connection['url']

          validate
        else
          raise('Missing connection info for MSSQL client')
        end

        Java.com.microsoft.sqlserver.jdbc.SQLServerDriver
      end

      def realize_query(query, _params)
        GoodData.gd_logger.info("Realize SQL query: type=mssql status=started")

        connect

        filename = "#{SecureRandom.urlsafe_base64(6)}_#{Time.now.to_i}.csv"
        measure = Benchmark.measure do
          statement = @connection.create_statement
          statement.set_fetch_size(MSSQL_FETCH_SIZE)
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

        GoodData.gd_logger.info("Realize SQL query: type=mssql status=finished duration=#{measure.real}")
        filename
      ensure
        @connection&.close
        @connection = nil
      end

      def connect
        connection_string = build_connection_string
        GoodData.logger.info "Setting up connection to MSSQL #{connection_string}"

        authentication = @authentication['basic'] || @authentication['activeDirectoryPassword']

        prop = java.util.Properties.new
        prop.setProperty('userName', authentication['userName'])
        prop.setProperty('password', authentication['password'])

        @connection = java.sql.DriverManager.getConnection(connection_string, prop)
      end

      def validate
        raise "SSL Mode should be prefer, require and verify-full" unless @ssl_mode == 'prefer' || @ssl_mode == 'require' || @ssl_mode == 'verify-full'

        raise "Instance name is not supported" if @url !~ /^[^\\]*$/

        raise "The connection url is invalid. Parameter is not supported." if @url.include? MSSQL_SEPARATOR_PARAM

        url_matches = @url.scan(MSSQL_URL_PATTERN)
        raise "Cannot reach the url" if url_matches.nil? || url_matches.length.zero?

        raise "The authentication method is not supported." unless @authentication['basic'] || @authentication['activeDirectoryPassword']
      end

      def build_connection_string
        encrypt = @ssl_mode != PREFER
        trust_server_certificate = @ssl_mode == REQUIRE

        "#{@url};" \
          "database=#{@database};" \
          "encrypt=#{encrypt};" \
          "trustServerCertificate=#{trust_server_certificate};" \
          "loginTimeout=#{LOGIN_TIME_OUT};" \
          "#{'authentication=ActiveDirectoryPassword;' if @authentication['activeDirectoryPassword']}"
      end
    end
  end
end
