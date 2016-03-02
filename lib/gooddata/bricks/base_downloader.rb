# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pathname'
require 'aws'

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

        files = meta['objects'].map { |_k, o| o }.reduce([]) do |a, e|
          a + e['filenames']
        end

        bucket_name = @params['s3_backup_bucket_name']

        s3 = AWS::S3.new(
          :access_key_id => @params['aws_access_key_id'],
          :secret_access_key => @params['aws_secret_access_key']
        )

        bucket = s3.buckets[bucket_name]
        bucket = s3.buckets.create(bucket_name) unless bucket.exists?

        files.each do |file|
          file_path = Pathname.new(file)
          target_path = Pathname.new(@params['s3_backup_path'] || '') + file_path.basename
          obj = bucket.objects[target_path]
          obj.write(file_path)
          @logger.info "Backed up file #{file_path} to s3 #{target_path}" if @logger
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
