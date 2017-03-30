# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class CollectSegmentClients < BaseAction
      DESCRIPTION = 'Collect Clients'

      PARAMS = define_params(self) do
      end

      RESULT_HEADER = [
        :from_name,
        :from_pid,
        :to_name,
        :to_pid
      ]

      DEFAULT_TABLE_NAME = 'LCM_RELEASE'

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          results = []
          synchronize_clients = params.segments.map do |segment|
            {
              from: segment.master_project.pid,
              to: segment.clients.map do |segment_client|
                results << {
                  from_name: segment.master_project.title,
                  from_pid: segment.master_project.pid,
                  to_name: segment_client.project.title,
                  to_pid: segment_client.project.pid
                }

                {
                  pid: segment_client.project.pid,
                  client_id: segment_client.client_id
                }
              end
            }
          end

          results.flatten!

          # Return results
          {
            results: results,
            params: {
              synchronize: synchronize_clients
            }
          }
        end
      end
    end
  end
end
