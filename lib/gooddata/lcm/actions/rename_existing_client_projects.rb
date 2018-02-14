# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class RenameExistingClientProjects < BaseAction
      DESCRIPTION = 'Rename Existing Client Projects'

      PARAMS = define_params(self) do
        description 'Clients'
        param :clients, array_of(instance_of(Type::HashType)), required: true, generated: true

        description 'Client projects'
        param :client_projects, instance_of(Type::GdSmartHashType), required: false
      end

      RESULT_HEADER = [
        :id,
        :pid,
        :old_title,
        :new_title
      ]

      class << self
        def call(params)
          client_projects = params.client_projects

          results = []
          params.clients.each do |c|
            info = client_projects[c[:id]]
            next unless info

            segment_client = info[:segment_client]
            project = info[:project]

            # If he is an existing client but has no project, he will be purged and then re-created again
            # so his project absolutely does not need to be updated title
            next unless project

            # If his project is existing, we do not know this is a correct project or not because user
            # can associate this client with another project and we need to check and update its title.
            # If this is a new project, we do not need to verify its status because we already did it in
            # CollectClients action
            project = segment_client.project

            new_title = c[:settings].find { |setting| setting[:name] == 'lcm.title' }[:value]
            next unless new_title

            old_title = project.title
            next if new_title == old_title

            project.title = new_title
            project.save

            results << {
              id: c[:id],
              pid: project.pid,
              old_title: old_title,
              new_title: new_title
            }
          end

          results
        end
      end
    end
  end
end
