# encoding: UTF-8

require 'csv'

module GoodData::Extract
  class CsvFile
    def initialize(file)
      @file = file
    end

    def read(&block)
      CSV.open @file, 'r', &block
    end
  end
end