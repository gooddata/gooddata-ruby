# encoding: UTF-8

module GoodData
  module Environment
    class << self
      def load(env = ENV['GD_ENV'] || 'develop')
        require_relative 'default'
        require_relative env
      end
    end
  end
end
