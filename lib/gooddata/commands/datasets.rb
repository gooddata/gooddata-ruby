require 'date'
require 'gooddata/dataset'

module Gooddata::Command
  class Datasets < Base
    def index
      project_id = extract_option('--project')
      raise ArgumentError.new "Project not specified, use the --project switch" unless project_id
      gooddata
      response = Gooddata::Project.find(project_id).datasets
      response['dataSetsInfo']['sets'].each do |ds|
        puts "#{ds['meta']['uri']}\t#{ds['meta']['identifier']}\t#{ds['meta']['title']}"
      end
    end

    def describe
      puts "describe" # TODO remove me
      reader = create_dataset.read
      fields = Guesser.new(reader).guess 1000
    end
    
    private
    
    def create_dataset
      file = extract_option('--file-csv')
      return Gooddata::Dataset::CsvReader.new file if file
      raise "Unsupported dataset type (only CSV supported now)"
    end
  end
  
  class Guesser
    def initialize(reader)
      @reader = reader
      @headers = reader.shift.map! { |h| h.to_s } or raise "Empty data set"
      @pros = {}; @cons = {}; @seen = {}
      @headers.map do |h|
        @cons[h.to_s] = {}
        @pros[h.to_s] = {}
        @seen[h.to_s] = {}
      end
    end
    
    def guess(limit)
      count = 0
      while row = @reader.shift
        break unless row && count < limit
        raise "%i fields in row %i, %i expected" % [ row.size, count + 1, @headers.size ] if row.size != @headers.size
        row.each_with_index do |value, j|
          header = @headers[j]
          number = check_number(header, value)
          date   = check_date(header, value)
          store_guess header, { @pros => :attribute } unless number || date
          hash_increment @seen[header], value
        end
        count += 1
      end
      # fields with unique values are connection point candidates
      @seen.each do |header, values|
        store_guess header, { @pros => :connection_point } if values.size == count
      end
      guess_result
    end
    
    private
    
    def guess_result
      result = {}
      @headers.each do |header|
        result[header] = @pros[header].keys.select { |type| @cons[header][type].nil? }
      end
      result
    end
    
    def hash_increment(hash, key)
      if hash[key]
        hash[key] += 1
      else
        hash[key] = 1
      end
    end
    
    def check_number(header, value)
      if value.nil? || value =~ /^[\+-]?\d*(\.\d*)?$/
        return store_guess header, { @pros => [ :fact, :attribute ] }
      end
      store_guess header, { @cons => :fact }
    end

    def check_date(header, value)
      return store_guess header, { @pros => [ :date, :attribute, :fact ] } if value.nil? || value == '0000-00-00'
      begin
        DateTime.parse value
        return store_guess header, { @pros => [ :date, :attribute ] }
      rescue ArgumentError; end
      store_guess header, { @cons => :date }
    end

    ##
    # Stores a guess about given header.
    #
    # Returns true if the @pros key is present, false otherwise
    #
    # === Parameters
    #
    # * +header+ - A header name
    # * +guess+ - A hash with optional @pros and @cons keys
    #
    def store_guess(header, guess)
      result = !guess[@pros].nil?
      [@pros, @cons].each do |hash|
        if guess[hash] then
          guess[hash] = [ guess[hash] ] unless guess[hash].is_a? Array
          guess[hash].each { |type| hash_increment hash[header], type }
        end
      end
      result
    end
  end
end