# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pmap'

require_relative 'process_helper'

require_relative '../environment/environment'

GoodData::Environment.load

module GoodData::Helpers
  module ScheduleHelper
    include GoodData::Environment::ScheduleHelper

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
end
