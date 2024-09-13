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
  require file unless file.start_with?('lcm-mysql-driver')
end

module GoodData
  module CloudResources
    class MysqlClient < CloudResourceClient
      JDBC_MYSQL_PATTERN = %r{jdbc:mysql:\/\/([^:^\/]+)(:([0-9]+))?(\/)?}
      MYSQL_DEFAULT_PORT = 3306
      JDBC_MYSQL_PROTOCOL = 'jdbc:mysql://'
      VERIFY_FULL = '&useSSL=true&verifyServerCertificate=true'
      PREFER = '&useSSL=true&requireSSL=false&verifyServerCertificate=false'
      REQUIRE = '&useSSL=true&requireSSL=true&verifyServerCertificate=false'
      MYSQL_FETCH_SIZE = 1000
      MONGO_BI_FETCH_SIZE = 1
      MONGO_BI_TYPE = 'MongoDBConnector'

      class << self
        def accept?(type)
          type == 'mysql'
        end
      end

      def initialize(options = {})
        raise("Data Source needs a client to Mysql to be able to query the storage but 'mysql_client' is empty.") unless options['mysql_client']

        if options['mysql_client']['connection'].is_a?(Hash)
          @database = options['mysql_client']['connection']['database']
          @authentication = options['mysql_client']['connection']['authentication']
          @ssl_mode = options['mysql_client']['connection']['sslMode']
          @database_type = options['mysql_client']['connection']['databaseType']
          raise "SSL Mode should be prefer, require and verify-full" unless @ssl_mode == 'prefer' || @ssl_mode == 'require' || @ssl_mode == 'verify-full'

          @url = build_url(options['mysql_client']['connection']['url'])
        else
          raise('Missing connection info for Mysql client')
        end

        # When update driver class then also updating driver class using in connection(..) method below
        Java.com.mysql.jdbc.Driver
      end

      def realize_query(query, _params)
        GoodData.gd_logger.info("Realize SQL query: type=mysql status=started")

        connect
        filename = "#{SecureRandom.urlsafe_base64(6)}_#{Time.now.to_i}.csv"
        measure = Benchmark.measure do
          statement = @connection.create_statement
          statement.set_fetch_size(fetch_size)
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
        GoodData.gd_logger.info("Realize SQL query: type=mysql status=finished duration=#{measure.real}")
        filename
      ensure
        @connection&.close
        @connection = nil
      end

      def connect
        GoodData.logger.info "Setting up connection to Mysql #{@database_type} #{@url} "

        prop = java.util.Properties.new
        prop.setProperty('user', @authentication['basic']['userName'])
        prop.setProperty('password', @authentication['basic']['password'])
        @connection = com.mysql.jdbc.Driver.new.connect(@url, prop)
        @connection.set_auto_commit(false)
      end

      def build_url(url)
        matches = url.scan(JDBC_MYSQL_PATTERN)
        raise 'Cannot reach the url' unless matches

        host = matches[0][0]
        port = matches[0][2]&.to_i || MYSQL_DEFAULT_PORT

        "#{JDBC_MYSQL_PROTOCOL}#{host}:#{port}/#{@database}?#{get_ssl_mode(@ssl_mode)}#{add_extended}&useCursorFetch=true&enabledTLSProtocols=TLSv1.2"
      end

      def fetch_size
        @database_type == MONGO_BI_TYPE ? MONGO_BI_FETCH_SIZE : MYSQL_FETCH_SIZE
      end

      def get_ssl_mode(ssl_mode)
        mode = PREFER
        if ssl_mode == 'verify-full'
          mode =  VERIFY_FULL
        elsif ssl_mode == 'require'
          mode =  REQUIRE
        end

        mode
      end

      def add_extended
        @database_type == MONGO_BI_TYPE ? '&authenticationPlugins=org.mongodb.mongosql.auth.plugin.MongoSqlAuthenticationPlugin&useLocalTransactionState=true' : ''
      end
    end
  end
end
