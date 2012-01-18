require 'fastercsv'

module GoodData

  class Row < FasterCSV::Row
    def ==(other)
       len = length()
       return false if len != other.length
       result = true

       len.times do |i|
         result = false unless convert_field(field(i)) == convert_field(other.field(i))
       end
       result
    end

    private
    def convert_field(val)
      if val.is_a?(String) && val.match(/^[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?$/)
        val = val.scan(/[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?/).first
        val = val.include?('.') ? val.to_f.round : val.to_i
        return val
      elsif val.nil? || val == ' '
        return 'N/A'
      elsif val.respond_to? :round
        return val.round
      else
        return val
      end
    end
  end

  class DataResult

    attr_reader :data

    def initialize(data)
      @data = data
    end

    def print
      a = to_table.to_a
      a.transpose.unshift((1..a.length).to_a).each_with_index.map{|col, i|
        col.unshift(i.zero?? nil : i)   # inserts row labels #
        w = col.map{|cell| cell.to_s.length}.max   # w = "column width" #
        col.each_with_index.map{|cell, i|
          i.zero?? cell.to_s.center(w) : cell.to_s.ljust(w)}   # alligns the column #
      }.transpose.each{|row| puts "[#{row.join(' | ')}]"}
      nil
    end

    def to_table
      raise "Should be implemented in subclass"
    end

  end

  class EmptyResult < DataResult

    def initialize(data, options = {})
      super(data)
      @options = options
      assemble_table
    end

    def print
      puts "No Data"
    end

    def assemble_table
      @table = FasterCSV::Table.new([GoodData::Row.new([],[],false)])
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

  class SFDataResult < DataResult

    def initialize(data, options = {})
      super(data)
      @options = options
      assemble_table
    end

    def assemble_table
      sf_data = data[:queryResponse][:result][:records]
      sf_data = sf_data.is_a?(Hash) ? [sf_data] : sf_data
      if @options[:soql]
        # puts @options[:soql]
        fields = @options[:soql].strip.match(/SELECT (.*) FROM/)[1]
        @headers = fields.strip.split(",").map do |item|
          item.strip.split(/\s/)
        end.map do |item|
          item.last.to_sym
        end
        # pp @headers
      elsif @options[:headers]
        @headers = @options[:headers]
      else
        @headers = sf_data.first.keys - [:type, :Id]
      end
      @table = FasterCSV::Table.new(sf_data.collect do |line|
        GoodData::Row.new([], @headers.map {|h| line[h] || ' '}, false)
      end)
    rescue
      fail "Unable to assemble the table. Either the data provided are empty or the SOQL is malformed."
    end

    def to_table
      @table
    end

    def == (otherDataResult)
      result = true
      len =  @table.length
      other_table = otherDataResult.to_table
      if len != other_table.length
        # puts "TABLES ARE OF DIFFERENT SIZES"
        return false
      end

      diff(otherDataResult).empty?() ? true : false

    end

    def diff(otherDataResult)
      other_table = otherDataResult.to_table
      differences = []

      @table.each do |row|
        differences << row unless other_table.detect {|r| r == row}
      end
      differences
    end

  end

  class ReportDataResult < DataResult

    attr_reader :row_headers, :column_headers, :table, :headers_height, :headers_width

    def initialize(data)
      super
      @row_headers      = []
      @column_headers   = []
      @table            = []

      @row_headers, @headers_width = tabularize_rows
      @column_headers, @headers_height = tabularize_columns

      assemble_table
    end

    def without_column_headers
      @table = table.transpose[headers_height, 1000000].transpose
      self
    end

    def each_line
      table.transpose.each {|line| yield line}
    end

    def to_table
      FasterCSV::Table.new(table.transpose.map {|line| GoodData::Row.new([], line.map {|item| item || ' '}, false)})
    end

    def == (otherDataResult)
      result = true
      csv_table = to_table
      len =  csv_table.length
      return false if len != otherDataResult.to_table.length


      result
    end

    def diff(otherDataResult)
      csv_table = to_table
      other_table = otherDataResult.to_table
      differences = []

      csv_table.each do |row|
        differences << row unless other_table.detect {|r| r == row}
      end
      differences
    end

    private
    def each_level(table, level, children, lookup)
      max_level = level + 1
      children.each do |kid|
        first = kid["first"]
        last = kid["last"]
        repetition = last - first + 1
        repetition.times do |i|
          table[first + i] ||= []
          if kid["type"] == 'total'
            table[first + i][level] = kid["id"]
          else
            table[first + i][level] = lookup[level][kid["id"].to_s]
          end
        end
        if (!kid["children"].empty?)
          new_level = each_level(table, level+1, kid["children"], lookup)
          max_level = [max_level, new_level].max
        end
      end
      max_level
    end

    def tabularize_rows
      rows    = data["xtab_data"]["rows"]
      kids = rows["tree"]["children"]

      if kids.empty? || (kids.size == 1 && kids.first['type'] == 'metric')
        headers, size = [[nil]], 0
      else
        headers = []
        size = each_level(headers, 0, rows["tree"]["children"], rows["lookups"])
      end
      return headers, size
    end

    def tabularize_columns
      columns = data["xtab_data"]["columns"]
      kids = columns["tree"]["children"]

      if kids.empty? || (kids.size == 1 && kids.first['type'] == 'metric')
        headers, size = [[nil]], 0
      else
        headers = []
        size = each_level(headers, 0, columns["tree"]["children"], columns["lookups"])
      end
      return headers, size
    end

    def assemble_table()
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

      xtab_data = data["xtab_data"]["data"]
  #    puts "=== DATA === #{column_headers.size}x#{row_headers.size}"
      (column_headers.size).times do |i|
        (row_headers.size).times do |j|
          table[headers_width + i] ||= []
  #        puts "[#{headers_width + i}, #{headers_height + j}] [#{i}][#{j}]=#{xtab_data[j][i]}"
          table[headers_width + i][headers_height + j] = xtab_data[j][i]
        end
      end
    end
  end
end
