# encoding: UTF-8

require 'pathname'

module GoodData
  module Bricks
    class BaseDownloader
      def initialize(params)
        @params = params
        @logger = @params['GDC_LOGGER']
      end

      def pre_process(meta)
        meta
      end

      def download
        @logger.info 'would download data' if @logger
        []
      end

      def backup(meta)
        @logger.info 'would send a backup list of files to backup' if @logger
        files = meta.reduce([]) do |a, e|
          a << e[:filename]
        end

        bucket_name = @params['s3_backup_bucket_name']

        s3 = AWS::S3.new(
          :access_key_id => @params['aws_access_key_id'],
          :secret_access_key => @params['aws_secret_access_key']
        )

        bucket = s3.buckets[bucket_name]
        bucket = s3.buckets.create(bucket_name) unless bucket.exists?

        files.each do |file|
          obj = bucket.objects[file]
          obj.write(Pathname.new(file))
        end

        meta
      end

      def post_process(meta)
        @logger.info 'Maybe some postprocessing' if @logger
        meta
      end

      # Run downloader
      def run
        downloaded_data = download
        downloaded_data = pre_process(downloaded_data)
        backup(downloaded_data) unless @params['skip_backup']

        downloaded_data = post_process(downloaded_data)

        # save the state - whatever is in the return value of #download in the :persist key .. to project metadata
        if downloaded_data[:persist]
          accumulated_state = downloaded_data[:persist].reduce([]) do |memo, item|
            item.key?(:state) ? memo.concat(item[:state]) : memo
          end
          accumulated_state.each do |item|
            key = item[:key]
            val = item[:value]

            @logger.info "Saving metadata #{key} => #{val}" if @logger
            GoodData::ProjectMetadata[key] = val
          end
        end

        post_process(downloaded_data)
      end
    end
  end
end
