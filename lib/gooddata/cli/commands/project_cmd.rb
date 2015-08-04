# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pathname'
require 'pp'

require_relative '../shared'
require_relative '../../commands/project'

GoodData::CLI.module_eval do
  desc 'Manage your project'
  arg_name 'project_command'
  command :project do |c|
    c.desc 'If you are in a gooddata project blueprint or if you provide a project id it will start an interactive session inside that project'
    c.command :jack_in do |jack|
      jack.action do |global_options, options, _args|
        opts = options.merge(global_options)
        GoodData::Command::Project.jack_in(opts)
      end
    end

    # TODO: Move away the ask methods. Provide params
    c.desc 'Create a gooddata project'
    c.command :create do |create|
      create.default_value nil
      create.arg_name :driver
      create.flag [:driver]

      create.default_value nil
      create.arg_name :template
      create.flag [:template]

      create.default_value nil
      create.arg_name :summary
      create.flag [:summary]

      create.action do |global_options, options, args|
        opts = options.merge(global_options)

        title = args[0] || ask('Project name')
        summary = opts[:summary] || args[1] || ask('Project summary') { |q| q.default = '' }
        template = opts[:template] || args[2] || ask('Project template')
        token = opts['token'] || ask('Token')
        driver = opts[:driver] || ask('Driver') { |q| q.default = 'Pg' }

        opts = options.merge(global_options)
        client = GoodData.connect(opts)
        begin
          project = GoodData::Command::Project.create(
            :title => title,
            :summary => summary,
            :template => template,
            :token => token,
            :driver => driver,
            client: client)
        rescue => e
          puts "Error creating project, reason: #{e.inspect}"
          raise e
        end

        puts "Project '#{project.title}' with id #{project.pid} created successfully!"
      end
    end

    c.desc 'Delete a project. Be careful this is impossible to revert'
    c.command :delete do |delete|
      delete.action do |global_options, options, _args|
        id = global_options[:project_id]
        opts = options.merge(global_options)
        client = GoodData.connect(opts)
        GoodData::Command::Project.delete(id, opts.merge(client: client))
      end
    end

    c.desc 'Clones a project. Useful for testing'
    c.command :clone do |clone|
      clone.desc 'Name of the new project'

      clone.default_value nil
      clone.arg_name 'cloned_project_name'
      clone.flag [:t, :title]

      clone.default_value false
      clone.switch [:u, :users]

      clone.default_value true
      clone.switch [:d, :data]

      clone.action do |global_options, options, _args|
        opts = options.merge(global_options)
        id = global_options[:project_id]
        token = opts[:token]
        opts[:auth_token] = token
        fail 'You have to provide a token for creating a project. Please use parameter --token' if token.nil? || token.empty?

        client = GoodData.connect(opts)
        new_project = GoodData::Command::Project.clone(id, opts.merge(client: client))
        puts "Project with title \"#{new_project.title}\" was cloned with id #{new_project.pid}"
      end
    end

    c.desc 'Invites user to project'
    c.command :invite do |store|
      store.action do |global_options, options, args|
        project_id = global_options[:project_id]
        fail 'Project ID has to be provided' if project_id.nil? || project_id.empty?

        email = args.first
        fail 'Email of user to be invited has to be provided' if email.nil? || email.empty?

        role = args[1]
        fail 'Role name has to be provided' if role.nil? || role.empty?

        msg = args[2]
        msg = GoodData::Project::DEFAULT_INVITE_MESSAGE if msg.nil? || msg.empty?

        opts = options.merge(global_options)
        client = GoodData.connect(opts)

        GoodData::Command::Project.invite(project_id, email, role, msg, opts.merge(client: client))
      end
    end

    c.desc 'List users'
    c.command :users do |list|
      list.action do |global_options, options, _args|
        opts = options.merge(global_options)
        client = GoodData.connect(opts)

        pid = global_options[:project_id]
        fail 'Project ID has to be provided' if pid.nil? || pid.empty?

        user_list = GoodData::Command::Project.users(pid, opts.merge(client: client))
        puts user_list.map { |u| [u.last_name, u.first_name, u.login, u.uri].join(',') }
      end
    end

    c.desc 'Shows basic info about a project'
    c.command :show do |show|
      show.action do |global_options, options, _args|
        id = global_options[:project_id]
        opts = options.merge(global_options)
        client = GoodData.connect(opts)
        p = GoodData::Command::Project.show(id, client: client)
        pp p.data
      end
    end

    c.desc 'If you are in a gooddata project blueprint it will apply the changes. If you do not provide a project id it will build it from scratch and create a project for you.'
    c.command :build do |show|
      show.action do |global_options, options, _args|
        opts = options.merge(global_options)
        client = GoodData.connect(opts)
        spec = GoodData::Command::Project.get_spec_and_project_id('.')[0]
        new_project = GoodData::Command::Project.build(opts.merge(spec: spec, client: client))
        puts "Project was created. New project PID is #{new_project.pid}, URI is #{new_project.uri}."
      end
    end

    c.desc 'If you are in a gooddata project blueprint it will apply the changes. If you do not provide a project id it will build it from scratch and create a project for you.'
    c.command :update do |show|
      show.action do |global_options, options, _args|
        opts = options.merge(global_options)
        GoodData.connect(opts)
        spec, project_id = GoodData::Command::Project.get_spec_and_project_id('.')
        project_id = global_options[:project_id] || project_id
        fail 'You have to provide "project_id". You can either provide it through -p flag or even better way is to fill it in in your Goodfile under key "project_id". If you just started a project you have to create it first. One way might be through "gooddata project build"' if project_id.nil? || project_id.empty?
        project = GoodData::Command::Project.update(opts.merge(:spec => spec, :project_id => project_id))
        puts "Migration was done. Project PID is #{project.pid}, URI is #{project.uri}."
      end
    end

    c.desc 'Shows roles in the project'
    c.command :roles do |roles|
      roles.action do |global_options, options, _args|
        project_id = global_options[:project_id]
        fail 'Project ID has to be provided' if project_id.nil? || project_id.empty?

        opts = options.merge(global_options)
        client = GoodData.connect(opts)

        roles = GoodData::Command::Project.roles(project_id, client: client)
        puts roles.map { |r| [r.uri, r.title].join(',') }
      end
    end

    c.desc 'You can run project validation which will check RI and other problems.'
    c.command :validate do |show|
      show.action do |global_options, options, _args|
        opts = options.merge(global_options)
        client = GoodData.connect(opts)
        pp GoodData::Command::Project.validate(global_options[:project_id], opts.merge(client: client))
      end
    end
  end
end
