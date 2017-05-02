# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
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
          client = params.gdc_gd_client

          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")

          params.clients.group_by { |data| data[:segment] }.each do |segment_name, clients|
            segment = domain.segments(segment_name)
            existing_clients = segment.clients.map(&:id)
            clients.each do |c|
              segment.create_client(id: c.id) unless existing_clients.include?(c.id)
            end
          end

          domain.update_clients_settings(params.clients)

          delete_projects = GoodData::Helpers.to_boolean(params.delete_projects)
          delete_extra = GoodData::Helpers.to_boolean(params.delete_extra)
          options = { delete_projects: delete_projects }
          options.merge!(delete_extra_option(params)) if delete_extra

          domain.update_clients(params.clients, options)
        end

        private

        def delete_extra_option(params)
          if params.segments_filter && params.segments_filter.any?
            { delete_extra_in_segments: params.segments_filter }
          else
            { delete_extra: delete_extra }
          end
        end
      end
    end
  end
end
