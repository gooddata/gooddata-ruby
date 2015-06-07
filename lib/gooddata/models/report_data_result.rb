# encoding: UTF-8

require_relative 'data_result.rb'

module GoodData
  class ReportDataResult < DataResult
    # Row limit
    ROW_LIMIT = 10_000_000

    attr_reader :row_headers, :column_headers, :table, :headers_height, :headers_width

    def initialize(data)
      super
      @row_headers = []
      @column_headers = []
      @table = []

      @row_headers, @headers_width = tabularize_rows
      @column_headers, @headers_height = tabularize_columns

      assemble_table
    end

    def without_column_headers
      @table = table.transpose[headers_height, ROW_LIMIT].transpose
      self
    end

    def to_data_table
      table.transpose[headers_height, ROW_LIMIT].transpose[headers_width, ROW_LIMIT]
    end

    def each_line
      to_table.each { |line| yield line }
    end

    alias_method :each_row, :each_line

    def each_column
      table.each { |line| yield line }
    end

    def to_a
      table.to_a
    end

    def to_table
      table.transpose
    end

    def [](index, _options = {})
      to_table[index]
    end

    alias_method :row, :[]

    def column(index)
      table[index]
    end

    def include_row?(row)
      to_table.include?(row)
    end

    def include_column?(row)
      table.include?(row)
    end

    def ==(other)
      csv_table = to_table
      len = csv_table.length
      table = other.respond_to?(:to_table) ? other.to_table : other
      return false if len != table.length
      diff(other).empty? ? true : false
    end

    def diff(otherDataResult)
      csv_table = to_table
      other_table = otherDataResult.respond_to?(:to_table) ? otherDataResult.to_table : otherDataResult
      differences = []

      csv_table.each do |row|
        differences << row unless other_table.find { |r| r == row }
      end
      differences
    end

    def empty?
      false
    end

    private

    def each_level(table, level, children, lookup)
      max_level = level + 1
      children.each do |kid|
        first = kid['first']
        last = kid['last']
        repetition = last - first + 1
        repetition.times do |i|
          table[first + i] ||= []
          if kid['type'] == 'total'
            table[first + i][level] = kid['id']
          else
            table[first + i][level] = lookup[level][kid['id'].to_s]
          end
        end
        unless kid['children'].empty?
          new_level = each_level(table, level + 1, kid['children'], lookup)
          max_level = [max_level, new_level].max
        end
      end
      max_level
    end

    def tabularize_rows
      rows = data['xtab_data']['rows']
      kids = rows['tree']['children']

      if kids.empty? || (kids.size == 1 && kids.first['type'] == 'metric')
        headers = [[nil]]
        size = 0
      else
        headers = []
        size = each_level(headers, 0, rows['tree']['children'], rows['lookups'])
      end
      return headers, size # rubocop:disable RedundantReturn
    end

    def tabularize_columns
      columns = data['xtab_data']['columns']
      kids = columns['tree']['children']

      if kids.empty? || (kids.size == 1 && kids.first['type'] == 'metric')
        headers = [[nil]]
        size = 0
      else
        headers = []
        size = each_level(headers, 0, columns['tree']['children'], columns['lookups'])
      end

      return headers, size # rubocop:disable RedundantReturn
    end

    def assemble_table
      #    puts "=== COLUMNS === #{column_headers.size}x#{headers_height}"
      (column_headers.size).times do |i|
        (headers_height).times do |j|
          table[headers_width + i] ||= []
          #        puts "[#{headers_width + i}][#{j}] #{column_headers[i][j]}"
          table[headers_width + i][j] = column_headers[i][j]
        end
      end

      #    puts "=== ROWS ==="
      (row_headers.size).times do |i|
        (headers_width).times do |j|
          table[j] ||= []
          #        puts "[#{j}][#{headers_height + i}] #{row_headers[i][j]}"
          table[j][headers_height + i] = row_headers[i][j]
        end
      end

      xtab_data = data['xtab_data']['data']
      #    puts "=== DATA === #{column_headers.size}x#{row_headers.size}"
      (column_headers.size).times do |i|
        (row_headers.size).times do |j|
          table[headers_width + i] ||= []
          #        puts "[#{headers_width + i}, #{headers_height + j}] [#{i}][#{j}]=#{xtab_data[j][i]}"
          val = xtab_data[j][i]
          table[headers_width + i][headers_height + j] = val.nil? ? val : BigDecimal(val)
        end
      end
    end
  end
end
