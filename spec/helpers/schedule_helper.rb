# encoding: UTF-8

require 'pmap'

require_relative 'process_helper'

module ScheduleHelper
  SCHEDULE_ID = '53e029bde4b035034ad4abb6'

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
