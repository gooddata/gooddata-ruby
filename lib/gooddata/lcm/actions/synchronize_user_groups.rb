# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'
require 'thread_safe'

module GoodData
  module LCM2
    class SynchronizeUserGroups < BaseAction
      DESCRIPTION = 'Synchronize User Groups'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Client used to connecting to development domain'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true

        description 'Additional Hidden Parameters'
        param :additional_hidden_params, instance_of(Type::HashType), required: false

        description 'Abort on error'
        param :abort_on_error, instance_of(Type::StringType), required: false

        description 'Collect synced status'
        param :collect_synced_status, instance_of(Type::BooleanType), required: false

        description 'Sync failed list'
        param :sync_failed_list, instance_of(Type::HashType), required: false
      end

      class << self
        def call(params)
          results = ThreadSafe::Array.new
          collect_synced_status = collect_synced_status(params)
          failed_projects = ThreadSafe::Array.new

          client = params.gdc_gd_client
          development_client = params.development_client

          params.synchronize.peach do |info|
            from_project = info.from
            to_projects = info.to

            from = development_client.projects(from_project)
            unless from
              process_failed_project(from_project, "Invalid 'from' project specified - '#{from_project}'", failed_projects, collect_synced_status)
              next
            end

            to_projects.peach do |entry|
              pid = entry[:pid]
              next if sync_failed_project(pid, params)

              to_project = client.projects(pid)
              unless to_project
                process_failed_project(pid, "Invalid 'to' project specified - '#{pid}'", failed_projects, collect_synced_status)
                next
              end

              begin
                params.gdc_logger.info "Transferring User Groups, from project: '#{from.title}', PID: '#{from.pid}', to project: '#{to_project.title}', PID: '#{to_project.pid}'"
                results += GoodData::Project.transfer_user_groups(from, to_project)
              rescue StandardError => err
                process_failed_project(pid, err.message, failed_projects, collect_synced_status)
              end
            end
          end

          process_failed_projects(failed_projects, short_name, params) if collect_synced_status
          results.uniq
        end
      end
    end
  end
end
