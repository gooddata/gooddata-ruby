# encoding: UTF-8

require_relative '../shared'
require_relative '../../commands/schedule'

GoodData::CLI.module_eval do

  desc 'Schedule related stuff'
  command :schedule do |c|
    c.desc 'List schedules'
    c.command :list do |list|
      list.action do |global_options, options, args|
        opts = options.merge(global_options)

        pid = global_options[:project_id]
        fail 'Project ID must be provided.' if pid.nil? || pid.empty?

        GoodData.connect(opts)

        list = GoodData::Command::Schedule.list(pid)
        list.each do |schedule|
          puts [schedule['params']['PROCESS_ID'], schedule['params']['GRAPH']].join(',')
        end
      end
    end

    c.desc 'Show schedule detailed info'
    c.command :show do |show|
      show.action do |global_options, options, args|
        opts = options.merge(global_options)

        pid = global_options[:project_id]
        fail 'Project ID must be provided.' if pid.nil? || pid.empty?

        sid = args.first
        sid = 'all' if sid.nil? || sid.empty?

        GoodData.connect(opts)

        list = GoodData::Command::Schedule.show(pid, sid)
        list.each do |schedule|
          pp schedule
        end
      end
    end

    c.desc 'Delete Schedule by ID.'
    c.command :delete do |delete|
      delete.action do |global_options, options, args|
        opts = options.merge(global_options)

        pid = global_options[:project_id]
        fail 'Project ID must be provided.' if pid.nil? || pid.empty?

        sid = args.first
        fail 'Schedule ID must be provided.' if sid.nil? || sid.empty?

        GoodData.connect(opts)

        GoodData::Command::Schedule.delete(pid, sid)

      end
    end

    c.desc 'Get the running status of a schedule.'
    c.command :state do |state|
      state.action do |global_options, options, args|
        opts = options.merge(global_options)

        pid = global_options[:project_id]
        fail 'Project ID must be provided.' if pid.nil? || pid.empty?

        sid = args.first
        fail 'Schedule ID must be provided.' if sid.nil? || sid.empty?

        GoodData.connect(opts)

        GoodData::Command::Schedule.state(pid, sid)

      end
    end

    c.desc 'Create a new Schedule.'
    c.command :create do |create|
      create.action do |global_options, options, args|
        opts = options.merge(global_options)

        pid = global_options[:project_id]
        fail 'Project ID must be provided.' if pid.nil? || pid.empty?
        fail 'A JSON Schedule file was not found.' if args.first.empty?

        file = JSON.load(File.open(args.first, 'r'))

        GoodData.connect(opts)

        GoodData::Command::Schedule.create(pid, file)

      end
    end

  end
end