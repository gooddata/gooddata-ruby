# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
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
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          client = params.gdc_gd_client

          technical_users = params.technical_user || []
          new_users = technical_users.map do |technical_user|
            {
              login: technical_user,
              role: 'admin'
            }
          end

          results = params.synchronize.map do |synchronize_info|
            synchronize_info[:to].map do |entry|
              project = client.projects(entry[:pid])
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

          results.flatten
        end
      end
    end
  end
end
