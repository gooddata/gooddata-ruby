# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.
require 'gooddata/extensions/class'
require 'gooddata/extensions/true'
require 'gooddata/extensions/false'
require 'gooddata/extensions/integer'
require 'gooddata/extensions/string'
require 'gooddata/extensions/nil'

require_relative '../dsl/dsl'
require_relative '../helpers/helpers'
require_relative '../types/types'

module GoodData
  module LCM2
    class BaseAction
      class << self
        include Dsl::Dsl

        SYNC_FAILED_LIST = 'sync_failed_list'.to_sym
        FAILED_PROJECTS = 'failed_projects'.to_sym
        FAILED_CLIENTS = 'failed_clients'.to_sym
        FAILED_SEGMENTS = 'failed_segments'.to_sym

        def check_params(specification, params)
          Helpers.check_params(specification, params)
        end

        # This method is used to enable the possibility to read keys of params object
        # which are not specified in the specification constant
        # typically in case when method access params dynamically based on user input
        def without_check(specification, params)
          params.clear_filters # disables params validation
          result = yield
          params.setup_filters(specification) # enables params validation
          result
        end

        def print_result(_params)
          true
        end

        def continue_on_error(params)
          Helpers.continue_on_error(params)
        end

        def collect_synced_status(params)
          Helpers.collect_synced_status(params)
        end

        def add_failed_project(project_id, message, failed_action, params)
          if collect_synced_status(params) && !sync_failed_project(project_id, params)
            sync_failed_list = sync_failed_list(params)
            project_client_mappings = sync_failed_list[:project_client_mappings]
            project_client_mapping = project_client_mappings ? project_client_mappings[project_id.to_sym] : nil
            client_id = project_client_mapping ? project_client_mapping[:client_id] : nil
            segment_id = project_client_mapping ? project_client_mapping[:segment_id] : nil

            failed_detailed_project = {
              project_id: project_id,
              client_id: client_id,
              segment: segment_id,
              message: message,
              action: failed_action
            }
            add_failed_detail(params, failed_detailed_project, sync_failed_list)
          end
        end

        def add_failed_client(client_id, message, error_action, params)
          if collect_synced_status(params) && !sync_failed_client(client_id, params)
            sync_failed_list = sync_failed_list(params)
            client_project_mappings = sync_failed_list[:client_project_mappings]
            client_project_mapping = client_project_mappings ? client_project_mappings[client_id.to_sym] : nil
            project_id = client_project_mapping ? client_project_mapping[:project_id] : nil
            segment_id = client_project_mapping ? client_project_mapping[:segment_id] : nil

            failed_detailed_client = {
              project_id: project_id,
              client_id: client_id,
              segment: segment_id,
              message: message,
              action: error_action
            }
            add_failed_detail(params, failed_detailed_client, sync_failed_list)
          end
        end

        def add_failed_segment(segment_id, message, error_action, params)
          if collect_synced_status(params) && !sync_failed_segment(segment_id, params)
            sync_failed_list = sync_failed_list(params)
            failed_detailed_segment = {
              project_id: nil,
              client_id: nil,
              segment: segment_id,
              message: message,
              action: error_action
            }
            add_failed_detail(params, failed_detailed_segment, sync_failed_list, true)
          end
        end

        def process_failed_project(project_id, failed_message, failed_projects, continue_on_error)
          fail(failed_message) unless continue_on_error

          failed_projects << {
            project_id: project_id,
            message: failed_message
          }
        end

        def process_failed_projects(failed_projects, failed_action, params)
          failed_projects.each do |failed_project|
            add_failed_project(failed_project[:project_id], failed_project[:message], failed_action, params)
          end
        end

        def sync_failed_project(project_id, params)
          collect_synced_status(params) && params[SYNC_FAILED_LIST][FAILED_PROJECTS].include?(project_id)
        end

        def sync_failed_client(client_id, params)
          collect_synced_status(params) && params[SYNC_FAILED_LIST][FAILED_CLIENTS].include?(client_id)
        end

        def sync_failed_segment(segment_id, params)
          collect_synced_status(params) && params[SYNC_FAILED_LIST][FAILED_SEGMENTS].include?(segment_id)
        end

        private

        def add_failed_detail(params, failed_detailed_project, sync_failed_list, ignore_segment = false)
          params.gdc_logger&.warn failed_detailed_project[:message]
          sync_failed_list[:failed_detailed_projects] << failed_detailed_project

          if ignore_segment
            add_failed_detail_segment(failed_detailed_project[:segment_id], sync_failed_list)
          else
            add_failed_detail_client(failed_detailed_project[:client_id], failed_detailed_project[:project_id], sync_failed_list)
          end
        end

        def sync_failed_list(params)
          if params.include?(SYNC_FAILED_LIST)
            params[SYNC_FAILED_LIST]
          else
            nil
          end
        end

        def add_failed_detail_client(client_id, project_id, sync_failed_list)
          sync_failed_list[FAILED_CLIENTS] << client_id if client_id

          sync_failed_list[FAILED_PROJECTS] << project_id if project_id
        end

        def add_failed_detail_segment(segment_id, sync_failed_list)
          if segment_id
            sync_failed_list[FAILED_SEGMENTS] << segment_id

            client_project_mappings = sync_failed_list[:client_project_mappings]
            client_project_mappings.each do |client_id, client_project_mapping|
              add_failed_detail_client(client_id, client_project_mapping[:project_id], sync_failed_list) if client_project_mapping[:segment_id] == segment_id
            end
          end
        end
      end
    end
  end
end
