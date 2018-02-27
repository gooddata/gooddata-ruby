# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'
require_relative 'purge_clients'

module GoodData
  module LCM2
    class ProvisionClients < BaseAction
      DESCRIPTION = 'Provisions LCM Clients'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'Domain'
        param :domain, instance_of(Type::StringType), required: false

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true

        description 'DataProduct to manage'
        param :data_product, instance_of(Type::GdProductType), required: false

        description 'DataLogger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true
      end

      RESULT_HEADER = [
        :id,
        :status,
        :project_uri,
        :error,
        :type
      ]

      class << self
        def call(params)
          synchronize_projects = []
          data_product = params.data_product
          client = params.gdc_gd_client
          domain_name = params.organization || params.domain
          fail "Either organisation or domain has to be specified in params" unless domain_name
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")

          begin
            results = params.segments.map do |segment|
              segment_object = domain.segments(segment.segment_id, data_product)
              tmp = segment_object.provision_client_projects.map do |m|
                Hash[m.each_pair.to_a].merge(type: :provision_result)
              end

              unless tmp.empty?
                synchronize_projects << {
                  segment_id: segment.segment_id,
                  from: segment.development_pid,
                  to: tmp.map do |entry|
                    unless entry[:project_uri]
                      raise "Provisioning project for client id #{entry[:id]} has error: #{entry[:error]}"
                    end
                    {
                      pid: entry[:project_uri].split('/').last,
                      client_id: entry[:id]
                    }
                  end
                }
              end

              tmp
            end
          rescue => e
            params.gdc_logger.error "Problem occurs when provisioning clients. Purge all invalid clients now ..."
            res = PurgeClients.send(:call, params)
            params.gdc_logger.debug "Purge clients result: #{res}"
            deleted_client_ids = res[:results].select { |r| r[:status] == 'purged' }.map { |r| r[:client_id] }
            params.gdc_logger.error "Deleted clients: #{deleted_client_ids.join(', ')}"
            raise e
          end

          results.flatten!

          # Return results
          {
            results: results,
            params: {
              synchronize: synchronize_projects
            }
          }
        end
      end
    end
  end
end
