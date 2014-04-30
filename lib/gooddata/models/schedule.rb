# encoding: UTF-8

module GoodData
  class Schedule
    class << self

      def [](id)
        GoodData.get "/gdc/projects/#{GoodData.project.pid}/schedules"
      end

      def create(process_id, cron, executable, options = {})
        default_opts = {
          'type' => 'MSETL',
          'timezone' => 'UTC',
          'cron' => cron,
          'params' => {
            'PROCESS_ID' => process_id,
            'EXECUTABLE' => executable
          },
          'hiddenParams' => {}
        }

        json = {
          'schedule' => default_opts.merge(options)
        }
        pp json

        tmp = json['schedule']['params']['PROCESS_ID']
        fail 'Process ID has to be provided' if tmp.nil? || tmp.empty?

        tmp = json['schedule']['params']['EXECUTABLE']
        fail 'Executable has to be provided' if tmp.nil? || tmp.empty?

        tmp = json['schedule']['cron']
        fail 'Cron schedule has to be provided' if tmp.nil? || tmp.empty?

        tmp = json['schedule']['timezone']
        fail 'A timezone has to be provided' if tmp.nil? || tmp.empty?

        tmp = json['schedule']['type']
        fail 'Schedule type has to be provided' if tmp.nil? || tmp.empty?


        url = "/gdc/projects/#{GoodData.project.pid}/schedules"
        res = GoodData.post url, json

        new_obj_json = GoodData.get res['schedule']['links']['self']
        GoodData::Schedule.new(new_obj_json)
      end
    end

    def initialize(json)
      @json = json
    end

    def delete
      GoodData.delete self.uri
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

    def uri
      @json['schedule']['links']['self'] if @json && @json['schedule'] && @json['schedule']['links']
    end

  end
end
