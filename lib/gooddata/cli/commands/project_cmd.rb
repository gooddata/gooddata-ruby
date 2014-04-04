# encoding: UTF-8

require 'pathname'
require 'pp'

require_relative '../shared'
require_relative '../../commands/projects'

GoodData::CLI.module_eval do

  desc 'Manage your projects'
  arg_name 'project_command'
  command :project do |c|

    c.desc "Lists user's projects"
    c.command :list do |list|
      list.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)
        list = GoodData::Command::Projects.list()
        puts list.map { |p| [p.uri, p.title].join(',') }
      end
    end

    c.desc 'If you are in a gooddata project blueprint or if you provide a project id it will start an interactive session inside that project'
    c.command :jack_in do |jack|
      jack.action do |global_options, options, args|
        goodfile_path = GoodData::Helpers.find_goodfile(Pathname('.'))

        spin_session = Proc.new do |goodfile, blueprint|
          project_id = global_options[:project_id] || goodfile[:project_id]
          fail "You have to provide 'project_id'. You can either provide it through -p flag or even better way is to fill it in in your Goodfile under key \"project_id\". If you just started a project you have to create it first. One way might be through \"gooddata project build\"" if project_id.nil? || project_id.empty?

          opts = options.merge(global_options)
          GoodData.connect(opts)

          begin
            GoodData.with_project(project_id) do |project|
              puts "Use 'exit' to quit the live session. Use 'q' to jump out of displaying a large output."
              binding.pry(:quiet => true,
                          :prompt => [proc { |target_self, nest_level, pry|
                            'project_live_sesion: '
                          }])
            end
          rescue GoodData::ProjectNotFound => e
            puts "Project with id \"#{project_id}\" could not be found. Make sure that the id you provided is correct."
          end
        end

        if goodfile_path
          goodfile = MultiJson.load(File.read(goodfile_path), :symbolize_keys => true)
          model_key = goodfile[:model]
          blueprint = GoodData::Model::ProjectBlueprint.new(eval(File.read(model_key)).to_hash) if File.exist?(model_key) && !File.directory?(model_key)
          FileUtils::cd(goodfile_path.dirname) do
            spin_session.call(goodfile, blueprint)
          end
        else
          spin_session.call({}, nil)
        end
      end
    end

    c.desc 'Create a gooddata project'
    c.command :create do |create|
      create.action do |global_options, options, args|
        title = ask 'Project name'
        summary = ask('Project summary') { |q| q.default = '' }
        template = ask('Project template')
        token = ask('token')

        opts = options.merge(global_options)
        GoodData.connect(opts)
        project = GoodData::Command::Projects.create({
                                                       :title => title,
                                                       :summary => summary,
                                                       :template => template,
                                                       :token => token
                                                     })
        puts "Project '#{project.title}' with id #{project.uri} created successfully!"
      end
    end

    c.desc 'Delete a project. Be careful this is impossible to revert'
    c.command :delete do |delete|
      delete.action do |global_options, options, args|
        id = global_options[:project_id]
        opts = options.merge(global_options)
        GoodData.connect(opts)
        GoodData::Command::Projects.delete(id)
      end
    end

    c.desc 'Clones a project. Useful for testing'
    c.command :clone do |clone|
      clone.desc 'Name of the new project'
      clone.default_value nil
      clone.arg_name 'cloned_project_name'
      clone.flag [:n, :name]

      clone.action do |global_options, options, args|
        id = global_options[:project_id]
        name = options[:name]
        token = options[:token]
        opts = options.merge(global_options)
        GoodData.connect(opts)
        GoodData::Command::Projects.clone(id, :name => name, :token => token)
      end
    end

    c.desc 'Shows basic info about a project'
    c.command :show do |show|
      show.action do |global_options, options, args|
        id = global_options[:project_id]
        opts = options.merge(global_options)
        GoodData.connect(opts)
        p = GoodData::Command::Projects.show(id)
        pp p.data
      end
    end

    c.desc 'If you are in a gooddata project blueprint it will apply the changes. If you do not provide a project id it will build it from scratch and create a project for you.'
    c.command :build do |show|
      show.action do |global_options, options, args|
        opts = options.merge(global_options)
        GoodData.connect(opts)
        spec, project_id = GoodData::Command::Projects.get_spec_and_project_id('.')
        new_project = GoodData::Command::Projects.build(opts.merge(:spec => spec))
        puts "Project was created. New project PID is #{new_project.pid}, URI is #{new_project.uri}."
      end
    end

    c.desc 'If you are in a gooddata project blueprint it will apply the changes. If you do not provide a project id it will build it from scratch and create a project for you.'
    c.command :update do |show|
      show.action do |global_options, options, args|

        opts = options.merge(global_options)
        GoodData.connect(opts)
        spec, project_id = GoodData::Command::Projects.get_spec_and_project_id('.')
        project = GoodData::Command::Projects.update(opts.merge(:spec => spec, :project_id => global_options[:project_id] || project_id))
        puts "Migration was done. Project PID is #{project.pid}, URI is #{project.uri}."

      end
    end
  end

end