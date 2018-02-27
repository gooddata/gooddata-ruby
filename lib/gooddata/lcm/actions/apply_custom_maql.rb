# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    # Applies custom MAQL DDL to all client projects so customized
    # labels and fiscal calendars are not deleted.
    # To ease up further automation, the MAQL DDL may be
    # stored in separate field in lcm_release
    # table as we will need custom Release brick action which will populate it.
    class ApplyCustomMaql < BaseAction
      DESCRIPTION = 'Apply Custom MAQL DDL'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true

        description 'Should be custom MAQL DDL Applied'
        param :apply_maql_ddl, instance_of(Type::BooleanType), required: false, default: false

        description 'Domain'
        param :domain, instance_of(Type::StringType), required: false

        description 'DataProduct to manage'
        param :data_product, instance_of(Type::GDDataProductType), required: false
      end

      RESULT_HEADER = [
        :segment,
        :maql,
        :status
      ]

      class << self
        def call(params)
          return [] unless params.apply_maql_ddl.to_b

          client = params.gdc_gd_client

          domain_name = params.organization || params.domain
          fail "Either organisation or domain has to be specified in params" unless domain_name
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")
          data_product = params.data_product

          segment_ids = params.segments.map(&:segment_id)
          domain_segments = domain.segments(:all, data_product).select do |ds|
            segment_ids.include?(ds.segment_id)
          end

          res = []
          domain_segments.peach do |ds|
            maql = 'CREATE DATASET {dataset.quotes} VISUAL (TITLE "Stock Quotes Data");'

            unless maql.empty?
              ds.clients.peach do |dc|
                project = dc.project

                r = project.execute_maql(maql)

                item = {
                  segment: ds.segment_id,
                  maql: maql,
                  status: r
                }

                res.push(item)
              end
            end
          end

          res
        end
      end
    end
  end
end
