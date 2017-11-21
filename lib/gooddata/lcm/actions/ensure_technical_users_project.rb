# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class EnsureTechnicalUsersProject < BaseAction
      DESCRIPTION = 'Ensure Technical Users in Project'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Technical users'
        param :technical_user, array_of(instance_of(Type::StringType)),
              required: false, deprecated: true, replacement: :technical_users

        description 'Technical users'
        param :technical_users, array_of(instance_of(Type::StringType)), required: false

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true
      end

      RESULT_HEADER = [
        :project,
        :pid,
        :login,
        :role,
        :result,
        :message,
        :url
      ]

      class << self
        def call(params)
          client = params.gdc_gd_client

          technical_users = params.technical_users || params.technical_user || []
          new_users = technical_users.map do |technical_user|
            {
              login: technical_user,
              role: 'admin'
            }
          end

          results = params.synchronize.pmap do |synchronize_info|
            synchronize_info[:to].pmap do |entry|
              ensure_users(client, entry[:pid], new_users)
            end
          end.flatten

          results += params.clients.pmap { |input_client| input_client[:project] }.compact.pmap { |pid| ensure_users(client, pid, new_users) }.flatten if params.clients

          results
        end

        private

        def ensure_users(client, project_id, new_users)
          project = client.projects(project_id)
          res = project.create_users(new_users)

          new_users.zip(res).map do |f, s|
            {
              project: project.title,
              pid: project.pid,
              login: f[:login],
              role: f[:role],
              result: s[:type],
              message: s[:message],
              url: s[:user]
            }
          end
        end
      end
    end
  end
end
