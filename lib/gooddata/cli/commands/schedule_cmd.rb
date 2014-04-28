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
        fail 'Project ID has to be provided' if pid.nil? || pid.empty?

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
        fail 'Project ID has to be provided' if pid.nil? || pid.empty?

        sid = args.first
        sid = 'all' if sid.nil? || sid.empty?

        GoodData.connect(opts)

        list = GoodData::Command::Schedule.show(pid, sid)
        list.each do |schedule|
          pp schedule
        end
      end
    end

    c.desc 'Delete schedule by ID.'
    c.command :delete do |del|
      del.action do |global_options, options, args|
        opts = options.merge(global_options)

        pid = global_options[:project_id]
        fail 'Project ID has to be provided' if pid.nil? || pid.empty?

        sid = args.first
        fail 'Schedule ID is required.' if sid.nil? || sid.empty?

        GoodData.connect(opts)

        GoodData::Command::Schedule.delete(pid, sid)

      end
    end

    c.desc 'Delete schedule by ID.'
    c.command :state do |state|
      state.action do |global_options, options, args|
        opts = options.merge(global_options)

        pid = global_options[:project_id]
        fail 'Project ID has to be provided' if pid.nil? || pid.empty?

        sid = args.first
        fail 'Schedule ID is required.' if sid.nil? || sid.empty?

        GoodData.connect(opts)

        GoodData::Command::Schedule.state(pid, sid)

      end
    end

  end
end