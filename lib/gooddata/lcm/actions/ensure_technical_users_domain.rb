# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class EnsureTechnicalUsersDomain < BaseAction
      DESCRIPTION = 'Ensure Technical Users in Domain'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: true

        description 'Technical users'
        param :technical_user, array_of(instance_of(Type::StringType)), required: false
      end

      RESULT_HEADER = [
        :login,
        :email,
        :domain,
        :status
      ]

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          client = params.gdc_gd_client

          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")

          technical_users = params.technical_user || []
          technical_users.map do |technical_user|
            domain_user = domain.users.find do |du|
              du.login == technical_user
            end

            if domain_user
              {
                login: domain_user.login,
                email: domain_user.email,
                domain: domain_name,
                status: 'exists'
              }
            else
              user = domain.add_user(login: technical_user, email: technical_user)
              {
                login: user.login,
                email: user.email,
                domain: domain_name,
                status: 'added'
              }
            end
          end
        end
      end
    end
  end
end
