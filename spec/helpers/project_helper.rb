# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

# Global requires
require 'multi_json'

# Local requires
require 'gooddata/models/models'

require_relative '../environment/environment'

GoodData::Environment.load

module GoodData
  module Helpers
    module ProjectHelper
      include GoodData::Environment::ProjectHelper

      ENVIRONMENT = 'TESTING'

      class << self
        def get_default_project(opts = { :client => GoodData.connection })
          GoodData::Project[GoodData::Helpers::ProjectHelper::PROJECT_ID, opts]
        end

        def delete_old_projects(opts = { :client => GoodData.connection })
          projects = opts[:client].projects
          projects.each do |project|
            next if project.json['project']['meta']['author'] != client.user.uri
            next if project.pid == 'we1vvh4il93r0927r809i3agif50d7iz'
            begin
              puts "Deleting project #{project.title}"
              project.delete
            rescue e
              puts 'ERROR: ' + e.to_s
            end
          end
        end

        def ensure_users(opts = {})
          caller = opts[:caller] ? CGI.escape(opts[:caller]) : rand(1e7)
          amount = opts[:amount] || 1
          usrs = amount.times.map do |i|
            opts[:login] = "gemtest-#{caller}-#{i}@gooddata.com"
            create_user(opts)
          end
          usrs.size == 1 ? usrs.first : usrs
        end

        def create_user(opts = {})
          num = rand(1e7)
          login = opts[:login] || "gemtest#{num}@gooddata.com"

          data = {
            email: login,
            login: login,
            first_name: 'the',
            last_name: login.split('@').first,
            role: 'editor',
            password: login.reverse,
            domain: ConnectionHelper::DEFAULT_DOMAIN
          }
          GoodData::Membership.create(data, client: opts[:client])
        end

        def load_full_project_implementation(client)
          spec = JSON.parse(File.read("./spec/data/blueprints/test_project_model_spec.json"), :symbolize_names => true)
          blueprint = GoodData::Model::ProjectBlueprint.new(spec)

          project = client.create_project_from_blueprint(
            blueprint,
            token: ConnectionHelper::GD_PROJECT_TOKEN,
            environment: ProjectHelper::ENVIRONMENT
          )

          [project, blueprint, spec]
        end
      end
    end
  end
end
