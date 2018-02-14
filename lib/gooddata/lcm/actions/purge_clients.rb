# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class PurgeClients < BaseAction
      DESCRIPTION = 'Purge LCM Clients'

      PARAMS = define_params(self) do
        description 'Client projects'
        param :client_projects, instance_of(Type::GdSmartHashType), required: false
      end

      RESULT_HEADER = [
        :client_id,
        :project,
        :status
      ]

      class << self
        def call(params)
          client_projects = params.client_projects

          results = client_projects.pmap do |_, info|
            client = info[:segment_client]
            project = info[:project]

            res = {
              client_id: client.client_id,
              project: project && project.pid
            }

            if project.nil? || project.deleted?
              client.delete
              res[:status] = 'purged'
            else
              res[:status] = 'ok - not purged'
            end

            res
          end

          results.pselect { |res| res[:status] == 'purged' }.pmap { |res| res[:client_id] }.each { |id| client_projects.delete(id) }

          {
            results: results,
            params: {
              client_projects: client_projects
            }
          }
        end
      end
    end
  end
end
