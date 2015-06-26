# encoding: UTF-8
require_relative 'base_middleware'

module GoodData
  module Bricks
    class FsProjectUploadMiddleware < Bricks::Middleware
      def initialize(options = {})
        super
        @destination = options[:destination]
      end

      def call(params)
        returning(@app.call(params)) do |_|
          destination = @destination
          (params['gdc_files_to_upload'] || []).each do |f|
            path = f[:path]
            case destination.to_sym
            when :staging
              GoodData.client.get '/gdc/account/token', :dont_reauth => true
              url = GoodData.project_webdav_path
              GoodData.upload_to_project_webdav(path)
              puts "Uploaded local file \"#{path}\" to url \"#{url + path}\""
            end
          end
        end
      end
    end
    FsUploadMiddleware = FsProjectUploadMiddleware
  end
end
