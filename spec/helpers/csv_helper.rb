# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

# Global requires
require 'multi_json'

# Local requires
require 'gooddata/models/models'

module GoodData::Helpers
  module CsvHelper
    CSV_PATH_EXPORT = 'out.txt'
    CSV_PATH_IMPORT = File.join(File.dirname(__FILE__), '..', 'data', 'users.csv')
  end
end
