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
              p.create_users(migration_spec[:technical_user].map { |u| { login: u, role: 'admin' } })
            rescue RestClient::Exception => e
              messages << { type: :technical_user_addition, status: 'ERROR', message: e.message }
            end
          end
        end
        messages
      end

      def transfer_everything(client, domain, migration_spec, filter_on_segment = [], opts = {})
        puts 'Ensuring Users - warning: works across whole domain not just provided segment(s)'
        ensure_users(domain, migration_spec, filter_on_segment)

        puts 'Migrating Blueprints'

        bp_opts = {
          update_preference: opts[:update_preference] || opts['update_preference'],
          maql_replacements: opts[:maql_replacements] || opts['maql_replacements']
        }

        tags = opts[:production_tag] || opts['production_tag']

        domain.segments.peach do |segment|
          next if !filter_on_segment.empty? && !(filter_on_segment.include?(segment.id))
          bp = segment.master_project.blueprint
          segment.clients.each do |c|
            p = c.project
            p.update_from_blueprint(bp, bp_opts)
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

          GoodData::Project.transfer_tagged_stuff(segment_master, project, tags) if tags
        end

        puts 'Migrating Dashboards'
        if filter_on_segment.empty?
          domain.synchronize_clients
        else
          filter_on_segment.map { |s| domain.segments(s).synchronize_clients }
        end
      end

      def transfer_label_types(source_project, targets)
        semaphore = Mutex.new

        synchronized_puts = proc do |*args|
          semaphore.synchronize { puts args }
        end

        # Convert to array
        targets = [targets] unless targets.is_a?(Array)

        client = source_project.client

        # Get attributes from source project
        attributes = GoodData::Attribute[:all, client: client, project: source_project]

        # Get display forms
        display_forms = attributes.map do |attribute|
          attribute.content['displayForms']
        end

        # Flatten result
        display_forms.flatten!(2)

        # Select only display forms with content type
        display_forms.select! { |display_form| display_form['content']['type'] }

        # Generate transfer table
        transfer = {}
        display_forms.each { |display_form| transfer[display_form['meta']['identifier']] = display_form['content']['type'] }

        puts 'Transferring label types'
        puts JSON.pretty_generate(transfer)

        # Transfer to target projects
        targets.peach do |target|
          transfer.peach do |identifier, type|
            uri = GoodData::MdObject.identifier_to_uri({ project: target, client: target.client }, identifier)
            next unless uri

            obj = GoodData::MdObject[uri, { project: target, client: target.client }]

            if obj
              if obj.content['type'] != type
                synchronized_puts.call "Updating #{identifier} -> #{type} in '#{target.title}'"
                obj.content['type'] = type
                obj.save
              else
                # synchronized_puts.call "Identifier #{identifier} in '#{target.title}' already has desired type - #{type}"
              end
            else
              synchronized_puts.call "Unable to find #{identifier} in '#{target.title}'"
            end
          end
        end
      end
    end
  end
end
