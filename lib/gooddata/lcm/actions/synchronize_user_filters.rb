# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeUserFilters < BaseAction
      DESCRIPTION = 'Synchronizes User Permissions Between Projects'

      PARAMS = define_params(self) do
        description 'Client Used For Connecting To GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Input Source'
        param :input_source, instance_of(Type::HashType), required: true

        description 'Synchronization Mode (e.g. sync_one_project_based_on_pid)'
        param :sync_mode, instance_of(Type::StringType), required: false, default: 'sync_project'

        description 'Column That Contains Target Project IDs'
        param :multiple_projects_column, instance_of(Type::StringType), required: false

        description 'Filters Config'
        param :filters_config, instance_of(Type::HashType), required: true

        description 'Input Source Contains CSV Headers?'
        param :csv_headers, instance_of(Type::StringType), required: false

        description 'Restrict If Missing Values In Input Source'
        param :restrict_if_missing_all_values, instance_of(Type::StringType), required: false

        description 'Ignore Missing Values In Input Source'
        param :ignore_missing_values, instance_of(Type::StringType), required: false

        description 'Do Not Touch Filters That Are Not Mentioned'
        param :do_not_touch_filters_that_are_not_mentioned, instance_of(Type::StringType), required: false

        description 'Restricts synchronization to specified segments'
        param :segments_filter, array_of(instance_of(Type::StringType)), required: false

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'Domain'
        param :domain, instance_of(Type::StringType), required: false

        description 'DataProduct to manage'
        param :data_product, instance_of(Type::GdProductType), required: true

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: false

        description 'DataLogger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true

        description 'GDC Project'
        param :gdc_project, instance_of(Type::GdProjectType), required: false

        description 'GDC Project Id'
        param :gdc_project_id, instance_of(Type::StringType), required: false

        description 'User brick users'
        param :users_brick_users, instance_of(Type::ObjectType), required: false

        description 'Fail Early'
        param :fail_early, instance_of(Type::BooleanType), required: false

        description 'Strict'
        param :strict, instance_of(Type::BooleanType), required: false

        description 'Username'
        param :username, instance_of(Type::StringType), required: false

        description 'Password'
        param :password, instance_of(Type::StringType), required: false

        description 'AWS Client'
        param :aws_client, instance_of(Type::GdSmartHashType), required: false

        description 'Input source of the Users Brick. Needed to prevent ' \
                    'deletion of filters for a user that is to be removed.'
        param :users_brick_config, instance_of(Type::UsersBrickConfig), required: true

        description 'Development Client Used for Connecting to GD'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'GDC client protocol'
        param :client_gdc_protocol, instance_of(Type::StringType), required: false

        description 'GDC client hostname'
        param :client_gdc_hostname, instance_of(Type::StringType), required: false

        description 'GDC password'
        param :gdc_password, instance_of(Type::StringType), required: false

        description 'GDC username'
        param :gdc_username, instance_of(Type::StringType), required: false

        description 'Additional Hidden Parameters'
        param :additional_hidden_params, instance_of(Type::HashType), required: false

        # gdc_project/gdc_project_id, required: true
        # organization/domain, required: true
      end

      class << self
        MODES = %w(
          add_to_organization
          sync_project
          sync_domain_and_project
          sync_multiple_projects_based_on_pid
          sync_one_project_based_on_pid
          sync_one_project_based_on_custom_id
          sync_multiple_projects_based_on_custom_id
          sync_domain_client_workspaces
        )

        def call(params)
          client = params.gdc_gd_client
          domain_name = params.organization || params.domain
          fail "Either organisation or domain has to be specified in params" unless domain_name
          domain = client.domain(domain_name) if domain_name
          project = client.projects(params.gdc_project) || client.projects(params.gdc_project_id)
          fail "Either project or project_id has to be specified in params" unless project
          data_product = params.data_product

          data_source = GoodData::Helpers::DataSource.new(params.input_source)

          config = params.filters_config
          fail 'User filters brick requires configuration how the filter should be setup. For this use the param "filters_config"' if config.blank?
          symbolized_config = GoodData::Helpers.deep_dup(config)
          symbolized_config = GoodData::Helpers.symbolize_keys(symbolized_config)
          symbolized_config[:labels] = symbolized_config[:labels].map { |l| GoodData::Helpers.symbolize_keys(l) }
          headers_in_options = params.csv_headers == 'false' || true

          mode = params.sync_mode
          unless MODES.include?(mode)
            fail "The parameter \"sync_mode\" has to have one of the values #{MODES.map(&:to_s).join(', ')} or has to be empty."
          end
          filters = []

          csv_with_headers = if GoodData::UserFilterBuilder.row_based?(symbolized_config)
                               false
                             else
                               headers_in_options
                             end

          multiple_projects_column = params.multiple_projects_column
          unless multiple_projects_column
            client_modes = %w(sync_domain_client_workspaces sync_one_project_based_on_custom_id sync_multiple_projects_based_on_custom_id)
            multiple_projects_column = if client_modes.include?(mode)
                                         'client_id'
                                       else
                                         'project_id'
                                       end
          end

          run_params = {
            restrict_if_missing_all_values: params.restrict_if_missing_all_values == 'true',
            ignore_missing_values: params.ignore_missing_values == 'true',
            do_not_touch_filters_that_are_not_mentioned: params.do_not_touch_filters_that_are_not_mentioned == 'true',
            domain: domain,
            dry_run: false,
            users_brick_input: params.users_brick_users
          }

          puts "Synchronizing in mode \"#{mode}\""
          case mode
          when 'sync_project'
            CSV.foreach(File.open(data_source.realize(params), 'r:UTF-8'), headers: csv_with_headers, return_headers: false, encoding: 'utf-8') do |row|
              filters << row
            end
            filters_to_load = GoodData::UserFilterBuilder.get_filters(filters, symbolized_config)
            puts "Synchronizing #{filters_to_load.count} filters"
            project.add_data_permissions(filters_to_load, run_params)
          when 'sync_one_project_based_on_pid'
            CSV.foreach(File.open(data_source.realize(params), 'r:UTF-8'), headers: csv_with_headers, return_headers: false, encoding: 'utf-8') do |row|
              filters << row if row[multiple_projects_column] == project.pid
            end
            filters_to_load = GoodData::UserFilterBuilder.get_filters(filters, symbolized_config)
            puts "Synchronizing #{filters_to_load.count} filters"
            project.add_data_permissions(filters_to_load, run_params)
          when 'sync_multiple_projects_based_on_pid'
            CSV.foreach(File.open(data_source.realize(params), 'r:UTF-8'), headers: csv_with_headers, return_headers: false, encoding: 'utf-8') do |row|
              filters << row.to_hash
            end
            filters.group_by { |u| u[multiple_projects_column] }.flat_map do |project_id, new_filters|
              fail "Project id cannot be empty" if project_id.blank?
              project = client.projects(project_id)
              filters_to_load = GoodData::UserFilterBuilder.get_filters(new_filters, symbolized_config)
              puts "Synchronizing #{filters_to_load.count} filters in project #{project.pid}"
              project.add_data_permissions(filters_to_load, run_params)
            end
          when 'sync_one_project_based_on_custom_id'
            filter_value = UserBricksHelper.resolve_client_id(domain, project, data_product)

            filepath = File.open(data_source.realize(params), 'r:UTF-8')
            CSV.foreach(filepath, headers: csv_with_headers, return_headers: false, encoding: 'utf-8') do |row|
              client_id = row[multiple_projects_column].to_s
              filters << row if client_id == filter_value
            end

            if filters.empty?
              params.gdc_logger.warn "Project \"#{project.pid}\" does not match with any client ids in input source (both GOODOT_CUSTOM_PROJECT_ID and SEGMENT/CLIENT). \
                                      Unable to get the value to filter users."
            end

            filters_to_load = GoodData::UserFilterBuilder.get_filters(filters, symbolized_config)
            puts "Synchronizing #{filters_to_load.count} filters"
            project.add_data_permissions(filters_to_load, run_params)
          when 'sync_multiple_projects_based_on_custom_id'
            CSV.foreach(File.open(data_source.realize(params), 'r:UTF-8'), headers: csv_with_headers, return_headers: false, encoding: 'utf-8') do |row|
              filters << row.to_hash
            end
            fail 'The filter set can not be empty when using sync_multiple_projects_based_on_custom_id mode' if filters.empty?
            filters.group_by { |u| u[multiple_projects_column] }.flat_map do |client_id, new_filters|
              fail "Client id cannot be empty" if client_id.blank?
              project = domain.clients(client_id, data_product).project
              fail "Client #{client_id} does not have project." unless project
              filters_to_load = GoodData::UserFilterBuilder.get_filters(new_filters, symbolized_config)
              puts "Synchronizing #{filters_to_load.count} filters in project #{project.pid} of client #{client_id}"
              project.add_data_permissions(filters_to_load, run_params)
            end
          when 'sync_domain_client_workspaces'
            CSV.foreach(File.open(data_source.realize(params), 'r:UTF-8'), headers: csv_with_headers, return_headers: false, encoding: 'utf-8') do |row|
              filters << row.to_hash
            end

            domain_clients = domain.clients(:all, data_product)
            if params.segments
              segment_uris = params.segments.map(&:uri)
              domain_clients = domain_clients.select { |c| segment_uris.include?(c.segment_uri) }
            end

            working_client_ids = []

            filters.group_by { |u| u[multiple_projects_column] }.flat_map do |client_id, new_filters|
              fail "Client id cannot be empty" if client_id.blank?
              c = domain.clients(client_id, data_product)
              if params.segments && !segment_uris.include?(c.segment_uri)
                puts "Client #{client_id} is outside segments_filter #{params.segments}"
                next
              end
              project = c.project
              fail "Client #{client_id} does not have project." unless project
              working_client_ids << client_id
              filters_to_load = GoodData::UserFilterBuilder.get_filters(new_filters, symbolized_config)
              puts "Synchronizing #{filters_to_load.count} filters in project #{project.pid} of client #{client_id}"
              project.add_data_permissions(filters_to_load, run_params)
            end

            results = []
            unless run_params[:do_not_touch_filters_that_are_not_mentioned]
              domain_clients.each do |c|
                next if working_client_ids.include?(c.client_id)
                begin
                  project = c.project
                rescue => e
                  puts "Error when accessing project of client #{c.client_id}. Error: #{e}"
                  next
                end
                unless project
                  puts "Client #{c.client_id} has no project."
                  next
                end
                if project.deleted?
                  puts "Project #{project.pid} of client #{c.client_id} is deleted."
                  next
                end

                puts "Delete all filters in project #{project.pid} of client #{c.client_id}"
                results << project.add_data_permissions([], run_params)
              end
            end

            {
              results: results
            }
          end
        end
      end
    end
  end
end
