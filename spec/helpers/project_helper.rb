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

class CachedProjectError < StandardError; end

module GoodData
  module Helpers
    module ProjectHelper
      include GoodData::Environment::ProjectHelper

      ENVIRONMENT = 'TESTING'
      PROJECT_TITLE = 'DailyUse Project for gooddata-ruby integration tests - DO NOT DELETE'
      CACHE_DIR = 'spec/cache/integration_projects/'
      @reuse_integration_project = GoodData::Environment::VCR_ON ? false : ENV['REUSE_INTEGRATION_PROJECT']
      @project_id = nil
      @process_id = nil
      @schedule_id = nil

      class << self
        attr_writer :project_id
        attr_writer :schedule_id
        attr_writer :process_id

        def get_default_project(opts = { :client => GoodData.connection })
          pid = project_id(opts[:client])
          GoodData::Project[pid, opts]
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
            token: ConnectionHelper::SECRETS[:gd_project_token],
            environment: ProjectHelper::ENVIRONMENT
          )

          [project, blueprint, spec]
        end

        def project_id(client)
          if @project_id.nil?
            if @reuse_integration_project
              reuse_project_id(client)
            else
              setup_platform_environment(client)
            end
          end
          @project_id
        end

        def process_id(client)
          project_id(client) if @process_id.nil?
          @process_id
        end

        def schedule_id(client)
          project_id(client) if @schedule_id.nil?
          @schedule_id
        end

        def reuse_project_id(client)
          begin # rubocop:disable RedundantBegin
            project_id = File.read(File.join(CACHE_DIR, GoodData::Environment::ConnectionHelper::DEFAULT_DOMAIN, 'project'))
            project = client.projects(project_id)
            unless project.title == PROJECT_TITLE
              project.delete
              GoodData.logger.error("Cached project modified")
              raise CachedProjectError 'Cached project modified'
            end
            GoodData.logger.info("Reusing project ID: #{project_id}")
            @project_id = project.pid
            process_id = File.read(File.join(CACHE_DIR, GoodData::Environment::ConnectionHelper::DEFAULT_DOMAIN, 'process'))
            project.processes(process_id)
            GoodData.logger.info("Reusing process ID: #{process_id}")
            @process_id = process_id
            schedule_id = File.read(File.join(CACHE_DIR, GoodData::Environment::ConnectionHelper::DEFAULT_DOMAIN, 'schedule'))
            project.schedules(schedule_id)
            GoodData.logger.info("Reusing schedule ID: #{schedule_id}")
            @schedule_id = schedule_id
          rescue CachedProjectError, Errno::ENOENT, RestClient::NotFound, RestClient::Gone => e
            GoodData.logger.warn("Cached project not found: #{e.message}")
            setup_platform_environment(client)
            FileUtils.mkpath(File.join(CACHE_DIR, GoodData::Environment::ConnectionHelper::DEFAULT_DOMAIN))
            File.write(File.join(CACHE_DIR, GoodData::Environment::ConnectionHelper::DEFAULT_DOMAIN, 'project'), @project_id)
            File.write(File.join(CACHE_DIR, GoodData::Environment::ConnectionHelper::DEFAULT_DOMAIN, 'process'), @process_id)
            File.write(File.join(CACHE_DIR, GoodData::Environment::ConnectionHelper::DEFAULT_DOMAIN, 'schedule'), @schedule_id)
          end
        end

        def setup_platform_environment(client)
          begin # rubocop:disable RedundantBegin TODO: remove this after droping JRuby which does not support rescue without begin
            project = client.create_project(
              title: PROJECT_TITLE,
              auth_token: ConnectionHelper::SECRETS[:prod_token]
            )
            proc = GoodData::Process.deploy(File.expand_path('./../../spec/data/cc', __dir__),
                                            project: project,
                                            client: client,
                                            name: 'Test process pepa GRAPH')
            ruby_process = project.deploy_process(
              RUBY_HELLO_WORLD_PROCESS_PATH,
              name: RUBY_HELLO_WORLD_PROCESS_NAME
            )
            schedule = proc.create_schedule(
              CC_SCHEDULE_CRON,
              'graph/graph.grf',
              params: RUBY_PARAMS,
              hidden_params: RUBY_SECURE_PARAMS,
              state: 'DISABLED'
            )
            ruby_schedule = ruby_process.create_schedule(
              schedule,
              'main.rb',
              params: RUBY_PARAMS,
              hidden_params: RUBY_SECURE_PARAMS,
              state: 'DISABLED'
            )
            @project_id = project.pid
            @process_id = File.basename(ruby_process.uri)
            @schedule_id = File.basename(ruby_schedule.uri)
          rescue StandardError => e
            ruby_schedule.delete if ruby_schedule
            schedule.delete if schedule
            ruby_process.delete if ruby_process
            proc.delete if proc
            project.delete if project
            fail e, 'The mandatory project, processes and schedules cannot be created in this environment!', caller
          end
        end
      end
    end
  end
end
