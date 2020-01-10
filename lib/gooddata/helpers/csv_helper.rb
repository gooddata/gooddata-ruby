# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'csv'
require 'fileutils'

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

        # Read data from csv as an array of hashes with symbol keys and parsed integers
        # @option filename String
        def read_as_hash(filename)
          res = []
          return res unless File.exist? filename

          CSV.parse(File.read(filename), headers: true, header_converters: :symbol, converters: :integer).map do |row|
            res << row.to_hash
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

        # Ammend a hash to CSV in a smart manner
        # @option filename String
        # @option data Hash
        def ammend_line(filename, data)
          GoodData.logger.info "Writing data to file #{filename}"

          current_data = read_as_hash(filename)
          data_to_write = (current_data << data).map(&:sort).map { |r| Hash[r] }
          FileUtils.mkpath(filename.split('/')[0...-1].join('/'))
          CSV.open(filename, 'w', write_headers: true, headers: data_to_write.first.keys) do |csv|
            data_to_write.each do |d|
              csv << d.values
            end
          end
        end
      end
    end
  end
end
