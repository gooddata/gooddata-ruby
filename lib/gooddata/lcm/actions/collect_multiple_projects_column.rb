# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.
require_relative 'base_action'

module GoodData
  module LCM2
    class CollectMultipleProjectsColumn < BaseAction
      DESCRIPTION = 'Collect multiple_projects_column to be used in user actions'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Identifier of column that identifies the relation to the projects in an user action input'
        param :multiple_projects_column, instance_of(Type::StringType), required: false

        description 'Synchronization Mode for user action (e.g. sync_one_project_based_on_pid)'
        param :sync_mode, instance_of(Type::StringType), required: false

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true
      end

      CLIENT_ID_MODES = %w(
        sync_domain_client_workspaces
        sync_one_project_based_on_custom_id
        sync_multiple_projects_based_on_custom_id
      )

      class << self
        def call(params)
          column = params.multiple_projects_column
          column = CLIENT_ID_MODES.include?(params.sync_mode) ? 'client_id' : 'project_id' unless column

          {
            results: [{ multiple_projects_column: column }],
            params: { multiple_projects_column: column }
          }
        end
      end
    end
  end
end
