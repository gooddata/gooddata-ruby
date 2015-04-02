# encoding: UTF-8
require_relative 'base_middleware'

module GoodData
  module Bricks
    class FsProjectDownloadMiddleware < Bricks::Middleware
      def call(params)
        (params['gdc_files_to_download'] || []).each do |source|
          case source[:type].to_s
          when 'ads'
            CSV.open(source[:to], 'w') do |csv|
              header_written = false
              header = nil
              dwh = params['ads_client']
              dwh.execute_select(source[:query]) do |row|
                unless header_written
                  header_written = true
                  header = row.keys
                  csv << header
                end
                csv << row.values_at(*header)
              end
            end
          when 'staging'
            webdav_uri = GoodData.project_webdav_path
            dav = Net::DAV.new(webdav_uri, :curl => false)
            dav.verify_server = false
            dav.credentials(params['GDC_USERNAME'], params['GDC_PASSWORD'])
            dav.find(path, recursive: true, suppress_errors: true) do |item|
              puts 'Checking: ' + item.url.to_s
              name = (item.uri - webdav_uri).to_s
              File.open(name, 'w') do |f|
                f << item.content
              end
            end
          end
        end
        @app.call(params)
      end
    end
  end
end
