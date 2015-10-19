# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  class ReportDataResult < Rest::Object
    class << self
      # Does all the needed parsing on the apyload coming from the API and returns an instance of ReportDataResult
      #
      # @param [Hash] data Data coming from the API
      # @return [GoodData::ReportDataResult] Returns new report data result
      def from_xtab(data)
        top = top_headers(data)
        left = left_headers(data)
        jank = GoodData::Helpers.zeroes(rows(top), cols(left), nil)
        d = data(data)
        stuff = d.empty? ? GoodData::Helpers.zeroes(rows(left), cols(top), nil) : d

        a = jank.zip(top).map { |x, y| x + y }
        b = left.zip(stuff).map { |x, y| x + y }
        result = a + b
        ReportDataResult.new(data: result, top: rows(top), left: cols(left))
      end

      private

      def line(child)
        children = child['children'] || []
        return (child['first']..child['last']).to_a.map { [child['id']] } if children.empty?
        children.flat_map { |c| line(c) }.map do |x|
          child['id'].nil? ? x : [child['id']] + x
        end
      end

      def root_line(root)
        lookups = root['lookups']
        header = line(root['tree'])
        header.map { |l| l.each_with_index.map { |item, index| lookups[index][item] } }
      end

      def top_headers(data)
        root = data['xtab_data']['columns']
        root_line(root).transpose
      end

      def left_headers(data)
        root = data['xtab_data']['rows']
        root_line(root)
      end

      def cols(stuff)
        stuff.first.count
      end

      def rows(stuff)
        stuff.count
      end

      def data(data)
        data['xtab_data']['data'].map { |row| row.map { |i| i ? BigDecimal(i) : i } }
      end
    end

    # Returns
    #
    # @param [Hash] opts Data for the report
    # @option opts [Array<Array>] :data The data as a matrix. First rows then cols
    # @option opts [Number] :top Number of rows that are representing the top header
    # @option opts [Number] :left Number of cols that are representing the left header
    # @return [GoodData::ReportDataResult] Returns new report data result
    def initialize(opts)
      @data = opts[:data]
      @top_headers_rows_nums = opts[:top]
      @left_headers_cols_nums = opts[:left]
    end

    # Gives you new report result with top headers removed
    #
    # @return [GoodData::ReportDataResult] Returns new report data result
    def without_top_headers
      slice(@top_headers_rows_nums, 0)
    end

    # Gives you new report result with left headers removed
    #
    # @return [GoodData::ReportDataResult] Returns new report data result
    def without_left_headers
      slice(0, @left_headers_cols_nums)
    end

    # Gives you left headers as an Array
    #
    # @return [Array] Return left headers as Array of Arrays. The notation is of a matrix. First rows then cols.
    def left_headers
      return nil if @left_headers_cols_nums == 0
      top = @left_headers_cols_nums - 1
      without_top_headers.slice(0, [0, top]).to_a
    end

    # Gives you right headers as an Array
    #
    # @return [Array] Return top headers as Array of Arrays. The notation is of a matrix. First rows then cols.
    def top_headers
      return nil if @top_headers_rows_nums == 0
      top = @top_headers_rows_nums - 1
      without_left_headers.slice([0, top], 0).to_a
    end

    # Gives you data as a new ReportDataResult
    #
    # @return [Array] Return left headers as Array of Arrays. The notation is of a matrix. First rows then cols.
    def data
      slice(@top_headers_rows_nums, @left_headers_cols_nums)
    end

    def each
      to_a.each
    end
    alias_method :each_line, :each
    alias_method :each_row, :each

    def each_column
      size.last.times.map do |i|
        col = map { |row| row[i] }
        yield(col)
      end
    end

    # Gives you data as a new ReportDataResult
    #
    # @return [Array] Return left headers as Array of Arrays. The notation is of a matrix. First rows then cols.
    def to_a
      @data
    end
    alias_method :to_table, :to_a

    # Gives report as a table suitable for printing out
    #
    # @return [String]
    def to_s(options = {})
      with_indices = options[:index]

      a = to_table.to_a
      data = a.transpose
      data.unshift((1..a.length).to_a) if with_indices
      processed_data = data.each_with_index.map do |col, i|
        col.unshift(i.zero? ? nil : i) if with_indices # inserts row labels #
        w = col.map { |cell| cell.to_s.length }.max # w = "column width" #
        col.each_with_index.map do |cell, j|
          j.zero? ? cell.to_s.center(w) : cell.to_s.ljust(w)
        end # alligns the column #
      end
      processed_data.transpose.map { |row| "[#{row.join(' | ')}]" }.unshift('').join("\n")
    end

    # Allows to pick particular row inside the report result
    #
    # @return [Array] Returns a row of data
    def [](index)
      @data[index]
    end
    alias_method :row, :[]

    # Allows to pick particular column inside the report result
    #
    # @return [Array] Returns a column of data. The column is returned transposed
    def column(index)
      transpose[index]
    end

    # Is the report without any data? This can be caused by the fact that the filters are too restrictive or data are not loaded in
    #
    # @return [Array] Returns true if data result is empty
    def empty?
      row, cols = size
      row == 0 && cols == 0
    end

    # Allows you to test if a report contains a row.
    #
    # @param [Array<String | Number>] row Row that you want to test. It is looking for the whole row. If the headers are getting in the way use #without_left_headers or #without_top_headers
    # @return [Array] Returns true if data are inside a report
    def include_row?(row)
      @data.include?(row)
    end

    # Allows you to test if a report contains a column.
    #
    # @param [Array<String | Number>] row Row that you want to test. It is looking for the whole row. If the headers are getting in the way use #without_left_headers or #without_top_headers
    # @return [Array] Returns true if data are inside a report
    def include_column?(col)
      transpose.include_row?(col)
    end

    # Returns the size of the report
    #
    # @return [Array<Number>] The size of the report result as an array. First element is rows second is columns
    def size
      [@data.size, @data.empty? ? 0 : @data.first.size]
    end

    # Transposes data and returns as new data result
    #
    # @return [GoodData::ReportDataResult] Returns new report data result with flipped columns and rows
    def transpose
      ReportDataResult.new(data: to_a.transpose, top: @left_headers_cols_nums, left: @top_headers_rows_nums)
    end

    # Gives you report result with a subset of data starting at position rows, cols
    #
    # @param [Number] rows Position where you want to slice your row. Currently accepts only number
    # @param [Number] cols Position where you want to slice your row. Currently accepts only number
    # @return [GoodData::ReportDataResult] Returns new report data result sliced data
    def slice(rows, cols)
      rows = rows.is_a?(Enumerable) ? rows : [rows, size.first]
      cols = cols.is_a?(Enumerable) ? cols : [cols, size.last]
      new_data = @data[rows.first..rows.last].map { |col| col[cols.first..cols.last] }
      if client
        client.create(ReportDataResult, data: new_data, top: @top_headers_rows_nums - rows.first, left: @left_headers_cols_nums - cols.first, project: project)
      else
        ReportDataResult.new(data: new_data, top: @top_headers_rows_nums - rows.first, left: @left_headers_cols_nums - cols.first, project: project)
      end
    end

    # Returns the size of the the data portion of report
    #
    # @return [Array<Number>] The size of the report result as an array. First element is rows second is columns
    def data_size
      data.size
    end

    def ==(other)
      return false if size != other.size
      @data == other.to_a
    end

    def eq?(other)
      self == other
    end

    # Implements subtraction. Works only on reports that have same number of columns. Gives you columns that are not in other.
    #
    # @param [GoodData::ReportDataResult] other The other report result
    # @return [Array<Array>] Returns rows that are not contained in other
    def -(other)
      fail 'Seems you are not using a data result as a parameter' unless other.respond_to?(:size)
      message = 'Results do not have compatible sizes. Subtracting the dataresults works row wise so you have to have the same number of columns'
      fail message if size.last != other.size.last
      to_a - other.to_a
    end

    # Implements diff. Works only on reports that have same number of columns (because it uses #- behind the scene).
    #
    # @param [GoodData::ReportDataResult] other The other report result
    # @return [Hash] Returns a hash that gives you the differences in the report results
    def diff(other)
      {
        added: other - self,
        removed: self - other,
        same: @data & other.to_a
      }
    end
  end
end
