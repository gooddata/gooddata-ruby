# encoding: UTF-8

module GoodData
  class Schedule
    class << self

      def [](id)
        GoodData.get "/gdc/projects/#{GoodData.project.pid}/schedules"
      end

      def create(json)
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
