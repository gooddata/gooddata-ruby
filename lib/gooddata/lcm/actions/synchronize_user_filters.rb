# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'
require 'thread_safe'

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
        param :sync_mode, instance_of(Type::StringType), required: false

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

        # gdc_project/gdc_project_id, required: true
        # organization/domain, required: true
      end

      class << self
        def call(params)
          client = params.gdc_gd_client
          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) if domain_name
          project = client.projects(params.gdc_project) || client.projects(params.gdc_project_id)

          data_source = GoodData::Helpers::DataSource.new(params.input_source)

          config = params.filters_config
          fail 'User filters brick requires configuration how the filter should be setup. For this use the param "filters_config"' if config.blank?
          symbolized_config = GoodData::Helpers.deep_dup(config)
          symbolized_config = GoodData::Helpers.symbolize_keys(symbolized_config)
          symbolized_config[:labels] = symbolized_config[:labels].map { |l| GoodData::Helpers.symbolize_keys(l) }
          headers_in_options = params.csv_headers == 'false' || true

          mode = params.sync_mode || 'sync_project'
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
            restrict_if_missing_all_values: params.restrict_if_missing_all_values == 'true' ? true : false,
            ignore_missing_values: params.ignore_missing_values == 'true' ? true : false,
            do_not_touch_filters_that_are_not_mentioned: params.do_not_touch_filters_that_are_not_mentioned == 'true' ? true : false,
            domain: domain,
            dry_run: false
          }

          semaphore = Mutex.new

          params.gdc_logger.info("Synchronizing in mode \"#{mode}\"")
          case mode
          when 'sync_project'
            CSV.foreach(File.open(data_source.realize(params), 'r:UTF-8'), headers: csv_with_headers, return_headers: false, encoding: 'utf-8') do |row|
              filters << row
            end
            filters_to_load = GoodData::UserFilterBuilder.get_filters(filters, symbolized_config)
            params.gdc_logger.info("Synchronizing #{filters_to_load.count} filters")
            project.add_data_permissions(filters_to_load, run_params)
          when 'sync_one_project_based_on_pid'
            CSV.foreach(File.open(data_source.realize(params), 'r:UTF-8'), headers: csv_with_headers, return_headers: false, encoding: 'utf-8') do |row|
              filters << row if row[multiple_projects_column] == project.pid
            end
            filters_to_load = GoodData::UserFilterBuilder.get_filters(filters, symbolized_config)
            params.gdc_logger.info("Synchronizing #{filters_to_load.count} filters")
            project.add_data_permissions(filters_to_load, run_params)
          when 'sync_multiple_projects_based_on_pid'
            CSV.foreach(File.open(data_source.realize(params), 'r:UTF-8'), headers: csv_with_headers, return_headers: false, encoding: 'utf-8') do |row|
              filters << row.to_hash
            end
            filters.group_by { |filter| filter[multiple_projects_column] }.flat_pmap do |project_id, new_filters|
              fail "Project id cannot be empty" if project_id.blank?
              client_project = client.projects(project_id)
              Thread.current['filters_to_load'] = GoodData::UserFilterBuilder.get_filters(new_filters, symbolized_config)
              semaphore.synchronize { params.gdc_logger.info("Synchronizing #{Thread.current['filters_to_load'].count} filters in project #{client_project.pid}") }
              client_project.add_data_permissions(Thread.current['filters_to_load'], run_params)
            end
          when 'sync_one_project_based_on_custom_id'
            md = project.metadata
            goodot_id = md['GOODOT_CUSTOM_PROJECT_ID'].to_s

            CSV.foreach(File.open(data_source.realize(params), 'r:UTF-8'), headers: csv_with_headers, return_headers: false, encoding: 'utf-8') do |row|
              client_id = row[multiple_projects_column].to_s
              if (goodot_id && client_id == goodot_id) || domain.clients(client_id).project_uri == project.uri
                filters << row
              end
            end

            if filters.empty?
              fail "Project \"#{project.pid}\" does not match with any client ids in input source (both GOODOT_CUSTOM_PROJECT_ID and SEGMENT/CLIENT). \
              We are unable to get the value to filter users."
            end

            filters_to_load = GoodData::UserFilterBuilder.get_filters(filters, symbolized_config)
            params.gdc_logger.info("Synchronizing #{filters_to_load.count} filters")
            project.add_data_permissions(filters_to_load, run_params)
          when 'sync_multiple_projects_based_on_custom_id'
            CSV.foreach(File.open(data_source.realize(params), 'r:UTF-8'), headers: csv_with_headers, return_headers: false, encoding: 'utf-8') do |row|
              filters << row.to_hash
            end
            filters.group_by { |filter| filter[multiple_projects_column] }.flat_pmap do |client_id, new_filters|
              semaphore.synchronize { params.gdc_logger.debug("Client id #{client_id} with input data #{new_filters}") }
              fail "Client id cannot be empty" if client_id.blank?
              client_project = domain.clients(client_id).project
              fail "Client #{client_id} does not have project." unless client_project
              Thread.current['filters_to_load'] = GoodData::UserFilterBuilder.get_filters(new_filters, symbolized_config)
              semaphore.synchronize do
                params.gdc_logger.debug("Filters to load: #{Thread.current['filters_to_load']}")
                params.gdc_logger.info("Synchronizing #{Thread.current['filters_to_load'].count} filters in project #{client_project.pid} of client #{client_id}")
              end
              client_project.add_data_permissions(Thread.current['filters_to_load'], run_params)
            end
          when 'sync_domain_client_workspaces'
            CSV.foreach(File.open(data_source.realize(params), 'r:UTF-8'), headers: csv_with_headers, return_headers: false, encoding: 'utf-8') do |row|
              filters << row.to_hash
            end

            domain_clients = domain.clients
            params.segments_filter ||= params.segments_filter
            if params.segments_filter
              segments_filter = params.segments_filter.map { |seg| "/gdc/domains/#{domain.name}/segments/#{seg}" }
              domain_clients.select! { |c| segments_filter.include?(c.segment_uri) }
            end

            working_client_ids = ThreadSafe::Array.new

            filters.group_by { |filter| filter[multiple_projects_column] }.flat_pmap do |client_id, new_filters|
              fail "Client id cannot be empty" if client_id.blank?
              segment_client = domain_clients.find { |c| c.client_id.to_s == client_id.to_s }
              if params.segments_filter && !segments_filter.include?(segment_client.segment_uri)
                semaphore.synchronize { params.gdc_logger.warn("Client #{client_id} is outside segments_filter #{params.segments_filter}") }
                next
              end
              client_project = segment_client.project
              fail "Client #{client_id} does not have project." unless client_project
              working_client_ids << client_id.to_s
              Thread.current['filters_to_load'] = GoodData::UserFilterBuilder.get_filters(new_filters, symbolized_config)
              semaphore.synchronize do
                params.gdc_logger.info("Synchronizing #{Thread.current['filters_to_load'].count} filters in project #{client_project.pid} of client #{client_id}")
              end
              client_project.add_data_permissions(Thread.current['filters_to_load'], run_params)
            end

            unless run_params[:do_not_touch_filters_that_are_not_mentioned]
              domain_clients.peach do |domain_client|
                next if working_client_ids.include?(domain_client.client_id.to_s)
                begin
                  clean_up_project = domain_client.project
                rescue => e
                  semaphore.synchronize { params.gdc_logger.warn("Error when accessing project of client #{domain_client.client_id}. Error: #{e}") }
                  next
                end
                unless clean_up_project
                  semaphore.synchronize { params.gdc_logger.warn("Client #{domain_client.client_id} has no project.") }
                  next
                end
                if clean_up_project.deleted?
                  semaphore.synchronize { params.gdc_logger.warn("Project #{clean_up_project.pid} of client #{domain_client.client_id} is deleted.") }
                  next
                end

                semaphore.synchronize { params.gdc_logger.info("Delete all filters in project #{clean_up_project.pid} of client #{domain_client.client_id}") }
                clean_up_project.add_data_permissions([], run_params)
              end
            end
          end

          return # rubocop:disable Style/RedundantReturn
        end
      end
    end
  end
end
