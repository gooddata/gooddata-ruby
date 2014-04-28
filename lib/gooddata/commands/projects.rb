# encoding: UTF-8

require 'pathname'

module GoodData::Command
  class Projects
    class << self
      def list
        GoodData::Project.all
      end
    end
  end
end

