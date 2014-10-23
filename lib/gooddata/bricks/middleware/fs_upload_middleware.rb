# encoding: UTF-8

require 'uri'
require 'net/http'
require 'pathname'

require_relative 'base_middleware'

module GoodData
  module Bricks
    class FsProjectUploadMiddleware < Bricks::Middleware
      def initialize(options = {})
        super
        @destination = options[:destination]
      end

      def call(params)
        returning(@app.call(params)) do |result|
          destination = @destination
          (params['gdc_files_to_upload'] || []).each do |f|
            webdav_filename = File.basename(f[:path])
            case destination.to_s
            when 'staging'
              url = GoodData.get_project_webdav_path(webdav_filename)
              GoodData.upload_to_project_webdav(webdav_filename, file_path: f[:path], directory: f[:webdav_directory])
              puts "Uploaded local file \"#{f[:path]}\" to url \"#{url}\""
            end
          end
        end
      end
    end
  end
end
