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

        def create_random_user(client, opts = {})
          num = rand(1e7)
          login = opts[:login] || "gemtest#{num}@gooddata.com"

          opts = {
            email: login,
            login: login,
            first_name: 'the',
            last_name: num.to_s,
            role: 'editor',
            password: CryptoHelper.generate_password,
            domain: ConnectionHelper::DEFAULT_DOMAIN
          }
          GoodData::Membership.create(opts, client: client)
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
