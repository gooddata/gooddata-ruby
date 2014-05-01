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

        fail 'Unable to create new schedule' if res.nil?

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

    def params
      @json['schedule']['params']
    end

    def timezone
      @json['schedule']['timezone']
    end

    def timezone=(new_timezone)
      @json['schedule']['timezone'] = new_timezone
      @dirty = true
    end

    def type=(new_type)
      @json['schedule']['type'] = new_type
      @dirty = true
    end

    def cron=(new_cron)
      @json['schedule']['cron'] = new_cron
      @dirty = true
    end

    def process_id=(new_project_id)
      @json['schedule']['params']['PROCESS_ID'] = new_project_id
      @dirty = true
    end

    def executable=(new_executable)
      @json['schedule']['params']['EXECUTABLE'] = new_executable
      @dirty = true
    end

    def executions
      if @json
        url = @json['schedule']['links']['executions']
        res = GoodData.get url
        res['executions']['items']
      end
    end

    def params=(new_param)
      @json['schedule']['params'].merge!(new_param)
      @dirty = true
    end

    def hidden_params=(new_hidden_param)
      @json['schedule']['hiddenParams'].merge!(new_hidden_param)
      @dirty = true
    end

    def save
      if @dirty
        update_json = {
            'schedule' => {
                'type' => @json['schedule']['type'],
                'timezone' => @json['schedule']['timezone'],
                'cron' => @json['schedule']['cron'],
                'params' => @json['schedule']['params'],
                'hiddenParams'=> @json['schedule']['hiddenParams']
            }
        }
        res = GoodData.put self.uri, update_json

        @json = res
        @dirty = false
      end
    end

    def uri
      @json['schedule']['links']['self'] if @json && @json['schedule'] && @json['schedule']['links']
    end

  end
end
