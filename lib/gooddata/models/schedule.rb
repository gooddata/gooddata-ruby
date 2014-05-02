# encoding: UTF-8

module GoodData
  class Schedule
    class << self

      def [](id)
        GoodData.get "/gdc/projects/#{GoodData.project.pid}/schedules"
      end

      def blah(id)
      end

    end

    def initialize(json)
      @json = json
    end

    def execute
      pp "I am going to execute #{@json['schedule']['params']['EXECUTABLE']}"
    end

  end
end
