# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeDataSetMapping < BaseAction
      DESCRIPTION = 'Synchronize Dataset Mappings'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Client used to connecting to development domain'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true

        description 'Abort on error'
        param :abort_on_error, instance_of(Type::StringType), required: false

        description 'Collect synced status'
        param :collect_synced_status, instance_of(Type::BooleanType), required: false

        description 'Sync failed list'
        param :sync_failed_list, instance_of(Type::HashType), required: false

        description 'Number Of Threads'
        param :number_of_threads, instance_of(Type::StringType), required: false, default: '10'
      end

      RESULT_HEADER = %i[from to count status]

      class << self
        def call(params)
          results = []
          collect_synced_status = collect_synced_status(params)
          failed_projects = ThreadSafe::Array.new

          client = params.gdc_gd_client
          development_client = params.development_client
          number_of_threads = Integer(params.number_of_threads || '8')

          params.synchronize.peach(number_of_threads) do |info|
            from_project = info.from
            to_projects = info.to

            from = development_client.projects(from_project)
            unless from
              process_failed_project(from_project, "Invalid 'from' project specified - '#{from_project}'", failed_projects, collect_synced_status)
              next
            end

            dataset_mapping = from.dataset_mapping
            if dataset_mapping&.dig('datasetMappings', 'items').nil? || dataset_mapping['datasetMappings']['items'].empty?
              params.gdc_logger.info "Project: '#{from.title}', PID: '#{from.pid}' has no model mapping, skip synchronizing model mapping."
            else
              to_projects.peach(number_of_threads) do |to|
                pid = to[:pid]
                next if sync_failed_project(pid, params)

                to_project = client.projects(pid)
                process_failed_project(pid, "Invalid 'to' project specified - '#{pid}'", failed_projects, collect_synced_status) unless to_project

                message_to_project = "to project: '#{to_project.title}', PID: '#{to_project.pid}'"
                params.gdc_logger.info "Transferring model mapping, from project: '#{from.title}', PID: '#{from.pid}', #{message_to_project}"
                res = to_project.update_dataset_mapping(dataset_mapping)
                res[:from] = from.pid
                results << res

                failed_message = "Failed to transfer model mapping from project '#{from.pid}' to project '#{to_project.pid}'"
                process_failed_project(pid, failed_message, failed_projects, collect_synced_status) if collect_synced_status && res[:status] != 'OK'
              end
            end
          end

          process_failed_projects(failed_projects, short_name, params) if collect_synced_status
          # Return results
          results.flatten
        end
      end
    end
  end
end
