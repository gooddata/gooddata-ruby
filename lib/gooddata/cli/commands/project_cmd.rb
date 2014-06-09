# encoding: UTF-8

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
      jack.action do |global_options, options, args|
        goodfile_path = GoodData::Helpers.find_goodfile(Pathname('.'))

        spin_session = proc do |goodfile, blueprint|
          project_id = global_options[:project_id] || goodfile[:project_id]
          fail "You have to provide 'project_id'. You can either provide it through -p flag or even better way is to fill it in in your Goodfile under key \"project_id\". If you just started a project you have to create it first. One way might be through \"gooddata project build\"" if project_id.nil? || project_id.empty?

          opts = options.merge(global_options)
          GoodData.connect(opts)

          begin
            GoodData.with_project(project_id) do |project|
              puts "Use 'exit' to quit the live session. Use 'q' to jump out of displaying a large output."
              binding.pry(:quiet => true,
                          :prompt => [proc do |target_self, nest_level, pry|
                            'project_live_sesion: '
                          end])
            end
          rescue GoodData::ProjectNotFound
            puts "Project with id \"#{project_id}\" could not be found. Make sure that the id you provided is correct."
          end
        end

        if goodfile_path
          goodfile = MultiJson.load(File.read(goodfile_path), :symbolize_keys => true)
          model_key = goodfile[:model]
          blueprint = GoodData::Model::ProjectBlueprint.new(eval(File.read(model_key)).to_hash) if File.exist?(model_key) && !File.directory?(model_key)
          FileUtils.cd(goodfile_path.dirname) do
            spin_session.call(goodfile, blueprint)
          end
        else
          spin_session.call({}, nil)
        end
      end
    end

    # TODO: Move away the ask methods. Provide params
    c.desc 'Create a gooddata project'
    c.command :create do |create|
      create.action do |global_options, options, args|
        opts = options.merge(global_options)

        title = args[0] || ask('Project name')
        summary = args[1] || ask('Project summary') { |q| q.default = '' }
        template = args[2] || ask('Project template')
        token = opts[:token] || ask('token')

        opts = options.merge(global_options)
        GoodData.connect(opts)
        project = GoodData::Command::Project.create(
          :title => title,
          :summary => summary,
          :template => template,
          :token => token
        )
        puts "Project '#{project.title}' with id #{project.uri} created successfully!"
      end
    end

    c.desc 'Delete a project. Be careful this is impossible to revert'
    c.command :delete do |delete|
      delete.action do |global_options, options, args|
        id = global_options[:project_id]
        opts = options.merge(global_options)
        GoodData.connect(opts)
        GoodData::Command::Project.delete(id)
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

      clone.action do |global_options, options, args|
        opts = options.merge(global_options)
        id = global_options[:project_id]
        token = opts[:token]

        fail 'You have to provide a token for creating a project. Please use parameter --token' if token.nil? || token.empty?

        GoodData.connect(opts)
        GoodData::Command::Project.clone(id, opts)
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
        msg = GoodData::Command::Project::DEFAULT_INVITE_MESSAGE if msg.nil? || msg.empty?

        opts = options.merge(global_options)
        GoodData.connect(opts)

        GoodData::Command::Project.invite(project_id, email, role, msg)
      end
    end

    c.desc 'List users'
    c.command :users do |list|
      list.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)

        pid = global_options[:project_id]
        fail 'Project ID has to be provided' if pid.nil? || pid.empty?

        user_list = GoodData::Command::Project.users(pid)
        puts user_list.map { |u| [u[:last_name], u[:first_name], u[:login], u[:uri]].join(',') }
      end
    end

    c.desc 'Shows basic info about a project'
    c.command :show do |show|
      show.action do |global_options, options, args|
        id = global_options[:project_id]
        opts = options.merge(global_options)
        GoodData.connect(opts)
        p = GoodData::Command::Project.show(id)
        pp p.data
      end
    end

    c.desc 'If you are in a gooddata project blueprint it will apply the changes. If you do not provide a project id it will build it from scratch and create a project for you.'
    c.command :build do |show|
      show.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)
        spec, _ = GoodData::Command::Project.get_spec_and_project_id('.')
        new_project = GoodData::Command::Project.build(opts.merge(:spec => spec))
        puts "Project was created. New project PID is #{new_project.pid}, URI is #{new_project.uri}."
      end
    end

    c.desc 'If you are in a gooddata project blueprint it will apply the changes. If you do not provide a project id it will build it from scratch and create a project for you.'
    c.command :update do |show|
      show.action do |global_options, options, args|

        opts = options.merge(global_options)
        GoodData.connect(opts)
        spec, project_id = GoodData::Command::Project.get_spec_and_project_id('.')
        project_id = global_options[:project_id] || project_id
        fail 'You have to provide "project_id". You can either provide it through -p flag or even better way is to fill it in in your Goodfile under key "project_id". If you just started a project you have to create it first. One way might be through "gooddata project build"' if project_id.nil? || project_id.empty?
        project = GoodData::Command::Project.update(opts.merge(:spec => spec, :project_id => project_id))
        puts "Migration was done. Project PID is #{project.pid}, URI is #{project.uri}."
      end
    end

    c.desc 'Roles'
    c.command :roles do |roles|
      roles.action do |global_options, options, args|
        project_id = global_options[:project_id]
        fail 'Project ID has to be provided' if project_id.nil? || project_id.empty?

        opts = options.merge(global_options)
        GoodData.connect(opts)

        roles = GoodData::Command::Project.roles(project_id)

        puts roles.map { |r| [r['url'], r['role']['projectRole']['meta']['title']].join(',') }
      end
    end

    c.desc 'You can run project validation which will check RI integrity and other problems.'
    c.command :validate do |show|
      show.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)
        pp GoodData::Command::Project.validate(global_options[:project_id])
      end
    end
  end
end
