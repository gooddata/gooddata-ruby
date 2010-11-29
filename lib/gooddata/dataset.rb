require 'csv'

module Gooddata::Dataset  
  class CsvReader
    def initialize(file)
      @file = file
    end
    
    def read(&block)
      CSV.open @file, 'r', &block
    end
  end
end
