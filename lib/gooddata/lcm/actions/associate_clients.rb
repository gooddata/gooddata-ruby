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

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'Domain'
        param :domain, instance_of(Type::StringType), required: false

        description 'Delete Extra Clients'
        param :delete_extra, instance_of(Type::BooleanType), required: false, default: false

        description 'Physically Delete Client Projects'
        param :delete_projects, instance_of(Type::BooleanType), required: false, default: false

        description 'Clients'
        param :clients, array_of(instance_of(Type::HashType)), required: true, generated: true

        description 'Segments to provision'
        param :segments_filter, array_of(instance_of(Type::StringType)), required: false

        description 'DataProduct'
        param :data_product, instance_of(Type::GdProductType), required: false
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
          fail "Either organisation or domain has to be specified in params" unless domain_name
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")
          data_product = params.data_product

          segments = {}

          params.clients.group_by { |data| data[:segment] }.each do |segment_name, clients|
            segment = domain.segments(segment_name, data_product)
            segments[segment_name] = segment
            (clients.map(&:id) - segment.clients.map(&:id)).each do |c|
              segment.create_client(id: c)
            end
          end

          params.clients.map! do |data|
            data[:data_product_id] = segments[data[:segment]].data_product.data_product_id
            data
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
            { delete_extra: GoodData::Helpers.to_boolean(params.delete_extra) }
          end
        end
      end
    end
  end
end
