# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../extensions/big_decimal'
require_relative '../rest/object'

module GoodData
  class DataResult < Rest::Object
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def print
      puts to_s
    end

    def to_s(options = {})
      with_indices = options[:index]

      a = to_table.to_a
      data = a.transpose
      data.unshift((1..a.length).to_a) if with_indices
      processed_data = data.each_with_index.map do |col, i|
        col.unshift(i.zero? ? nil : i) if with_indices # inserts row labels #
        w = col.map { |cell| cell.to_s.length }.max # w = "column width" #
        col.each_with_index.map do |cell, j|
          j.zero? ? cell.to_s.center(w) : cell.to_s.ljust(w)
        end # alligns the column #
      end
      processed_data.transpose.map { |row| "[#{row.join(' | ')}]" }.unshift('').join("\n")
    end

    def to_table
      fail 'Should be implemented in subclass'
    end
  end
end
