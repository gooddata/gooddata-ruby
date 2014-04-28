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
          if (sid === 'all')
            res << schedule
          elsif (sid == schedule['params']['PROCESS_ID'])
            res << schedule
          end
        end
        res
      end

      def state(pid = nil, sid = nil)
        if pid == nil && sid == nil
          @schedule['state']
        else
          GoodData.get("/gdc/projects/#{pid}/schedules/#{sid}")['state']
        end
      end

      def delete(pid=nil, sid=nil)
        pid = GoodData.project.pid if pid.nil? || pid.empty?
        uri = "/gdc/projects/#{pid}/schedules/#{sid}"
        GoodData.delete(uri)
      end

    end

    def initialize(data)
      @schedule = data
    end

    def all
      Schedule[:all]
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

    def timezone
      @schedule['timezone']
    end

    def cron
      @schedule['name']
    end

    def save(pid = nil, sid = nil)
      pid = GoodData.project.pid if pid.nil? || pid.empty?
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

    if options['type'] && options['cron'] && options['params']['PROCESS_ID'] && options['params']['EXECUTABLE']
      Schedule.new(options)
      Schedule.save
    else
      throw "Schedule object is not formatted correctly."
    end

  end

end