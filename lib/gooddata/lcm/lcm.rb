# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module LCM
    class << self
      def ensure_users(domain, migration_spec, filter_on_segment = [])
        messages = []
        # Ensure technical user is in all projects
        if migration_spec.key?(:technical_user)
          clients = domain.clients

          clients.peach do |c|
            segment = c.segment
            next if !filter_on_segment.empty? && !(filter_on_segment.include?(segment.id))
            p = client.project
            begin
              p.create_users(migration_spec[:technical_user].map { |u| {login: u, role: 'admin'} })
            rescue RestClient::Exception => e
              messages << {type: :technical_user_addition, status: 'ERROR', message: e.message}
            end
          end
        end
        messages
      end

      def transfer_everything(client, domain, migration_spec, filter_on_segment = [])
        puts 'Ensuring Users - warning: works across whole domain not just provided segment(s)'
        ensure_users(domain, migration_spec, filter_on_segment)

        puts 'Migrating Blueprints'

        domain.segments.peach do |segment|
          next if !filter_on_segment.empty? && !(filter_on_segment.include?(segment.id))
          bp = segment.master_project.blueprint
          segment.clients.each do |c|
            p = c.project
            p.update_from_blueprint(bp)
          end
        end

        puts 'Migrating Processes and Schedules'

        deployment_client = migration_spec.key?(:user_for_deployment) ? GoodData.connect(migration_spec[:user_for_deployment]) : client
        domain.clients.peach do |c|
          segment = c.segment
          next if !filter_on_segment.empty? && !(filter_on_segment.include?(segment.id))
          segment_master = segment.master_project
          project = c.project
          # set metadata
          project.set_metadata('GOODOT_CUSTOM_PROJECT_ID', c.id)
          # copy processes

          deployment_client_segment_master = deployment_client.projects(segment_master.pid)
          deployment_client_project = deployment_client.projects(project.pid)
          GoodData::Project.transfer_processes(deployment_client_segment_master, deployment_client_project)

          GoodData::Project.transfer_schedules(segment_master, project)

          # Set up unique parameters
          deployment_client_project.schedules.peach do |s|
            s.update_params('GOODOT_CUSTOM_PROJECT_ID' => c.id)
            s.update_params('CLIENT_ID' => c.id)
            s.update_params('SEGMENT_ID' => segment.id)
            s.update_params(migration_spec[:additional_params] || {})
            s.update_hidden_params(migration_spec[:additional_hidden_params] || {})
            s.save
          end
        end

        puts 'Migrating Dashboards'
        if filter_on_segment.empty?
          domain.synchronize_clients
        else
          filter_on_segment.map { |s| domain.segments(s).synchronize_clients }
        end
      end
    end
  end
end
