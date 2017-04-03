# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class ApplyCustomMaql < BaseAction
      DESCRIPTION = 'Apply Custom MAQL DDL'

      PARAMS = define_params(self) do
        description 'Should be custom MAQL DDL Applied'
        param :aplly_maql_ddl, instance_of(Type::BooleanType), required: false, default: false
      end

      RESULT_HEADER = [
        :segment,
        :maql,
        :status
      ]

      class << self
        def say(msg)
          puts "#{name}#say - #{msg}"
        end

        def call(params)
          unless params.apply_maql_ddl.to_b
            return []
          end

          client = params.gdc_gd_client

          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")

          segment_ids = params.segments.map(&:segment_id)
          domain_segments = domain.segments.select do |ds|
            segment_ids.include?(ds.segment_id)
          end

          res = []
          domain_segments.peach do |ds|
            maql = 'CREATE DATASET {dataset.quotes} VISUAL (TITLE "Stock Quotes Data");'

            unless maql.empty?
              ds.clients.peach do |dc|
                project = dc.project

                # TODO: Apply MAQL here!
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
