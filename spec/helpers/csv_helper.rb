# encoding: UTF-8

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
