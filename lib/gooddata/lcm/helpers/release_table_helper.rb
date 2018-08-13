# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module LCM2
    class Helpers
      DEFAULT_TABLE_NAME = 'LCM_RELEASE'

      class << self
        def latest_master_project(release_table_name, ads_client, segment_id)
          replacements = {
            table_name: release_table_name || DEFAULT_TABLE_NAME,
            segment_id: segment_id
          }

          path = File.expand_path('../../data/select_from_lcm_release.sql.erb', __FILE__)
          query = GoodData::Helpers::ErbHelper.template_file(path, replacements)

          res = ads_client.execute_select(query)
          sorted = res.sort_by { |row| row[:version] }
          sorted.last
        end
      end
    end
  end
end
