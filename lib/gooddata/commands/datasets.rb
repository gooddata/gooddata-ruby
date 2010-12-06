require 'date'
require 'gooddata/load'
require 'gooddata/dataset'

module Gooddata::Command
  class Datasets < Base
    def index
      with_project do |project_id|
        response = Gooddata::Project.find(project_id).datasets
        response['dataSetsInfo']['sets'].each do |ds|
          puts "#{ds['meta']['uri']}\t#{ds['meta']['identifier']}\t#{ds['meta']['title']}"
        end
      end
    end

    def describe
      columns  = ask_for_fields
      name   = extract_option('--name') || ask("Enter the dataset name")
      output = extract_option('--output') || ask("Enter path to the file where to save the model description", :default => "#{name}.json")
      open output, 'w' do |f|
        f << JSON.pretty_generate( :title => name, :columns => columns ) + "\n"
        f.flush
      end
    end

    def apply
      with_project do |project_id|
        cfg_file = args.shift rescue nil
        raise(CommandFailed, "Specify the dataset config file") unless cfg_file
        fh = open(cfg_file, 'r') rescue raise(CommandFailed, "Error reading dataset config file '#{cfg_file}'")
        content = fh.readlines.join
        config = JSON.parse(content) # rescue raise(CommandFailed, "Error parsing dataset config file #{cfg_file}")
        puts Gooddata::Dataset::Dataset.new(config).to_maql    
      end
    end

    private

    def with_project
      project_id = extract_option('--project')
      raise CommandFailed.new "Project not specified, use the --project switch" unless project_id
      gooddata
      yield project_id
    end
    
    def ask_for_fields
      guesser = Guesser.new create_dataset.read
      guess = guesser.guess(1000)
      model = []
      connection_point_set = false
      question_fmt = 'Select data type of column #%i (%s)'
      guesser.headers.each_with_index do |header, i|
        options = guess[header].map { |t| t.to_s }
        options = options.select { |t| t != :connection_point.to_s } if connection_point_set
        type = ask question_fmt % [ i + 1, header ], :answers => options
        model.push :title => header, :name => header, :type => type.upcase
        connection_point_set = true if type == :connection_point.to_s
      end
      model
    end

    def create_dataset
      file = extract_option('--file-csv')
      return Gooddata::Load::CSV.new file if file
      raise CommandFailed.new "Unknown data set. Please specify a data set using --file-csv option (more supported data sources to come!)"
    end
  end
  
  ##
  # Utility class to guess data types of a data stream by looking at first couple of rows
  #
  class Guesser

    TYPES_PRIORITY = [ :connection_point, :fact, :date, :attribute ]
    attr_reader :headers

    class << self
      def sort_types(types)
        types.sort do |x, y|
          TYPES_PRIORITY.index(x) <=> TYPES_PRIORITY.index(y)
        end
      end
    end

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
        break unless row && !row.empty? && count < limit
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
        result[header] = Guesser::sort_types @pros[header].keys.select { |type| @cons[header][type].nil? }
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