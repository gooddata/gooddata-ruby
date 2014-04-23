require 'gooddata'
require 'pathname'

require_relative '../core/core'

# Schedule Class
module GoodData::Command::Process

  class Schedule

    class << self

      def list(options={})
        GoodData.with_project(options[:project_id]) do
          url = "/gdc/projects/#{:project_id}/schedules"
          list = []
          schedules = GoodData.get(url)
          schedules['schedules']['items'].each do |schedule|
            list << schedule['schedule']
          end
        end
      end

      def update(schedule={}, options={})
        GoodData.with_project(options[:project_id]) do |p|
          url = "/gdc/projects/#{p.obj_id}/schedules/#{schedule[:schedule_id]}"
          payload = {
            'schedule' => {
              'type' => "MSETL",
              'timezone' => schedule['timezone'] ? schedule['timezone'] : "UTC",
              'cron' => schedule['cron'],
              'params' => {
                schedule['params'],
              }
              'hiddenParams' => {
                schedule['hiddenParams'],
              }
            }
          }.to_json
          res = GoodData.put(url, payload)
        end
      end

      def create(schedule={}, options={})
        GoodData.with_project(options[:project_id]) do |p|
          url = "/gdc/projects/#{p.obj_id}/schedules"
          payload = {
            'schedule' => {
              'type' => "MSETL",
              'timezone' => schedule['timezone'] ? schedule['timezone'] : "UTC",
              'cron' => schedule['cron'],
              'params' => {
                schedule['params'],
              }
              'hiddenParams' => {
                schedule['hiddenParams'],
              }
            }
          }.to_json
          res = GoodData.post(url, payload)
        end
      end

      def delete(schedule={}, options={})
        GoodData.with_project(options[:project_id], schedule) do |p|
          url = "/gdc/projects/#{p.obj_id}/schedules/#{schedule_id}/executions"
          res = GoodData.delete(url, schedule['process_id'])
        end
      end

      def exec_list(schedule={}, options={})
        GoodData.with_project(options[:project_id]) do
          url = "#{schedule['link']['executions']}"
          list = []
          executions = GoodData.get(url)
          executions['executions']['items'].each do |execution|
            list << execution
          end
        end
      end

      # Going through with_project in this case is not needed, I left if it is needed.
      def exec(schedule_id)
        GoodData.with_project(options[:project_id]) do
          url = "#{schedule['link']['executions']}/#{schedule_id}"
          payload  = "{\n    \"execution\": {}\n}"
          execution = GoodData.post(url, payload)
        end
      end

      # Also uncessary SEE ABOVE "def exec"
      def exec_status(schedule={})
        GoodData.with_project(options[:project_id]) do
          url = "#{schedule['link']['self']}/execution"
          execution = GoodData.get(url)
        end
      end

    end
  end
end