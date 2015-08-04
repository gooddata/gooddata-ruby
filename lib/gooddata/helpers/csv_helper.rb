# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'csv'

module GoodData
  module Helpers
    class Csv
      class << self
        # Read data from CSV
        #
        # @param [Hash] opts
        # @option opts [String] :path File to read data from
        # @option opts [Boolean] :header File to read data from
        # @return Array of rows with loaded data
        def read(opts)
          path = opts[:path]
          res = []

          line = 0

          CSV.foreach(path) do |row|
            line += 1
            next if opts[:header] && line == 1

            if block_given?
              data = yield row
            else
              data = row
            end

            res << data if data
          end

          res
        end

        # Write data to CSV
        # @option opts [String] :path File to write data to
        # @option opts [Array] :data Mandatory array of data to write
        # @option opts [String] :header Optional Header row
        def write(opts, &_block)
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
end
