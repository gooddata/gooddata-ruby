# TODO: Move to some shared helper
class BigDecimal; def pretty_print(p) p.text to_s; end; end

module GoodData
  
  class DataResult

    attr_reader :data

    def initialize(data)
      @data = data
    end

    def print
      puts to_s
    end

    def to_s(options={})
      with_indices = options[:index] || false
      a = to_table.to_a
      data = a.transpose
      data.unshift((1..a.length).to_a) if with_indices
      data.each_with_index.map{|col, i|
        col.unshift(i.zero? ? nil : i) if with_indices  # inserts row labels #
        w = col.map{|cell| cell.to_s.length}.max   # w = "column width" #
        col.each_with_index.map{|cell, i|
          i.zero? ? cell.to_s.center(w) : cell.to_s.ljust(w)} # alligns the column #
      }.transpose.map{|row| "[#{row.join(' | ')}]"}.unshift("").join("\n")
    end

    def to_table
      raise "Should be implemented in subclass"
    end

  end

end
