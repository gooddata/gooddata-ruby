# encoding: UTF-8

require 'pmap'

require_relative 'process_helper'

module ScheduleHelper
  SCHEDULE_ID = '54b90771e4b067429a27a549'

  class << self
    def remove_old_schedules(project)
      schedules = project.schedules
      schedules.pmap do |schedule|
        next if schedule.obj_id == SCHEDULE_ID

        puts "Deleting #{schedule.inspect}"
        schedule.delete
      end
    end
  end
end
