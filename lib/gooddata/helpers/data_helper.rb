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
        opts = opts.symbolize_keys
        @source = opts[:type]
        @options = opts
        @realized = false
      end

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

      def realize(params = {})
        @realized = true
        case @source.to_s
        when 'ads'
          realize_query(params)
        when 'staging'
          realize_staging(params)
        when 'web'
          realize_link
        end
      end
    end
  end
end
