# encoding: UTF-8

require 'highline'

# Define GoodData::CLI as GLI Wrapper
module GoodData
  module CLI
    DEFAULT_TERMINAL = HighLine.new unless const_defined?(:DEFAULT_TERMINAL)

    class << self
      def terminal
        DEFAULT_TERMINAL
      end
    end
  end
end
