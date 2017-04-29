# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class EnsureReleaseTable < BaseAction
      DESCRIPTION = 'Ensures presence of LCM_RELEASE table'

      PARAMS = define_params(self) do
        description 'ADS Client'
        param :ads_client, instance_of(Type::AdsClientType), required: true

        description 'Table Name'
        param :release_table_name, instance_of(Type::StringType), required: false
      end

      RESULT_HEADER = [
        :table_name,
        :status
      ]

      DEFAULT_TABLE_NAME = 'LCM_RELEASE'

      class << self
        def call(params)
          replacements = {
            table_name: params.release_table_name || DEFAULT_TABLE_NAME
          }

          path = File.expand_path('../../data/create_lcm_release.sql.erb', __FILE__)
          query = GoodData::Helpers::ErbHelper.template_file(path, replacements)

          sql_result = params.ads_client.execute(query)

          # TODO: Format
          GoodData.logger.info(JSON.pretty_generate(sql_result))

          [
            {
              table_name: replacements[:table_name],
              status: 'ok'
            }
          ]
        end
      end
    end
  end
end
