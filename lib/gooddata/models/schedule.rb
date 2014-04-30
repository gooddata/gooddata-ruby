# encoding: UTF-8

module GoodData
  class Schedule
    class << self

      def [](id)
        GoodData.get "/gdc/projects/#{GoodData.project.pid}/schedules"
      end

      def create(json)
        url = "/gdc/projects/#{GoodData.project.pid}/schedules"
        res = GoodData.post url, json

        pp res

        # new_obj_json = GoodData.get res['links']['self']
        # GoodData::Schedule.new(new_obj_json)
      end
    end

    def initialize(json)
      @json = json
    end

    def delete
      GoodData.delete self.execution_url
    end

    def execute
      data = {
        :execution => {}
      }
      GoodData.post self.execution_url, data
    end

    def execution_url
      @json['schedule']['links']['executions']
    end

    def type
      @json['schedule']['type']
    end

    def state
      @json['schedule']['state']
    end

    def graph
      @json['schedule']['params']['GRAPH']
    end

  end
end
