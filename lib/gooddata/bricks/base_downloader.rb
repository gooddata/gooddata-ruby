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

      def post_process(meta)
        puts 'Maybe some postprocessing'
        meta
      end

      # Run downloader
      def run
        downloaded_data = download
        downloaded_data = pre_process(downloaded_data)
        downloaded_data = post_process(downloaded_data)
      end
    end
  end
end
