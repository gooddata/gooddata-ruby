# encoding: UTF-8

require_relative '../core/core'

module GoodData::Command
  class Schedule
    class << self
      def list(pid = nil)
        return GoodData::Schedule.list(pid)
      end
    end
  end
end