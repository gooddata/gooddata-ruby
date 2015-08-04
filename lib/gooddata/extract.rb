# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'csv'

module GoodData
  module Extract
    class CsvFile
      def initialize(file)
        @file = file
      end

      def read(&block)
        CSV.open @file, 'r', &block
      end
    end
  end
end
