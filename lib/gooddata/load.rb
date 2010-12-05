require 'csv'

module Gooddata::Load  
  class CSV
    def initialize(file)
      @file = file
    end
    
    def read(&block)
      CSV.open @file, 'r', &block
    end
  end
end
