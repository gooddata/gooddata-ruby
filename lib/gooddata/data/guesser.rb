# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'date'

require_relative '../extract'
require_relative '../exceptions/command_failed'

module GoodData
  module Data
    ##
    # Utility class to guess data types of a data stream by looking at first couple of rows
    #
    class Guesser
      TYPES_PRIORITY = [:connection_point, :fact, :date, :attribute]
      attr_reader :headers

      class << self
        def sort_types(types)
          types.sort do |x, y|
            TYPES_PRIORITY.index(x) <=> TYPES_PRIORITY.index(y)
          end
        end
      end

      def initialize(reader)
        @reader = reader
        @headers = reader.shift.map!(&:to_s) || fail('Empty data set')
        @pros = {}
        @cons = {}
        @seen = {}

        @headers.map do |h|
          @cons[h.to_s] = {}
          @pros[h.to_s] = {}
          @seen[h.to_s] = {}
        end
      end

      def guess(limit)
        count = 0
        while (row = @reader.shift)
          break unless row && !row.empty? && count < limit
          fail '%i fields in row %i, %i expected' % [row.size, count + 1, @headers.size] if row.size != @headers.size
          row.each_with_index do |value, j|
            header = @headers[j]
            number = check_number(header, value)
            date = check_date(header, value)
            store_guess header, @pros => :attribute unless number || date
            hash_increment @seen[header], value
          end
          count += 1
        end
        # fields with unique values are connection point candidates
        @seen.each do |header, values|
          store_guess header, @pros => :connection_point if values.size == count
        end
        guess_result
      end

      private

      def guess_result
        result = {}
        @headers.each do |header|
          result[header] = Guesser.sort_types @pros[header].keys.select { |type| @cons[header][type].nil? }
        end
        result
      end

      def hash_increment(hash, key)
        if hash[key]
          hash[key] += 1
        else
          hash[key] = 1
        end
      end

      def check_number(header, value)
        if value.nil? || value =~ /^[\+-]?\d*(\.\d*)?$/
          return store_guess(header, @pros => [:fact, :attribute])
        end
        store_guess header, @cons => :fact
      end

      def check_date(header, value)
        return store_guess(header, @pros => [:date, :attribute, :fact]) if value.nil? || value == '0000-00-00'
        begin
          DateTime.parse value
          return store_guess(header, @pros => [:date, :attribute])
        rescue ArgumentError => e
          raise e
        end
        store_guess header, @cons => :date
      end

      ##
      # Stores a guess about given header.
      #
      # Returns true if the @pros key is present, false otherwise
      #
      # === Parameters
      #
      # * +header+ - A header name
      # * +guess+ - A hash with optional @pros and @cons keys
      #
      def store_guess(header, guess)
        result = guess[@pros]
        [@pros, @cons].each do |hash|
          if guess[hash]
            guess[hash] = [guess[hash]] unless guess[hash].is_a? Array
            guess[hash].each { |type| hash_increment hash[header], type }
          end
        end
        result
      end
    end
  end
end
