# encoding: UTF-8

require 'pathname'

base = Pathname(__FILE__).dirname.expand_path
Dir.glob(base + '*.rb').each do |file|
  require_relative file
end

module GoodData
  module Rest
    class << self
      # Print GoodData::Rest internal info
      def info
        # TODO: Print objects
        # TODO: Print resources
      end
    end
  end
end
