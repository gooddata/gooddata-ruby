require 'csv'

module Gooddata::Load  
  class CsvFile
    def initialize(file)
      @file = file
    end
    
    def read(&block)
      CSV.open @file, 'r', &block
    end
  end
end
