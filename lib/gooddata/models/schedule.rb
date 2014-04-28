require 'gooddata'
require 'pathname'

require_relative '../core/core'
require_relative './process'

module GoodData
  class Schedule
    class << self
      def [](id)
        if id == :all
          schedules = self.list
          schedules.each do |schedule|
            Schedule.new(schedule)
          end
        else
          uri = "/gdc/projects/#{GoodData.project.pid}/schedules/#{id}"
          Schedule.new(GoodData.get(uri))
        end
      end

      def list(pid = nil)
        pid = pid || GoodData.project.pid

        fail 'You have to provide project_id' if pid.nil?

        res = []

        uri = "/gdc/projects/#{pid}/schedules"
        schedules = GoodData.get(uri)
        schedules['schedules']['items'].each do |schedule|
          res << schedule['schedule']
        end
        res
      end

      def show(pid = nil, sid = nil)
        fail 'You have to provide project_id' if pid.nil?

        res = []

        schedules = self.list(pid)
        schedules.each do |schedule|
          if(sid === 'all')
            res << schedule
          elsif(sid == schedule['params']['PROCESS_ID'])
            res << schedule
          end
        end
        res
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

#  body: "{\n    \"schedule\" : {\n        \"type\" : \"MSETL\",\n        \"timezone\" : \"UTC\",\n        \"cron\" : \"0 15 27 7 *\",\n        \"params\": {\n            \"PROCESS_ID\" : \"{process-id}\",\n            \"EXECUTABLE\" : \"graph/run.grf\",\n            \"PARAM1_NAME\" : \"PARAM1_VALUE\",\n            \"PARAM2_NAME\" : \"PARAM2_VALUE\"\n        },\n        \"hiddenParams\" : {\n            \"HPARAM1_NAME\" : \"HPARAM1_VALUE\",\n            \"HPARAM2_NAME\" : \"HPARAM2_VALUE\"\n        }\n    }\n}",

    def create(options={})

      if options['type'] && options['cron'] && options['params']['PROCESS_ID'] && options['params']['EXECUTABLE']
        Schedule.new(options)
        Schedule.save
      else
        throw "Schedule object is not formatted correctly."
      end

    end

  end
end