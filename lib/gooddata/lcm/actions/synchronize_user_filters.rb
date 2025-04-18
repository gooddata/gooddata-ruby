# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

using TrueExtensions
using FalseExtensions
using IntegerExtensions
using StringExtensions
using NilExtensions

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
        param :data_product, instance_of(Type::GDDataProductType), required: true

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: false

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true

        description 'GDC Project'
        param :gdc_project, instance_of(Type::GdProjectType), required: false

        description 'GDC Project Id'
        param :gdc_project_id, instance_of(Type::StringType), required: false

        description 'User brick users'
        param :users_brick_users, instance_of(Type::ObjectType), required: false, default: []

        description 'Makes the brick run without altering user filters'
        param :dry_run, instance_of(Type::StringType), required: false, default: false

        description 'Number Of Threads'
        param :number_of_threads, instance_of(Type::StringType), required: false, default: '10'
      end

      class << self
        MODES = %w(
          sync_project
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

          config = params.filters_config
          fail 'User filters brick requires configuration how the filter should be setup. For this use the param "filters_config"' if config.blank?

          symbolized_config = GoodData::Helpers.deep_dup(config)
          symbolized_config = GoodData::Helpers.symbolize_keys(symbolized_config)
          symbolized_config[:labels] = symbolized_config[:labels].map { |l| GoodData::Helpers.symbolize_keys(l) }
          multiple_projects_column = params.multiple_projects_column
          number_of_threads = Integer(params.number_of_threads || '10')

          mode = params.sync_mode
          unless MODES.include?(mode)
            fail "The parameter \"sync_mode\" has to have one of the values #{MODES.map(&:to_s).join(', ')} or has to be empty."
          end

          user_filters = load_data(params, symbolized_config)

          run_params = {
            restrict_if_missing_all_values: params.restrict_if_missing_all_values == 'true',
            ignore_missing_values: params.ignore_missing_values == 'true',
            do_not_touch_filters_that_are_not_mentioned: params.do_not_touch_filters_that_are_not_mentioned == 'true',
            domain: domain,
            dry_run: params[:dry_run].to_b,
            users_brick_input: params.users_brick_users
          }
          all_clients = domain.clients(:all, data_product).to_a
          GoodData.gd_logger.info("Synchronizing in mode=#{mode}, number_of_clients=#{all_clients.size}, data_rows=#{user_filters.size} ,")

          GoodData.logger.info("Synchronizing in mode \"#{mode}\"")
          results = []
          case mode
          when 'sync_project', 'sync_one_project_based_on_pid', 'sync_one_project_based_on_custom_id'
            if mode == 'sync_one_project_based_on_pid'
              filter = project.pid
            elsif mode == 'sync_one_project_based_on_custom_id'
              filter = UserBricksHelper.resolve_client_id(domain, project, params.data_product)
            end
            user_filters = user_filters.select { |f| f[:pid] == filter } if filter

            GoodData.gd_logger.info("Synchronizing in mode=#{mode}, project_id=#{project.pid}, data_rows=#{user_filters.size} ,")
            current_results = sync_user_filters(project, user_filters, run_params, symbolized_config)

            results.concat(current_results[:results]) unless current_results.nil? || current_results[:results].empty?
          when 'sync_multiple_projects_based_on_pid', 'sync_multiple_projects_based_on_custom_id'
            users_by_project = run_params[:users_brick_input].group_by { |u| u[:pid] }
            user_filters.group_by { |u| u[:pid] }.flat_map.pmap do |id, new_filters|
              users = users_by_project[id]
              fail "The #{multiple_projects_column} cannot be empty" if id.blank?

              if mode == 'sync_multiple_projects_based_on_custom_id'
                c = all_clients.detect { |specific_client| specific_client.id == id }
                current_project = c.project
              elsif mode == 'sync_multiple_projects_based_on_pid'
                current_project = client.projects(id)
              end

              GoodData.gd_logger.info("Synchronizing in mode=#{mode}, project_id=#{id}, data_rows=#{new_filters.size} ,")
              current_results = sync_user_filters(current_project, new_filters, run_params.merge(users_brick_input: users), symbolized_config)

              results.concat(current_results[:results]) unless current_results.nil? || current_results[:results].empty?
            end
          when 'sync_domain_client_workspaces'
            domain_clients = all_clients
            if params.segments
              segment_uris = params.segments.map(&:uri)
              domain_clients = domain_clients.select { |c| segment_uris.include?(c.segment_uri) }
            end

            working_client_ids = []
            semaphore = Mutex.new

            users_by_project = run_params[:users_brick_input].group_by { |u| u[:pid] }
            user_filters.group_by { |u| u[multiple_projects_column] }.flat_map.pmap do |client_id, new_filters|
              users = users_by_project[client_id]
              fail "Client id cannot be empty" if client_id.blank?

              c = all_clients.detect { |specific_client| specific_client.id == client_id }
              if c.nil?
                params.gdc_logger.warn "Client #{client_id} is not found"
                next
              end
              if params.segments && !segment_uris.include?(c.segment_uri)
                params.gdc_logger.warn "Client #{client_id} is outside segments_filter #{params.segments}"
                next
              end
              current_project = c.project
              fail "Client #{client_id} does not have project." unless current_project

              semaphore.synchronize do
                working_client_ids << client_id.to_s
              end

              GoodData.gd_logger.info("Synchronizing in mode=#{mode}, client_id=#{client_id}, data_rows=#{new_filters.size} ,")
              partial_results = sync_user_filters(current_project, new_filters, run_params.merge(users_brick_input: users), symbolized_config)
              results.concat(partial_results[:results]) unless partial_results.nil? || partial_results[:results].empty?
            end

            GoodData.gd_logger.info("Synchronizing in mode=#{mode}, working_client_ids=#{working_client_ids.join(', ')} ,") if working_client_ids.size < 50

            unless run_params[:do_not_touch_filters_that_are_not_mentioned]
              to_be_deleted_clients = UserBricksHelper.non_working_clients(domain_clients, working_client_ids)
              to_be_deleted_clients.peach(number_of_threads) do |c|
                begin
                  current_project = c.project
                  users = users_by_project[c.client_id]
                  params.gdc_logger.info "Delete all filters in project #{current_project.pid} of client #{c.client_id}"

                  GoodData.gd_logger.info("Delete all filters in project_id=#{current_project.pid}, client_id=#{c.client_id} ,")
                  current_results = sync_user_filters(current_project, [], run_params.merge(users_brick_input: users), symbolized_config)

                  results.concat(current_results[:results]) unless current_results.nil? || current_results[:results].empty?
                rescue StandardError => e
                  params.gdc_logger.error "Failed to clear filters of  #{c.client_id} due to: #{e.inspect}"
                end
              end
            end
          end

          {
            results: results
          }
        end

        def sync_user_filters(project, filters, params, filters_config)
          # Do not change this line -> can cause paralelisation errors in jRuby viz TMA-963
          project.add_data_permissions(GoodData::UserFilterBuilder.get_filters(filters, filters_config), params)
        end

        def load_data(params, symbolized_config)
          filters = []
          headers_in_options = params.csv_headers == 'false' || true
          csv_with_headers = if GoodData::UserFilterBuilder.row_based?(symbolized_config)
                               false
                             else
                               headers_in_options
                             end

          multiple_projects_column = params.multiple_projects_column
          data_source = GoodData::Helpers::DataSource.new(params.input_source)

          tmp = without_check(PARAMS, params) do
            File.open(data_source.realize(params), 'r:UTF-8')
          end

          begin
            GoodData.logger.info('Start reading data')
            row_count = 0
            CSV.foreach(tmp, :headers => csv_with_headers, :return_headers => false, :header_converters => :downcase, :encoding => 'utf-8') do |row|
              filters << row.to_hash.merge(pid: row[multiple_projects_column.downcase])
              row_count += 1
              GoodData.logger.info("Read #{row_count} rows") if (row_count % 50_000).zero?
            end
            GoodData.logger.info("Done reading data, total #{row_count} rows")
          rescue Exception => e # rubocop:disable RescueException
            fail "There was an error during loading data. Message: #{e.message}. Error: #{e}"
          end

          if filters.empty? && %w(sync_multiple_projects_based_on_pid sync_multiple_projects_based_on_custom_id).include?(params.sync_mode)
            fail 'The filter set can not be empty when using sync_multiple_projects_* mode as the filters contain \
                  the project ids in which the permissions should be changed'
          end

          filters
        end
      end
    end
  end
end
