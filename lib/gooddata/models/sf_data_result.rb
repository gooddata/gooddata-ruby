module GoodData
# class SFDataResult < DataResult
#
#     def initialize(data, options = {})
#       super(data)
#       @options = options
#       assemble_table
#     end
#
#     def assemble_table
#       sf_data = data[:queryResponse][:result][:records]
#       sf_data = sf_data.is_a?(Hash) ? [sf_data] : sf_data
#       if @options[:soql]
#         # puts @options[:soql]
#         fields = @options[:soql].strip.match(/SELECT (.*) FROM/i)[1]
#         @headers = fields.strip.split(",").map do |item|
#           item.strip.split(/\s/)
#         end.map do |item|
#           item.last.to_sym
#         end
#         # pp @headers
#       elsif @options[:headers]
#         @headers = @options[:headers]
#       else
#         @headers = sf_data.first.keys - [:type, :Id]
#       end
#       @table = CSV::Table.new(sf_data.collect do |line|
#         GoodData::Row.new([], @headers.map {|h| line[h] || ' '}, false)
#       end)
#     rescue
#       fail "Unable to assemble the table. Either the data provided are empty or the SOQL is malformed."
#     end
#
#     def to_table
#       @table
#     end
#
#     def == (otherDataResult)
#       result = true
#       len =  @table.length
#       other_table = otherDataResult.to_table
#       if len != other_table.length
#         # puts "TABLES ARE OF DIFFERENT SIZES"
#         return false
#       end
#
#       diff(otherDataResult).empty?() ? true : false
#
#     end
#
#     def diff(otherDataResult)
#       other_table = otherDataResult.to_table
#       differences = []
#
#       @table.each do |row|
#         differences << row unless other_table.detect {|r| r == row}
#       end
#       differences
#     end
#
#   end
end
