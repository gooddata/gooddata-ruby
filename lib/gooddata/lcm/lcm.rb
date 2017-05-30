# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
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

      def transfer_everything(client, domain, migration_spec, opts = {})
        filter_on_segment = migration_spec[:segments] || migration_spec['segments'] || []

        puts 'Ensuring Users - warning: works across whole domain not just provided segment(s)'
        ensure_users(domain, migration_spec, filter_on_segment)

        puts 'Migrating Blueprints'

        bp_opts = {
          update_preference: opts[:update_preference] || opts['update_preference'],
          maql_replacements: opts[:maql_replacements] || opts['maql_replacements']
        }

        #########################################################
        # New Architecture of Transfer Everything Functionality #
        #########################################################
        #
        # modes = {
        #   release: [
        #     self.synchronize_ldm,
        #     self.synchronize_label_types,
        #     self.synchronize_meta, # Tag specified? If yes, transfer only tagged stuff. If not transfer all meta.
        #     self.synchronize_etl, # Processes, Schedules, Additional Params
        #   ],
        #   provisioning: [
        #     # self.ensure_titles # Handled by Provisioning Brick?
        #     self.ensure_users,
        #     self.delete_clients,
        #     self.provision_clients, # LCM API
        #     self.synchronize_label_types,
        #     self.synchronize_etl # Processes, Schedules, Additional Params
        #   ],
        #   rollout: [ # Works on segments only, not using collect_clients
        #     self.ensure_users,
        #     self.synchronize_ldm,
        #     self.synchronize_label_types,
        #     self.synchronize_etl, # Processes, Schedules, Additional Params
        #     self.synchronize_clients
        #   ]
        # }
        #
        # mode_name = param['mode']
        # mode_actions = modes[mode_name] || fail("Invalid mode specified: '#{mode_name}'")
        # messages = mode_actions.map do |action|
        #   action(params)
        # end

        domain.segments.peach do |segment|
          next if !filter_on_segment.empty? && !(filter_on_segment.include?(segment.id))

          bp = segment.master_project.blueprint
          segment.clients.each do |c|
            p = c.project
            p.update_from_blueprint(bp, bp_opts)
          end

          # target_projects = segment.clients.map(&:project)

          # Transfer metadata objects
          # GoodData::LCM.transfer_meta(segment.master_project, target_projects)
        end

        puts 'Migrating Processes and Schedules'

        deployment_client = migration_spec.key?(:user_for_deployment) ? GoodData.connect(migration_spec[:user_for_deployment]) : client
        domain.clients.peach do |c|
          segment = c.segment
          next if !filter_on_segment.empty? && !(filter_on_segment.include?(segment.id))

          segment_master = segment.master_project
          project = c.project

          # set metadata
          # TODO: Review this and remove if not required or duplicate
          # FIXME: TMA-210
          project.set_metadata('GOODOT_CUSTOM_PROJECT_ID', c.id)

          # copy processes
          deployment_client_segment_master = deployment_client.projects(segment_master.pid)
          deployment_client_project = deployment_client.projects(project.pid)
          GoodData::Project.transfer_processes(deployment_client_segment_master, deployment_client_project)

          GoodData::Project.transfer_schedules(segment_master, project)

          # Set up unique parameters
          deployment_client_project.schedules.peach do |s|
            # TODO: Review this and remove if not required or duplicate (GOODOT_CUSTOM_PROJECT_ID vs CLIENT_ID)
            s.update_params('GOODOT_CUSTOM_PROJECT_ID' => c.id)
            s.update_params('CLIENT_ID' => c.id)
            s.update_params('SEGMENT_ID' => segment.id)
            s.update_params(migration_spec[:additional_params] || {})
            s.update_hidden_params(migration_spec[:additional_hidden_params] || {})
            s.save
          end

          # Transfer label types
          begin
            GoodData::LCM.transfer_label_types(segment_master, project)
          rescue => e
            puts "Unable to transfer label_types, reason: #{e.message}"
          end

          # Transfer tagged objects
          # FIXME: Make sure it is not duplicate functionality mentioned in TMA-171
          tag = migration_spec[:production_tag]
          GoodData::Project.transfer_tagged_stuff(segment_master, project, tag) if tag
        end

        do_not_synchronize_clients = migration_spec[:do_not_synchronize_clients]
        if do_not_synchronize_clients.nil? || !do_not_synchronize_clients
          puts 'Migrating Dashboards'
          if filter_on_segment.empty?
            domain.synchronize_clients
          else
            filter_on_segment.map do |s|
              domain.segments(s).synchronize_clients
            end
          end
        end

        # User groups must be migrated after dashboards
        puts 'Migrating User Groups'
        domain.clients.peach do |c|
          segment = c.segment
          segment_master = segment.master_project
          project = c.project
          GoodData::Project.transfer_user_groups(segment_master, project)
        end
      end

      def transfer_label_types(source_project, targets)
        semaphore = Mutex.new

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

        GoodData.logger.info 'Transferring label types'
        GoodData.logger.info JSON.pretty_generate(transfer)

        # Transfer to target projects
        targets.peach do |target|
          transfer.peach do |identifier, type|
            uri = GoodData::MdObject.identifier_to_uri({ project: target, client: target.client }, identifier)
            next unless uri

            obj = GoodData::MdObject[uri, { project: target, client: target.client }]

            if obj
              if obj.content['type'] != type
                semaphore.synchronize do
                  GoodData.logger.info "Updating #{identifier} -> #{type} in '#{target.title}'"
                end

                obj.content['type'] = type
                obj.save
              end
            else
              semaphore.synchronize do
                GoodData.logger.warn "Unable to find #{identifier} in '#{target.title}'"
              end
            end

            nil
          end

          nil
        end
      end

      # Synchronizes the dashboards tagged with the +$PRODUCTION_TAG+ from development project to master projects
      # Params:
      # +source_workspace+:: workspace with the tagged dashboards that are going to be synchronized to the target workspaces
      # +target_workspaces+:: array of target workspaces where the tagged dashboards are going be synchronized to
      def transfer_meta(source_workspace, target_workspaces, tag = nil)
        objects = get_dashboards(source_workspace, tag)
        begin
          token = source_workspace.objects_export(objects)
          GoodData.logger.info "Export token: '#{token}'"
        rescue => e
          GoodData.logger.error "Export failed, reason: #{e.message}"
        end
        target_workspaces.each do |target_workspace|
          begin
            target_workspace.objects_import(token)
          rescue => e
            GoodData.logger.error "Import failed, reason: #{e.message}"
          end
        end
      end

      # Retrieves all dashboards tagged with the +$PRODUCTION_TAG+ from the +workspace+
      # Params:
      # +workspace+:: workspace with the tagged dashboards
      # Returns enumeration of the tagged dashboards URIs
      def get_dashboards(workspace, tag = nil)
        if tag
          GoodData::Dashboard.find_by_tag(tag, project: workspace, client: workspace.client).map(&:uri)
        else
          GoodData::Dashboard.all(project: workspace, client: workspace.client).map(&:uri)
        end
      end

      def transfer_attribute_drillpaths(source_project, targets, attributes)
        semaphore = Mutex.new

        # Convert to array
        targets = [targets] unless targets.is_a?(Array)

        # Get attributes from source project
        attributes |= source_project.attributes

        # Generate transfer table
        drill_paths = attributes.pmap do |attribute|
          drill_label_uri = attribute.content['drillDownStepAttributeDF']
          if drill_label_uri
            drill_label = source_project.labels(drill_label_uri)
            [attribute.uri, attribute.meta['identifier'], drill_label_uri, drill_label.identifier]
          else
            []
          end
        end
        drill_paths.reject!(&:empty?)

        # Transfer to target projects
        targets.peach do |target|
          drill_paths.peach do |drill_path_info|
            src_attr_uri, attr_identifier, drill_label_uri, drill_path_identifier = drill_path_info

            attr_uri = GoodData::MdObject.identifier_to_uri({ project: target, client: target.client }, attr_identifier)
            next unless attr_uri

            attribute = GoodData::MdObject[attr_uri, project: target, client: target.client]

            if attribute
              drill_path = GoodData::MdObject.identifier_to_uri({ project: target, client: target.client }, drill_path_identifier)
              next unless drill_path

              if !attribute.content['drillDownStepAttributeDF'] || attribute.content['drillDownStepAttributeDF'] != drill_path
                semaphore.synchronize do
                  GoodData.logger.debug <<-DEBUG
Transfer from:
{
  attr_uri: #{src_attr_uri},
  attr_identifier: #{attr_identifier},
  drill_label_uri: #{drill_label_uri},
  drill_label_identifier: #{drill_path_identifier}
}
To:
{
  attr_uri: #{attr_uri},
  attr_identifier: #{attr_identifier},
  drill_label_uri: #{drill_path},
  drill_label_identifier: #{drill_path_identifier}
}
DEBUG
                  GoodData.logger.info "Updating drill path of #{attr_identifier} -> #{drill_path} in '#{target.title}'"
                end

                attribute.content['drillDownStepAttributeDF'] = drill_path
                attribute.save
              end
            else
              semaphore.synchronize do
                GoodData.logger.warn "Unable to find #{attr_identifier} in '#{target.title}'"
              end
            end

            nil
          end

          nil
        end
      end
    end
  end
end
