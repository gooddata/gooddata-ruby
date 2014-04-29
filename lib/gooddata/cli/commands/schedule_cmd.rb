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
        fail 'Project ID must be provided' if pid.nil? || pid.empty?

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
    c.command :delete do |del|
      del.action do |global_options, options, args|
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
        fail 'Project ID must be provided' if pid.nil? || pid.empty?

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
        fail 'Project ID must be provided' if pid.nil? || pid.empty?

        # Example post body.
        # body: "{\n    \"schedule\" : {\n        \"type\" : \"MSETL\",\n        \"timezone\" : \"UTC\",\n        \"cron\" : \"0 15 27 7 *\",\n        \"params\": {\n            \"PROCESS_ID\" : \"{process-id}\",\n            \"EXECUTABLE\" : \"graph/run.grf\",\n            \"PARAM1_NAME\" : \"PARAM1_VALUE\",\n            \"PARAM2_NAME\" : \"PARAM2_VALUE\"\n        },\n        \"hiddenParams\" : {\n            \"HPARAM1_NAME\" : \"HPARAM1_VALUE\",\n            \"HPARAM2_NAME\" : \"HPARAM2_VALUE\"\n        }\n    }\n}",

        if args.length > 0

          sch = {
              'type' => args.first,
              'timezone' => arg[1],
              'cron' => args[2],
              'process_id' => args[3],
              'executable' => args[4],
              #TODO: Tomas, how to pass hidden params?
              'hidden_params' => args[5..9]
          }

          GoodData.connect(opts)

          GoodData::Command::Schedule.create(pid, sch)

        else
          #TODO: Enter interactive.
        end

      end
    end

  end
end