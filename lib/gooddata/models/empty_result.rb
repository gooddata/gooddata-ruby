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

    def ==(other)
      false
    end

    def diff(otherDataResult)
      ['empty']
    end
  end
end
