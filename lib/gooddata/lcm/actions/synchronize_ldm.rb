# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

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
      end

      class << self
        def call(params)
          results = []
          synchronize = []
          params.synchronize.map do |segment_info|
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
          results = []
          client = params.gdc_gd_client
          exclude_fact_rule = params.exclude_fact_rule.to_b
          from_pid = segment_info[:from]
          from = params.development_client.projects(from_pid) || fail("Invalid 'from' project specified - '#{from_pid}'")

          GoodData.logger.info "Creating Blueprint, project: '#{from.title}', PID: #{from_pid}"
          blueprint = from.blueprint(include_ca: params.include_computed_attributes.to_b)
          maql_diff = nil
          previous_master = segment_info[:previous_master]
          diff_against_master = %w(diff_against_master_with_fallback diff_against_master)
            .include?(params[:synchronize_ldm].downcase)
          if previous_master && diff_against_master
            maql_diff_params = [:includeGrain]
            maql_diff_params << :excludeFactRule if exclude_fact_rule
            maql_diff = previous_master.maql_diff(blueprint: blueprint, params: maql_diff_params)
          end

          segment_info[:to] = segment_info[:to].pmap do |entry|
            pid = entry[:pid]
            to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")

            GoodData.logger.info "Updating from Blueprint, project: '#{to_project.title}', PID: #{pid}"
            begin
              entry[:ca_scripts] = to_project.update_from_blueprint(
                blueprint,
                update_preference: params[:update_preference],
                exclude_fact_rule: exclude_fact_rule,
                execute_ca_scripts: false,
                maql_diff: maql_diff
              )
            rescue MaqlExecutionError => e
              GoodData.logger.info("Applying MAQL to project #{to_project.title} - #{pid} failed. Reason: #{e}")
              fail e unless diff_against && params[:synchronize_ldm] == 'diff_against_master_with_fallback'
              GoodData.logger.info("Restoring the client project #{to_project.title} from master.")
              entry[:ca_scripts] = to_project.update_from_blueprint(
                blueprint,
                update_preference: params[:update_preference],
                exclude_fact_rule: exclude_fact_rule,
                execute_ca_scripts: false
              )
            end

            results << {
              from: from_pid,
              to: pid,
              status: 'ok'
            }
            entry
          end

          [segment_info, results]
        end
      end
    end
  end
end
