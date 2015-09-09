# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pathname'

module GoodData
  module Command
    class Project
      class << self
        # Create new project based on options supplied
        def create(options = { client: GoodData.connection })
          title = options[:title]
          summary = options[:summary]
          template = options[:template]
          token = options[:token]
          client = options[:client]
          driver = options[:driver] || 'Pg'
          GoodData::Project.create(:title => title, :summary => summary, :template => template, :auth_token => token, :client => client, :driver => driver)
        end

        # Show existing project
        def show(id, options = { client: GoodData.connection })
          client = options[:client]
          client.projects(id)
        end

        def invite(project_id, email, role, msg = GoodData::Project::DEFAULT_INVITE_MESSAGE, options = {})
          client = options[:client]
          project = client.projects(project_id)
          fail "Invalid project id '#{project_id}' specified" if project.nil?

          project.invite(email, role, msg)
        end

        # Clone existing project
        #
        # @param project_id [String | GoodData::Project] Project id or project instance to delete
        # @option options [String] :data Clone including all the data (default true)
        # @option options [String] :users Clone including all the users (default false)
        # @option options [String] :title Name of the cloned project (default "Clone of {old_project_title}")
        # @option options [Boolean] :verbose (false) Switch on verbose mode for detailed logging
        def clone(project_id, options = { client: GoodData.connection })
          client = options[:client]
          client.with_project(project_id) do |project|
            project.clone(options)
          end
        end

        # Deletes existing project
        #
        # @param project_id [String | GoodData::Project] Project id or project instance to delete
        def delete(project_id, options = { client: GoodData.connection })
          client = options[:client]
          p = client.projects(project_id)
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

        # Update project
        def update(opts = { client: GoodData.connection })
          client = opts[:client]
          fail ArgumentError, 'No :client specified' if client.nil?

          p = opts[:project]
          fail ArgumentError, 'No :project specified' if p.nil?

          project = GoodData::Project[p, opts]
          fail ArgumentError, 'Wrong :project specified' if project.nil?

          GoodData::Model::ProjectCreator.migrate(:spec => opts[:spec], :client => client, :project => project)
        end

        # Build project
        def build(opts = { client: GoodData.connection })
          client = opts[:client]
          fail ArgumentError, 'No :client specified' if client.nil?

          GoodData::Model::ProjectCreator.migrate(opts.merge(:client => client))
        end

        # Performs project validation
        #
        # @param project_id [String | GoodData::Project] Project id or project instance to validate
        # @return [Object] Report of found problems
        def validate(project_id, options = { client: GoodData.connection })
          client = options[:client]
          client.with_project(project_id, &:validate)
        end

        def jack_in(options)
          goodfile_path = GoodData::Helpers.find_goodfile(Pathname('.'))

          spin_session = proc do |goodfile, _blueprint|
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
                binding.pry(:quiet => true, # rubocop:disable Lint/Debugger
                            :prompt => [proc do |_target_self, _nest_level, _pry|
                              'project_live_session: '
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

        # Lists roles in a project
        #
        # @param project_id [String | GoodData::Project] Project id or project instance to list the users in
        # @return [Array <GoodData::Role>] List of project roles
        def roles(project_id, options = { client: GoodData.connection })
          client = options[:client]
          client.with_project(project_id, &:roles)
        end

        # Lists users in a project
        #
        # @param project_id [String | GoodData::Project] Project id or project instance to list the users in
        # @return [Array <GoodData::Membership>] List of project users
        def users(project_id, options = { client: GoodData.connection })
          client = options[:client]
          client.with_project(project_id, &:users)
        end
      end
    end
  end
end
