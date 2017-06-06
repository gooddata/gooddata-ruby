# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pathname'
require 'terminal-table'

require_relative '../connection'

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
        # @option options [Boolean] :exclude_schedules Specifies whether to include scheduled emails
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
          client, project = GoodData.get_client_and_project(opts)
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
          client = options[:client] || GoodData.connect(options)
          client.with_project(project_id, &:users)
        end

        # Lists users in a project
        #
        # @param options [Hash] List of users
        #
        # TODO: Review and refactor #users & #list_users
        def list_users(options = { client: GoodData.connection })
          client = GoodData.connect(options)
          project = client.projects(options[:project_id])

          rows = project.users.to_a.map do |user|
            [user.email, user.full_name, user.role.title, user.user_groups.join(', ')]
          end

          table = Terminal::Table.new :headings => ['Email', 'Full Name', 'Role', 'Groups'], :rows => rows
          puts table
        end
      end
    end
  end
end
