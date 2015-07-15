# encoding: UTF-8

require 'csv'
require 'digest'
require 'open-uri'

module GoodData
  module Helpers
    class DataSource
      attr_reader :realized

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
          fail "DataSource does not support type \"#{source}\""
        end
      end

      def realized?
        @realized == true
      end

      private

      def realize_query(params)
        query = @options[:query]
        dwh = params['ads_client']
        fail "Data Source needs a client to ads to be able to query the storage but 'ads_client' is empty." unless dwh
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
        puts "Realizing SQL query \"#{query}\" took #{measure.real}"
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
        s3_client = params['aws_client'] && params['aws_client']['s3_client']
        fail 'AWS client not present. Perhaps S3Middleware is missing in the brick definition?' if !s3_client || !s3_client.respond_to?(:buckets)
        bucket_name = @options[:bucket]
        key = @options[:key]
        fail "Key \"bucket\" is missing in S3 datasource" if bucket_name.blank?
        fail "Key \"key\" is missing in S3 datasource" if key.blank?
        puts "Realizing download from S3. Bucket #{bucket_name}, object with key #{key}."
        filename = Digest::SHA256.new.hexdigest(@options.to_json)
        bucket = s3_client.buckets[bucket_name]
        obj = bucket.objects[key]
        File.open(filename, 'wb') do |file|
          obj.read do |chunk|
            file.write(chunk)
          end
        end
        puts 'Done downloading file.'
        filename
      end
    end
  end
end
