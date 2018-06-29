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
        param :delete_extra, instance_of(Type::BooleanType), required: false, default: false, deprecated: true, replacement: :delete_mode

        description 'Physically Delete Client Projects'
        param :delete_projects, instance_of(Type::BooleanType), required: false, default: false, deprecated: true, replacement: :delete_mode

        description 'Physically Delete Client Projects'
        param :delete_mode, instance_of(Type::StringType), required: false, default: 'none'

        description 'Clients'
        param :clients, array_of(instance_of(Type::HashType)), required: true, generated: true

        description 'Segments to provision'
        param :segments_filter, array_of(instance_of(Type::StringType)), required: false

        description 'DataProduct'
        param :data_product, instance_of(Type::GDDataProductType), required: false
      end

      RESULT_HEADER = [
        :id,
        :status,
        :originalProject,
        :client,
        :type
      ]

      class << self
        DELETE_MODES = %w(
          none
          delete_projects
          delete_extra
        )
        def call(params)
          unless DELETE_MODES.include?(params.delete_mode) || params.delete_mode.nil?
            fail "The parameter \"delete_mode\" has to have one of the values #{DELETE_MODES.map(&:to_s).join(', ')} or has to be empty."
          end

          case params.delete_mode
          when 'delete_projects'
            delete_projects = true
            delete_extra = true
          when 'delete_extra'
            delete_projects = false
            delete_extra = true
          else
            # Usage of the depracated params
            delete_projects = GoodData::Helpers.to_boolean(params.delete_projects)
            delete_extra = GoodData::Helpers.to_boolean(params.delete_extra)
          end

          if delete_projects && !delete_extra
            GoodData.logger.warn("Parameter `delete_projects` is set to true and parameter `delete_extra` is set to false (which is default) this action will not delete anything!")
          end

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
          options = { delete_projects: delete_projects }
          options.merge!(delete_extra_option(params, delete_extra)) if delete_extra

          domain.update_clients(params.clients, options)
        end

        private

        def delete_extra_option(params, delete_extra)
          if params.segments_filter && params.segments_filter.any?
            { delete_extra_in_segments: params.segments_filter }
          else
            { delete_extra: GoodData::Helpers.to_boolean(delete_extra) }
          end
        end
      end
    end
  end
end
