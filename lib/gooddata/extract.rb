require 'csv'

module Gooddata::Extract  
  class CsvFile
    def initialize(file)
      @file = file
    end
    
    def read(&block)
      CSV.open @file, 'r', &block
    end
  end
end
