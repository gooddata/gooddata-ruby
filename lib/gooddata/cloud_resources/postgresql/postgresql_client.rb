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
  require file unless file.start_with?('lcm-postgresql-driver')
end

module GoodData
  module CloudResources
    class PostgresClient < CloudResourceClient
      JDBC_POSTGRES_PATTERN = %r{jdbc:postgresql:\/\/([^:^\/]+)(:([0-9]+))?(\/)?}
      POSTGRES_DEFAULT_PORT = 5432
      JDBC_POSTGRES_PROTOCOL = 'jdbc:postgresql://'
      SSL_JAVA_FACTORY = '&sslfactory=org.postgresql.ssl.DefaultJavaSSLFactory'
      VERIFY_FULL = 'verify-full'
      PREFER = 'prefer'
      REQUIRE = 'require'
      POSTGRES_SET_SCHEMA_COMMAND = "set search_path to"
      POSTGRES_FETCH_SIZE = 1000

      class << self
        def accept?(type)
          type == 'postgresql'
        end
      end

      def initialize(options = {})
        raise("Data Source needs a client to Postgres to be able to query the storage but 'postgresql_client' is empty.") unless options['postgresql_client']

        if options['postgresql_client']['connection'].is_a?(Hash)
          @database = options['postgresql_client']['connection']['database']
          @schema = options['postgresql_client']['connection']['schema'] || 'public'
          @authentication = options['postgresql_client']['connection']['authentication']
          @ssl_mode = options['postgresql_client']['connection']['sslMode']
          raise "SSL Mode should be prefer, require and verify-full" unless @ssl_mode == 'prefer' || @ssl_mode == 'require' || @ssl_mode == 'verify-full'

          @url = build_url(options['postgresql_client']['connection']['url'])
        else
          raise('Missing connection info for Postgres client')
        end

        # When update driver class then also updating driver class using in connection(..) method below
        Java.org.postgresql.Driver
      end

      def realize_query(query, _params)
        GoodData.gd_logger.info("Realize SQL query: type=postgresql status=started")

        connect
        filename = "#{SecureRandom.urlsafe_base64(6)}_#{Time.now.to_i}.csv"
        measure = Benchmark.measure do
          statement = @connection.create_statement
          statement.set_fetch_size(POSTGRES_FETCH_SIZE)
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
        GoodData.gd_logger.info("Realize SQL query: type=postgresql status=finished duration=#{measure.real}")
        filename
      ensure
        @connection&.close
        @connection = nil
      end

      def connect
        GoodData.logger.info "Setting up connection to Postgresql #{@url}"

        prop = java.util.Properties.new
        prop.setProperty('user', @authentication['basic']['userName'])
        prop.setProperty('password', @authentication['basic']['password'])
        prop.setProperty('schema', @schema)

        @connection = org.postgresql.Driver.new.connect(@url, prop)
        statement = @connection.create_statement
        statement.execute("#{POSTGRES_SET_SCHEMA_COMMAND} #{@schema}")
        @connection.set_auto_commit(false)
      end

      def build_url(url)
        matches = url.scan(JDBC_POSTGRES_PATTERN)
        raise 'Cannot reach the url' unless matches

        host = matches[0][0]
        port = matches[0][2]&.to_i || POSTGRES_DEFAULT_PORT

        "#{JDBC_POSTGRES_PROTOCOL}#{host}:#{port}/#{@database}?sslmode=#{@ssl_mode}#{VERIFY_FULL == @ssl_mode ? SSL_JAVA_FACTORY : ''}"
      end
    end
  end
end
