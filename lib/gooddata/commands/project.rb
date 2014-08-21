# encoding: UTF-8

require 'pathname'

module GoodData
  module Command
    class Project
      class << self
        # Create new project based on options supplied
        def create(options = {})
          title = options[:title]
          summary = options[:summary]
          template = options[:template]
          token = options[:token]

          GoodData::Project.create(:title => title, :summary => summary, :template => template, :auth_token => token)
        end

        # Show existing project
        def show(id)
          GoodData::Project[id]
        end

        def invite(project_id, email, role, msg = GoodData::Project::DEFAULT_INVITE_MESSAGE)
          msg = GoodData::Project::DEFAULT_INVITE_MESSAGE if msg.nil? || msg.empty?

          project = GoodData::Project[project_id]
          fail "Invalid project id '#{project_id}' specified" if project.nil?

          project.invite(email, role, msg)
        end

        # Clone existing project
        def clone(project_id, options)
          GoodData.with_project(project_id) do |project|
            project.clone(options)
          end
        end

        # Delete existing project
        def delete(project_id)
          p = GoodData::Project[project_id]
          p.delete
        end

        # Get Spec and ID (of project)
        def get_spec_and_project_id(base_path)
          goodfile_path = GoodData::Helpers.find_goodfile(Pathname(base_path))
          fail 'Goodfile could not be located in any parent directory. Please make sure you are inside a gooddata project folder.' if goodfile_path.nil?
          goodfile = JSON.parse(File.read(goodfile_path), :symbolize_names => true)
          spec_path = goodfile[:model] || fail('You need to specify the path of the build spec')
          fail "Model path provided in Goodfile \"#{spec_path}\" does not exist" unless File.exist?(spec_path) && !File.directory?(spec_path)

          spec_path = Pathname(spec_path)

          content = File.read(spec_path)
          spec = if spec_path.extname == '.rb'
                   eval(content)
                 elsif spec_path.extname == '.json'
                   JSON.parse(spec_path, :symbolize_names => true)
                 end
          [spec, goodfile[:project_id]]
        end

        def list_users(pid)
          users = []
          finished = false
          offset = 0
          # Limit set to 1000 to be safe
          limit = 1000
          until finished
            result = GoodData.get('/gdc/projects/#{pid}/users?offset=#{offset}&limit=#{limit}')
            result['users'].map do |u|
              as = u['user']
              users.push(
                  :login => as['content']['email'],
                  :uri => as['links']['self'],
                  :first_name => as['content']['firstname'],
                  :last_name => as['content']['lastname'],
                  :role => as['content']['userRoles'].first,
                  :status => as['content']['status']
            )
            end
            if result['users'].count == limit
              offset += limit
            else
              finished = true
            end
          end
          users
        end

        # Update project
        def update(opts = {})
          client = opts[:client]
          fail ArgumentError, 'No :client specified' if client.nil?

          p = opts[:project]
          fail ArgumentError, 'No :project specified' if p.nil?

          project = GoodData::Project[p, opts]
          fail ArgumentError, 'Wrong :project specified' if project.nil?

          GoodData::Model::ProjectCreator.migrate(:spec => opts[:spec], :client => client, :project => project)
        end

        # Build project
        def build(opts = {})
          client = opts[:client]
          fail ArgumentError, 'No :client specified' if client.nil?

          GoodData::Model::ProjectCreator.migrate(:spec => opts[:spec], :token => opts[:token], :client => client)
        end

        def validate(project_id)
          GoodData.with_project(project_id) do |p|
            p.validate
          end
        end

        def jack_in(options)
          goodfile_path = GoodData::Helpers.find_goodfile(Pathname('.'))

          spin_session = proc do |goodfile, blueprint|
            project_id = options[:project_id] || goodfile[:project_id]
            message = 'You have to provide "project_id". You can either provide it through -p flag'\
               'or even better way is to fill it in in your Goodfile under key "project_id".'\
               'If you just started a project you have to create it first. One way might be'\
               'through "gooddata project build"'
            fail message if project_id.nil? || project_id.empty?

            begin
              require 'gooddata'
              client = GoodData.connect(options)

              GoodData.with_project(project_id, :client => client) do |project|
                fail ArgumentError, 'Wrong project specified' if project.nil?

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
    end
  end
end
