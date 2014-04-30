# encoding: UTF-8

require_relative '../core/core'

module GoodData::Command
  class Schedule
    class << self

      def list(pid = nil)
        return GoodData::Schedule.list(pid)
      end

      def show(project_id = nil, sid = nil)
        GoodData.with_project(project_id) do |project|
          GoodData::Schedule[sid]
        end
      end

      def delete(pid = nil, sid = nil)
        return GoodData::Schedule.delete(pid, sid)
      end

      def state(pid = nil, sid = nil)
        return GoodData::Schedule.state(pid, sid)
      end

      def create(pid = nil, schedule = nil)
        return GoodData::Schedule.create(pid, schedule)
      end

    end
  end
end