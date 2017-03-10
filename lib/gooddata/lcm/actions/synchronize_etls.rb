# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeETLs < BaseAction
      DESCRIPTION = 'Synchronize ETLs (CC/Ruby)'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true
      end

      # will be updated later based on the way etl synchronization
      RESULT_HEADER = [
      ]

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          results = []

          client = params.gdc_gd_client
          development_client = params.development_client

          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")

          # we will use client_id to detect the context of etl synchronization. If we don't have client_id, it means we are in Release brick
          has_client_ids = params
                            .synchronize
                            .group_by do |info|
                              info[:to].first[:client_id]
                            end
                            .keys
                            .compact
          if !has_client_ids.empty?
            RESULT_HEADER.push(:segment, :master_project, :client_id, :client_project, :status)

            synchronize_segments = params.synchronize.group_by do |info|
              info[:segment_id]
            end
            synchronize_segments.map do |segment_id, synchronize|
              segment = domain.segments(segment_id)
              res = segment.synchronize_processes(
                synchronize.map do |info|
                  info[:to].map do |to|
                    to[:pid]
                  end
                end.flatten
              )

              res = GoodData::Helpers.symbolize_keys(res)
              results += res[:syncedResult][:clients].map do |item|
                item = item[:client]
                {
                  segment: segment_id,
                  master_project: segment.master_project_id,
                  client_id: item[:id],
                  client_project: item[:project].split('/').last,
                  status: 'ok'
                }
              end
            end
          else
            RESULT_HEADER.push(:from, :to, :process_name, :schedule_name, :type, :state)

            params.synchronize.each do |info|
              from_project = info.from
              to_projects = info.to

              from = development_client.projects(from_project) || fail("Invalid 'from' project specified - '#{from_project}'")

              to_projects.each do |to|
                pid = to[:pid]
                client_id = to[:client_id]

                to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")

                params.gdc_logger.info "Transferring processes, from project: '#{from.title}', PID: '#{from.pid}', to project: '#{to_project.title}', PID: '#{to_project.pid}'"
                GoodData::Project.transfer_processes(from, to_project)

                to_project.add.output_stage.client_id = client_id if client_id && to_project.add.output_stage

                params.gdc_logger.info "Transferring Schedules, from project: '#{from.title}', PID: '#{from.pid}', to project: '#{to_project.title}', PID: '#{to_project.pid}'"
                res = GoodData::Project.transfer_schedules(from, to_project).sort_by do |item|
                  item[:status]
                end

                results += res.map do |item|
                  schedule = item[:schedule]

                  # TODO: Review this and remove if not required or duplicate (GOODOT_CUSTOM_PROJECT_ID vs CLIENT_ID)
                  # s.update_params('GOODOT_CUSTOM_PROJECT_ID' => c.id)
                  # s.update_params('CLIENT_ID' => c.id)
                  # s.update_params('SEGMENT_ID' => segment.id)
                  schedule.update_params(params.additional_params || {})
                  schedule.update_hidden_params(params.additional_hidden_params || {})
                  schedule.save

                  {
                    from: from.pid,
                    to: to_project.pid,
                    process_name: item[:process].name,
                    schedule_name: schedule.name,
                    type: item[:process].type,
                    state: item[:state]
                  }
                end
              end
            end
          end

          # Return results
          results
        end
      end
    end
  end
end
