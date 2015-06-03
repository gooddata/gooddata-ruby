# encoding: UTF-8

module GoodData
  module Environment
    class << self
      def load(env = ENV['GD_ENV'] || 'develop')
        require_relative 'default'
        require_relative env

        ENV['GD_SERVER'] = GoodData::Environment::ConnectionHelper::DEFAULT_SERVER
      end
    end
  end
end
