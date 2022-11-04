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
    class SynchronizeLdm < BaseAction
      DESCRIPTION = 'Synchronize Logical Data Model'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Client used to connecting to development domain'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'LDM Update Preference'
        param :update_preference, instance_of(Type::UpdatePreferenceType), required: false

        description 'Specifies whether to transfer computed attributes'
        param :include_computed_attributes, instance_of(Type::BooleanType), required: false, default: true

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true

        description 'Additional Hidden Parameters'
        param :additional_hidden_params, instance_of(Type::HashType), required: false

        description 'Allows to have facts with higher precision decimals'
        param :exclude_fact_rule, instance_of(Type::BooleanType), required: false, default: false

        description 'Specifies how to synchronize LDM and resolve possible conflicts'
        param :synchronize_ldm, instance_of(Type::SynchronizeLDM), required: false, default: 'diff_against_master_with_fallback'

        description 'Enables handling of deprecated objects in the logical data model.'
        param :include_deprecated, instance_of(Type::BooleanType), required: false, default: false

        description 'Abort on error'
        param :abort_on_error, instance_of(Type::StringType), required: false

        description 'Collect synced status'
        param :collect_synced_status, instance_of(Type::BooleanType), required: false

        description 'Sync failed list'
        param :sync_failed_list, instance_of(Type::HashType), required: false
      end

      RESULT_HEADER = %i[from to status]

      class << self
        def call(params)
          results = []
          synchronize = []
          params.synchronize.map do |segment_info|
            next if sync_failed_segment(segment_info[:segment_id], params)

            new_segment_info, segment_results = sync_segment_ldm(params, segment_info)
            results.concat(segment_results)
            synchronize << new_segment_info
          end

          {
            results: results,
            params: {
              synchronize: synchronize
            }
          }
        end

        private

        def sync_segment_ldm(params, segment_info)
          collect_synced_status = collect_synced_status(params)
          failed_projects = ThreadSafe::Array.new
          results = ThreadSafe::Array.new
          client = params.gdc_gd_client
          exclude_fact_rule = params.exclude_fact_rule.to_b
          include_deprecated = params.include_deprecated.to_b
          from_pid = segment_info[:from]
          from = params.development_client.projects(from_pid)
          unless from
            segment_id = segment_info[:segment_id]
            error_message = "Failed to sync LDM for segment #{segment_id}. Error: Invalid 'from' project specified - '#{from_pid}'"
            fail(error_message) unless collect_synced_status

            add_failed_segment(segment_id, error_message, short_name, params)
            return [segment_info, results]
          end

          GoodData.logger.info "Creating Blueprint, project: '#{from.title}', PID: #{from_pid}"
          blueprint = from.blueprint(include_ca: params.include_computed_attributes.to_b)
          segment_info[:from_blueprint] = blueprint
          maql_diff = nil
          previous_master = segment_info[:previous_master]
          synchronize_ldm_mode = params[:synchronize_ldm].downcase
          diff_against_master = %w(diff_against_master_with_fallback diff_against_master)
            .include?(synchronize_ldm_mode)
          GoodData.logger.info "Synchronize LDM mode: '#{synchronize_ldm_mode}'"
          if segment_info.key?(:previous_master) && diff_against_master
            if previous_master
              maql_diff_params = [:includeGrain]
              maql_diff_params << :excludeFactRule if exclude_fact_rule
              maql_diff_params << :includeDeprecated if include_deprecated
              maql_diff = previous_master.maql_diff(blueprint: blueprint, params: maql_diff_params)
            else
              maql_diff = {
                "projectModelDiff" =>
                   {
                     "updateOperations" => [],
                     "updateScripts" => []
                   }
              }
            end

            chunks = maql_diff['projectModelDiff']['updateScripts']
            if chunks.empty?
              GoodData.logger.info "Synchronize LDM to clients will not proceed in mode \
'#{synchronize_ldm_mode}' due to no LDM changes in the segment master project. \
If you had changed LDM of clients manually, please use mode 'diff_against_clients' \
to force synchronize LDM to clients"
            end
          end

          segment_info[:to] = segment_info[:to].pmap do |entry|
            update_status = true
            pid = entry[:pid]
            next if sync_failed_project(pid, params)

            to_project = client.projects(pid)
            unless to_project
              process_failed_project(pid, "Invalid 'to' project specified - '#{pid}'", failed_projects, collect_synced_status)
              next
            end

            GoodData.logger.info "Updating from Blueprint, project: '#{to_project.title}', PID: #{pid}"
            begin
              entry[:ca_scripts] = to_project.update_from_blueprint(
                blueprint,
                update_preference: params[:update_preference],
                exclude_fact_rule: exclude_fact_rule,
                execute_ca_scripts: false,
                maql_diff: maql_diff,
                include_deprecated: include_deprecated
              )
            rescue MaqlExecutionError => e
              if collect_synced_status
                update_status = false
                failed_message = "Applying MAQL to project #{to_project.title} - #{pid} failed. Reason: #{e}"
                process_failed_project(pid, failed_message, failed_projects, collect_synced_status)
              else
                fail e unless previous_master && params[:synchronize_ldm] == 'diff_against_master_with_fallback'

                GoodData.logger.info("Restoring the client project #{to_project.title} from master.")
                entry[:ca_scripts] = to_project.update_from_blueprint(
                  blueprint,
                  update_preference: params[:update_preference],
                  exclude_fact_rule: exclude_fact_rule,
                  execute_ca_scripts: false,
                  include_deprecated: include_deprecated
                )
              end
            end

            results << {
              from: from_pid,
              to: pid,
              status: 'ok'
            } if update_status

            entry
          end

          process_failed_projects(failed_projects, short_name, params) if collect_synced_status
          [segment_info, results]
        end
      end
    end
  end
end
