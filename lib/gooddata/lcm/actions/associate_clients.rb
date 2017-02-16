# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class AssociateClients < BaseAction
      DESCRIPTION = 'Associate LCM Clients'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true
      end

      RESULT_HEADER = [
        :id,
        :status,
        :originalProject,
        :client,
        :type
      ]

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          client = params.gdc_gd_client

          delete_projects = params.delete_projects == 'false' || params.delete_projects == false ? false : true
          delete_extra = params.delete_extra == 'false' || params.delete_extra == false ? false : true

          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")

          domain.update_clients(params.clients, delete_extra: delete_extra, delete_projects: delete_projects)
        end
      end
    end
  end
end
