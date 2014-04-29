# encoding: UTF-8

require_relative '../core/core'

module GoodData::Command
  class Schedule
    class << self
      def list(pid = nil)
        return GoodData::Schedule.list(pid)
      end

      def show(pid = nil, sid = nil)
        return GoodData::Schedule.show(pid, sid)
      end

      def delete(pid = nil, sid = nil)
        return GoodData::Schedule.delete(pid, sid)
      end

      def state(pid = nil, sid = nil)
        return GoodData::Schedule.state(pid, sid)
      end

      def create(pid = nil, schedule)
        return GoodData::Schedule.save(pid, schedule)
      end

    end
  end
end