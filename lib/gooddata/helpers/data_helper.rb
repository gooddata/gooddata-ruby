# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'csv'
require 'digest'
require 'open-uri'

module GoodData
  module Helpers
    class DataSource
      attr_reader :realized

      class << self
        def interpolate_sql_params(query, params)
          keys = query.scan(/\$\{([^\{]+)\}/).flatten
          keys.reduce(query) do |a, e|
            key = e
            raise "Param #{key} is not present in schedule params yet it is expected to be interpolated in the query" unless params.key?(key)
            a.gsub("${#{key}}", params[key])
          end
        end
      end

      def initialize(opts = {})
        opts = opts.is_a?(String) ? { type: :staging, path: opts } : opts
        opts = GoodData::Helpers.symbolize_keys(opts)
        @source = opts[:type]
        @options = opts
        @realized = false
      end

      def realize(params = {})
        @realized = true
        source = @source && @source.to_s
        case source
        when 'ads'
          realize_query(params)
        when 'staging'
          realize_staging(params)
        when 'web'
          realize_link
        when 's3'
          realize_s3(params)
        else
          raise "DataSource does not support type \"#{source}\""
        end
      end

      def realized?
        @realized == true
      end

      private

      def realize_query(params)
        query = DataSource.interpolate_sql_params(@options[:query], params)
        dwh = params['ads_client'] || params[:ads_client] || raise("Data Source needs a client to ads to be able to query the storage but 'ads_client' is empty.")
        filename = Digest::SHA256.new.hexdigest(query)
        measure = Benchmark.measure do
          CSV.open(filename, 'w') do |csv|
            header_written = false
            header = nil
            dwh.execute_select(query) do |row|
              unless header_written
                header_written = true
                header = row.keys
                csv << header
              end
              csv << row.values_at(*header)
            end
          end
        end
        GoodData.logger.info "Realizing SQL query \"#{query}\" took #{measure.real}"
        filename
      end

      def realize_staging(params)
        path = @options[:path]
        url = URI.parse(path)
        filename = Digest::SHA256.new.hexdigest(path)
        if url.relative?
          params['gdc_project'].download_file(path, filename)
        else
          params['GDC_GD_CLIENT'].download_file(path, filename)
        end
        filename
      end

      def realize_link
        link = @options[:url]
        filename = Digest::SHA256.new.hexdigest(link)
        measure = Benchmark.measure do
          File.open(filename, 'w') do |f|
            open(link) { |rf| f.write(rf.read) }
          end
        end
        puts "Realizing web download from \"#{link}\" took #{measure.real}"
        filename
      end

      def realize_s3(params)
        params = GoodData::Helpers.stringify_keys(params)
        s3_client = params['aws_client'] && params['aws_client']['s3_client']
        raise 'AWS client not present. Perhaps S3Middleware is missing in the brick definition?' if !s3_client || !s3_client.respond_to?(:bucket)
        bucket_name = @options[:bucket]
        key = @options[:key]
        raise 'Key "bucket" is missing in S3 datasource' if bucket_name.blank?
        raise 'Key "key" is missing in S3 datasource' if key.blank?
        puts "Realizing download from S3. Bucket #{bucket_name}, object with key #{key}."
        filename = Digest::SHA256.new.hexdigest(@options.to_json)
        bucket = s3_client.bucket(bucket_name)
        obj = bucket.object(key)
        obj.get(response_target: filename, bucket: bucket_name, key: key)

        puts 'Done downloading file.'
        filename
      end
    end
  end
end
