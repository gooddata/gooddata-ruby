# encoding: UTF-8

require_relative '../exceptions/command_failed'

module GoodData
  module Command
    # Low level access to GoodData API
    class Projects
      class << self
        def list
          GoodData::Project.all
        end
      end
    end
  end
end
