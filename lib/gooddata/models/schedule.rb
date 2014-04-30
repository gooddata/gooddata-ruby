require 'pathname'
require 'pp'

require_relative '../core/core'
require_relative './process'

module GoodData
  class Schedule
    class << self
      def [](id)
        pp id
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
        pid ||= GoodData.project.pid

        fail 'You have to provide project_id' if pid.nil?

        res = []

        uri = "/gdc/projects/#{pid}/schedules"
        schedules = GoodData.get(uri)
        schedules['schedules']['items'].each do |schedule|
          res << schedule['schedule']
        end
        res
      end

      def all
        Schedule[:all]
      end

      def create(pid = nil, file = nil)
        pid = GoodData.project.pid if pid.nil? || pid.empty?
        if file.nil? || file.empty?
          fail 'No JSON Schedule file was found.'
        else
          Schedule.new(file['schedule'])
          Schedule.save(pid, nil, file)
        end
      end

    end

    def initialize(data)
      @schedule = data
    end

    def state(pid = nil, sid = nil)
      if pid == nil && sid == nil
        @schedule['state']
      else
        GoodData.get("/gdc/projects/#{pid}/schedules/#{sid}")['state']
      end
    end

    def save(pid = nil, sid = nil, sch = nil)

      if sch.nil?
        uri = @schedule['links']['self']
        GoodData.put(uri, @schedule)
      else
        pid = GoodData.project.pid if pid.nil? || pid.empty?
        uri = "/gdc/projects/#{pid}/schedules"
        GoodData.post(uri, sch)
      end

    end

    def delete(pid = nil, sid = nil)
      pid = GoodData.project.pid if pid.nil? || pid.empty?
      links['']
      uri = "/gdc/projects/#{pid}/schedules/#{sid}"
      GoodData.delete(uri)
    end

    def type
      @schedule['type']
    end

    def params
      @schedule['params']
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

  end

  def executable
    @schedule['params']['EXECUTABLE']
  end

  def process_id
    @schedule['params']['PROCESS_ID']
  end

end