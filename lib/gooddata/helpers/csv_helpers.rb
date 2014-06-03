# encoding: UTF-8

require 'csv'

module GoodData
  module Helpers
    class << self
      def csv_read(opts)
        path = opts[:path]
        res = []

        line = 0

        CSV.foreach(path) do |row|
          line += 1
          next if opts[:header] && line == 1

          tmp_user = yield row
          res << tmp_user if tmp_user
        end

        res
      end

      def csv_write(opts, &block)
        path = opts[:path]
        header = opts[:header]
        data = opts[:data]

        CSV.open(path, 'w') do |csv|
          csv << header unless header.nil?
          data.each do |entry|
            res = yield entry
            csv << res if res
          end
        end
      end
    end
  end
end
