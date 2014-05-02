# encoding: UTF-8

require 'pathname'

module GoodData
  module Command
    class Projects
      class << self
        def list
          GoodData::Project.all
        end
      end
    end
  end
end
