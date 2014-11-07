# encoding: UTF-8

require 'pp'

require_relative '../shared'
require_relative '../../commands/process'

GoodData::CLI.module_eval do

  desc 'Work with deployed processes'
  arg_name 'Describe arguments to list here'
  command :process do |c|

    c.desc 'Use when you need to redeploy a specific process'
    c.default_value nil
    c.flag :process_id

    c.desc 'Specify directory for deployment'
    c.default_value nil
    c.flag :dir

    c.desc 'Specify type of deployment'
    c.default_value nil
    c.flag :type

    c.desc 'Specify name of deployed process'
    c.default_value nil
    c.flag :name

    c.desc 'Specify executable of the process'
    c.default_value nil
    c.flag :executable

    c.desc "Lists all user's processes deployed on the plaform"
    c.command :list do |list|
      list.action do |global_options, options, args|
        opts = options.merge(global_options)
        client = GoodData.connect(opts)
        opts = opts.merge(:project_id => args[0]) if args.length > 0
        processes = GoodData::Command::Process.list(opts.merge(client: client))
        processes.each do |process|
          puts "#{process.name},#{client.connection.server_url + process.uri}"
        end
      end
    end

    c.desc 'Gives you some basic info about the process'
    c.command :show do |get|
      get.action do |global_options, options, _args|
        opts = options.merge(global_options)
        client = GoodData.connect(opts)
        pp GoodData::Command::Process.get(opts.merge(client: client)).raw_data
      end
    end

    c.desc 'Deploys provided directory to the server'
    c.command :deploy do |deploy|
      deploy.action do |global_options, options, _args|
        opts = options.merge(global_options)
        dir = opts[:dir]
        name = opts[:name]
        fail 'You have to provide a directory or a file to deploy. Use --dir param' if dir.nil? || dir.empty?
        fail 'You have to provide a name of the deployed process.  Use --name param' if name.nil? || name.empty?
        client = GoodData.connect(opts)
        process = GoodData::Command::Process.deploy(dir, opts.merge(client: client))
        puts "Process #{process.uri} was deployed"
      end
    end

    c.desc 'Delete specific process'
    c.command :delete do |deploy|
      deploy.action do |global_options, options, _args|
        opts = options.merge(global_options)
        process_id = opts[:process_id]
        fail 'You have to provide a process id. Use --process_id param' if process_id.nil? || process_id.empty?
        client = GoodData.connect(opts)
        GoodData::Command::Process.delete(process_id, opts.merge(client: client))
        puts "Process #{process_id} was deleted"
      end
    end

    c.desc 'Execute specific deployed process'
    # TODO: Add params. HOW?
    c.command :execute do |deploy|
      deploy.action do |global_options, options, _args|
        opts = options.merge(global_options)
        process_id = opts[:process_id]
        executable = opts[:executable]
        fail 'You have to provide a process id. Use --process_id param' if process_id.nil? || process_id.empty?
        fail 'You have to provide an executable for the process. Use --executable param' if executable.nil? || executable.empty?
        GoodData.connect(opts)
        pp GoodData::Command::Process.execute_process(process_id, executable, opts)
      end
    end
  end
end
