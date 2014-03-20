require 'uri'
require 'net/http'
require 'pathname'

require_relative 'base_middleware'

module GoodData::Bricks
  class FsUploadMiddleware < GoodData::Bricks::Middleware
    def initialize(options={})
      super
      @destination = options[:destination]
    end

    def call(params)
      returning(@app.call(params)) do |result|
        destination = @destination
        (params["gdc_files_to_upload"] || []).each do |f|
          path = f[:path]
          case destination.to_s
          when "staging"
            url = GoodData.get_user_webdav_path(path)
            GoodData.upload_to_user_webdav(path)
            puts "Uploaded local file \"#{path}\" to url \"#{url + path}\""
          end
        end
      end
    end
  end
end