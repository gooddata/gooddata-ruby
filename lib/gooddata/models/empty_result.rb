# encoding: UTF-8

require_relative 'data_result.rb'

module GoodData
  class EmptyResult < DataResult
    attr_reader :table

    def initialize(data, options = {})
      super(data)
      @options = options
      assemble_table
    end

    def to_s
      'No Data'
    end

    def assemble_table
      @table = [[]]
      # CSV::Table.new([GoodData::Row.new([],[],false)])
    end

    alias_method :to_table, :table
    alias_method :without_column_headers, :table

    def ==(_other)
      false
    end

    def diff(_otherDataResult)
      ['empty']
    end

    def [](index, _options = {})
      to_table[index]
    end

    alias_method :row, :[]

    def empty?
      true
    end

    def column(index)
      table[index]
    end

    def include_row?(_row = nil)
      false
    end

    def include_column?(_row = nil)
      false
    end
  end
end
