# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeClients < BaseAction
      DESCRIPTION = 'Synchronize LCM Clients'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'DataProduct to manage'
        param :data_product, instance_of(Type::GDDataProductType), required: false

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'Domain'
        param :domain, instance_of(Type::StringType), required: false

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true

        description 'Table Name'
        param :release_table_name, instance_of(Type::StringType), required: false

        description 'ADS Client'
        param :ads_client, instance_of(Type::AdsClientType), required: false

        description 'Keep number of old master workspace excluding the latest one'
        param :keep_only_previous_masters_count, instance_of(Type::StringType), required: false, default: '-1'

        description 'Additional Hidden Parameters'
        param :additional_hidden_params, instance_of(Type::HashType), required: false

        description 'Abort on error'
        param :abort_on_error, instance_of(Type::StringType), required: false

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: false

        description 'Collect synced status'
        param :collect_synced_status, instance_of(Type::BooleanType), required: false

        description 'Sync failed list'
        param :sync_failed_list, instance_of(Type::HashType), required: false

        description 'Synchronize clients time limit'
        param :sync_clients_timeout, instance_of(Type::StringType), required: false
      end

      RESULT_HEADER = [
        :segment,
        :successful_count,
        :master_name,
        :master_pid
      ]

      class << self
        def call(params)
          GoodData.logger.info 'Starting SynchronizeClients action'
          client = params.gdc_gd_client

          domain_name = params.organization || params.domain
          fail "Either organisation or domain has to be specified in params" unless domain_name
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")
          data_product = params.data_product
          domain_segments = domain.segments(:all, data_product)
          keep_only_previous_masters_count = Integer(params.keep_only_previous_masters_count || "-1")
          sync_clients_options = {}
          sync_clients_options = sync_clients_options.merge(:time_limit => Integer(params.sync_clients_timeout)) if params.sync_clients_timeout

          segments = params.segments.map do |seg|
            domain_segments.find do |s|
              s.segment_id == seg.segment_id
            end
          end

          results = segments.map do |segment|
            next if sync_failed_segment(segment.segment_id, params)

            if params.ads_client
              master_projects = GoodData::LCM2::Helpers.get_master_project_list_from_ads(params.release_table_name, params.ads_client, segment.segment_id)
            else
              master_projects = GoodData::LCM2::Helpers.get_master_project_list_from_nfs(domain_name, data_product.data_product_id, segment.segment_id)
            end

            current_master = master_projects.last
            # TODO: Check res.first.nil? || res.first[:master_project_id].nil?
            master = client.projects(current_master[:master_project_id])
            segment.master_project = master
            segment.save

            GoodData.logger.info "Starting synchronize clients for segment: '#{segment.segment_id}' with master workspace: '#{current_master[:master_project_id]}'"
            res = segment.synchronize_clients(sync_clients_options)
            GoodData.logger.info "Finish synchronize clients for segment: '#{segment.segment_id}'"

            sync_result = res.json['synchronizationResult']
            failed_count = sync_result['failedClients']['count']

            if failed_count.to_i > 0
              error_handle(segment, res, collect_synced_status(params), params)
            end

            if keep_only_previous_masters_count >= 0
              number_of_deleted_projects = master_projects.count - (keep_only_previous_masters_count + 1)

              if number_of_deleted_projects.positive?
                begin
                  removal_master_project_ids = remove_multiple_workspace(params, segment.segment_id, master_projects, number_of_deleted_projects)
                  remove_old_workspaces_from_release_table(params, domain_name, data_product.data_product_id, segment.segment_id, master_projects, removal_master_project_ids)
                rescue Exception => e # rubocop:disable RescueException
                  GoodData.logger.error "Problem occurs when removing old master workspace, reason: #{e.message}"
                end
              end
            end

            {
              segment: segment.id,
              master_pid: master.nil? ? '' : master.pid,
              master_name: master.nil? ? '' : master.title,
              successful_count: sync_result['successfulClients']['count']
            }
          end

          # Return results
          results
        end

        def remove_multiple_workspace(params, segment_id, master_projects, number_of_deleted_projects)
          removal_master_project_ids = []
          need_to_delete_projects = master_projects.take(number_of_deleted_projects)

          need_to_delete_projects.each do |project_wrapper|
            master_project_id = project_wrapper[:master_project_id]
            next if master_project_id.to_s.empty?

            begin
              project = params.gdc_gd_client.projects(master_project_id)
              if project && !%w[deleted archived].include?(project.state.to_s)
                GoodData.logger.info "Segment #{segment_id}: Deleting old master workspace, project: '#{project.title}', PID: (#{project.pid})."
                project.delete
              end
              removal_master_project_ids << master_project_id
              master_projects.delete_if { |p| p[:master_project_id] == master_project_id }
            rescue Exception => ex # rubocop:disable RescueException
              GoodData.logger.error "Unable to remove master workspace: '#{master_project_id}', Error: #{ex.message}"
            end
          end
          removal_master_project_ids
        end

        # rubocop:disable Metrics/ParameterLists
        def remove_old_workspaces_from_release_table(params, domain_id, data_product_id, segment_id, master_projects, removal_master_project_ids)
          unless removal_master_project_ids.empty?
            if params.ads_client
              GoodData::LCM2::Helpers.delete_master_project_from_ads(params.release_table_name, params.ads_client, segment_id, removal_master_project_ids)
            else
              data = master_projects.sort_by { |master| master[:version] }
              GoodData::LCM2::Helpers.update_master_project_to_nfs(domain_id, data_product_id, segment_id, data)
            end
          end
        end
        # rubocop:enable Metrics/ParameterLists

        private

        def error_handle(segment, error_result, continue_on_error, params)
          sync_result = error_result.json['synchronizationResult']
          success_count = sync_result['successfulClients']['count'].to_i
          failed_count = sync_result['failedClients']['count'].to_i

          # Synchronize failure for all clients in segment
          if continue_on_error && success_count.zero? && failed_count.positive?
            segment_warning_message = "Failed to synchronize all clients for #{segment.segment_id} segment. Details: #{sync_result['links']['details']}"
            if sync_result['links'] && sync_result['links']['details'] # rubocop:disable Style/SafeNavigation
              begin
                client = params.gdc_gd_client
                response = client.get sync_result['links']['details']
                error_detail_result = response['synchronizationResultDetails']

                if error_detail_result && error_detail_result['items'] # rubocop:disable Style/SafeNavigation
                  error_count = 1
                  error_detail_result['items'].each do |item|
                    break if error_count > 5

                    GoodData.logger.warn(error_message(item, segment))
                    error_count += 1
                  end
                end
              rescue StandardError => ex
                GoodData.logger.warn "Failed to fetch result of synchronize clients. Error: #{ex.message}"
              end
            end

            add_failed_segment(segment.segment_id, segment_warning_message, short_name, params)
            return
          end

          summary_error_message = "#{failed_count} clients failed to synchronize. Details: #{sync_result['links']['details']}"
          fail(summary_error_message) unless continue_on_error

          GoodData.logger.warn summary_error_message
          if error_result.details # rubocop:disable Style/SafeNavigation
            error_result.details.items.each do |item|
              next if item['status'] == 'OK'

              error_client_id = item['id']
              error_message = error_message(item, segment)
              add_failed_client(error_client_id, error_message, short_name, params)
            end
          end
        end

        def error_message(error_item, segment)
          error_client_id = error_item['id']
          error_message = "Failed to synchronize #{error_client_id} client in #{segment.segment_id} segment"
          error_message = "#{error_message}. Detail: #{error_item['error']['message']}" if error_item['error'] && error_item['error']['message']

          error_message = "#{error_message}. Error items: #{error_item['error']['parameters']}" if error_item['error'] && error_item['error']['parameters']

          error_message
        end
      end
    end
  end
end
