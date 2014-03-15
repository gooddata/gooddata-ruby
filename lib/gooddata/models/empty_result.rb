module GoodData
  class EmptyResult < DataResult

    def initialize(data, options = {})
      super(data)
      @options = options
      assemble_table
    end

    def to_s
      "No Data"
    end

    def assemble_table
      @table = [[]]
      # CSV::Table.new([GoodData::Row.new([],[],false)])
    end

    def to_table
      @table
    end

    def without_column_headers
      @table
    end

    def == (otherDataResult)
      false
    end

    def diff(otherDataResult)
      ['empty']
    end
  end
end
