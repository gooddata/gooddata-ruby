# encoding: UTF-8

require 'pathname'

module GoodData
  module Command
    class Projects
      class << self
        def list(options = { client: GoodData.connection })
          client = options[:client]
          client.projects
        end
      end
    end
  end
end
