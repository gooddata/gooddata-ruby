# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class UpdateReleaseTable < BaseAction
      DESCRIPTION = 'Update Release Table'

      PARAMS = define_params(self) do
        description 'ADS Client'
        param :ads_client, instance_of(Type::AdsClientType), required: true
      end

      DEFAULT_QUERY_INSERT = 'INSERT INTO lcm_release (segment_id, master_project_id, version) VALUES (\'#{segment_id}\', \'#{master_project_id}\', #{version});'
      DEFAULT_QUERY_UPDATE = 'UPDATE lcm_release SET master_project_id=\'#{master_project_id}\', version=#{version} WHERE segment_id=\'#{segment_id}\';'

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          client = params.gdc_gd_client

          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")

          params.segments.map do |segment_in|
            segment_id = segment_in.segment_id

            placeholders = {
              '#{segment_id}' => segment_in[:segment_id],
              '#{master_project_id}' => segment_in[:master_pid],
              '#{version}' => segment_in[:version],
              '#{timestamp}' => segment_in[:timestamp],
            }

            self.update_release_table(params, placeholders)

            {
              segment: segment_id,
              master_pid: segment_in[:master_pid],
              version: segment_in[:version],
              timestamp: segment_in[:timestamp]
            }
          end
        end

        def update_release_table(params, placeholders)
          query = if placeholders['#{version}'] > 1
                    (params.query && params.query.update) || DEFAULT_QUERY_UPDATE
                  else
                    (params.query && params.query.insert) || DEFAULT_QUERY_INSERT
                  end

          placeholders.each do |k, v|
            query = query.gsub(k, v.to_s)
          end

          params.ads_client.execute(query)
        end
      end
    end
  end
end
