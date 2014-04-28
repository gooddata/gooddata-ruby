require 'gooddata'
require 'pathname'

require_relative '../core/core'
require_relative 'process'

module GoodData
  class Schedule
    class << self
      def [](id)
        if id == :all
          uri = "/gdc/projects/#{GoodData.project.pid}/schedules"
          schedules = GoodData.get(uri)
          schedules['schedules']['items'].each do |schedule|
            Schedule.new(schedule)
          end
        else
          uri = "/gdc/projects/#{GoodData.project.pid}/schedules/#{id}"
          schedule = Schedule.new(GoodData.get(uri))
        end
      end
    end

    def initialize(data)
      @schedule = data
    end

    def all
      Schedule[:all]
    end

    def delete
      GoodData.delete(uri)
    end

    def type
      @schedule['type']
    end

    def params
      @schedule['params']
    end

    def links
      process['links']
    end

    def self
      links['self']
    end

    def state
      #TODO: Changed state to type BOOL.
      state = @schedule['state']
      if state == "ENABLED"
        return 1
      else
        return 0
      end
    end

    def timezone
      @schedule['timezone']
    end

    def cron
      @schedule['name']
    end

    def save
      #TODO: Confused on how to set up the conditional when to post/put
      if @schedule['params']['PROCESS_ID']
        GoodData.put(uri, @schedule)
      else
        GoodData.post(uri, @schedule)
      end
    end

    def executable
      @schedule['params']['EXECUTABLE']
    end

    def process_id
      @schedule['params']['PROCESS_ID']
    end

    def create(options={})

      if options['cron'] && options['params']['PROCESS_ID'] && options['type']
        Schedule.new(options)
      else
        throw "Schedule object is not formatted correctly."
      end
    end

  end
end