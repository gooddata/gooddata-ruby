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
        returning(@app.call(params)) do |_result|
          destination = @destination
          (params['gdc_files_to_upload'] || []).each do |f|
            case destination.to_s
            when 'staging'
              GoodData.upload_to_project_webdav(f[:path], directory: f[:webdav_directory])
              puts "Uploaded local file \"#{f[:path]}\" to webdav."
            end
          end
        end
      end
    end

    # Alias to make it backwards compatible
    FsUploadMiddleware = FsProjectUploadMiddleware
  end
end
