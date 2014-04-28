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

        pid = global_options[:project_id] || args.first
        fail 'Project ID has to be provided' if pid.nil? || pid.empty?

        GoodData.connect(opts)

        list = GoodData::Command::Schedule.list(pid)
        list.each do |schedule|
          puts [schedule['params']['PROCESS_ID'], schedule['params']['GRAPH']].join(',')
        end
      end
    end
  end
end