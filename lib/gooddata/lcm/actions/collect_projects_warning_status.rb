# frozen_string_literal: true
# (C) 2019-2022 GoodData Corporation
require_relative 'base_action'

module GoodData
  module LCM2
    class CollectProjectsWarningStatus < BaseAction
      DESCRIPTION = 'Collect synced projects status'

      PARAMS = define_params(self) do
        description 'Abort on error'
        param :abort_on_error, instance_of(Type::StringType), required: false

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: false

        description 'Collect synced status'
        param :collect_synced_status, instance_of(Type::BooleanType), required: false

        description 'Sync failed list'
        param :sync_failed_list, instance_of(Type::HashType), required: false
      end

      RESULT_HEADER = %i[segment client project_pid failed_action]

      class << self
        def call(params)
          results = []
          return results unless collect_synced_status(params)

          sync_failed_list = params[SYNC_FAILED_LIST]
          if sync_failed_list
            failed_detailed_projects = sync_failed_list[:failed_detailed_projects]
            failed_detailed_projects.each do |failed_detailed_project|
              results << {
                segment: failed_detailed_project[:segment],
                client: failed_detailed_project[:client_id],
                project_pid: failed_detailed_project[:project_id],
                failed_action: failed_detailed_project[:action]
              }
            end
          end

          results
        end

        def print_result(params)
          collect_synced_status(params)
        end
      end
    end
  end
end
