# encoding: UTF-8

require 'pathname'

module GoodData
  module Bricks
    class BaseDownloader
      def initialize(params)
        @params = params
      end

      def pre_process(meta)
        meta
      end

      def download
        puts 'would download data'
        []
      end

      def backup(meta)
        puts 'would send a backup list of files to backup'
        files = meta.reduce([]) do |a, e|
          a << e[:filename]
        end

        bucket_name = @params[:s3_backup_bucket_name]

        s3 = AWS::S3.new(
          :access_key_id => @params[:aws_access_key_id],
          :secret_access_key => @params[:aws_secret_access_key])

        bucket = s3.buckets[bucket_name]
        bucket = s3.buckets.create(bucket_name) unless bucket.exists?

        files.each do |file|
          obj = bucket.objects[file]
          obj.write(Pathname.new(file))
        end
        meta
      end

      def post_process(meta)
        puts 'Maybe some postprocessing'
        meta
      end

      # Run downloader
      def run
        downloaded_data = download
        downloaded_data = pre_process(downloaded_data)
        backup(downloaded_data)
        downloaded_data = post_process(downloaded_data)

        accumulated_state = downloaded_data.reduce([]) do |memo, item|
          item.key?(:state) ? memo.concat(item[:state]) : memo
        end
        accumulated_state.each do |item|
          key = item[:key]
          val = item[:value]

          puts "Saving metadata #{key} => #{val}"
          GoodData::ProjectMetadata[key] = val
        end
      end
    end
  end
end
