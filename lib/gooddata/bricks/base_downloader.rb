# encoding: UTF-8

require 'pathname'

module GoodData::Bricks
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

      downloaded_data.reduce([]) do |memo, item|
        item.has_key?(:state) ? memo.concat(item[:state]) : memo
      end.each do |item|
        key = item[:key]
        val = item[:value]

        puts "Saving metadata #{key} => #{val}"
        GoodData::ProjectMetadata[key] = val
      end
    end
  end
end