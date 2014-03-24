# encoding: UTF-8

require 'highline'

# Define GoodData::CLI as GLI Wrapper
module GoodData
  module CLI
    DEFAULT_TERMINAL = HighLine.new

    class << self
      def terminal
        DEFAULT_TERMINAL
      end
    end
  end
end
