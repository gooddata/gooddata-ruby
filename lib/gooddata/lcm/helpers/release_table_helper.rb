# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module LCM2
    class Helpers
      DEFAULT_TABLE_NAME = 'LCM_RELEASE'
      DEFAULT_NFS_DIRECTORY = '/release-tables'

      class << self
        def latest_master_project_from_ads(release_table_name, ads_client, segment_id)
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

        def latest_master_project_from_nfs(domain_id, data_product_id, segment_id)
          file_path = path_to_release_table_file(domain_id, data_product_id, segment_id)
          data = GoodData::Helpers::Csv.read_as_hash(file_path)
          latest_master_project = data.sort_by { |master| master[:version] }
              .reverse.first

          version_info =  latest_master_project ? "master_pid=#{latest_master_project[:master_project_id]} version=#{latest_master_project[:version]}" : ""
          GoodData.gd_logger.info "Getting latest master project: file=#{file_path} domain=#{domain_id} data_product=#{data_product_id} segment=#{segment_id} #{version_info}"
          latest_master_project
        end

        def update_latest_master_to_nfs(domain_id, data_product_id, segment_id, master_pid, version)
          file_path = path_to_release_table_file(domain_id, data_product_id, segment_id)
          GoodData.gd_logger.info "Updating release table: file=#{file_path} domain=#{domain_id} data_product=#{data_product_id} segment=#{segment} master_pid=#{master_pid} version=#{version}"
          GoodData::Helpers::Csv.ammend_line(
            file_path,
            master_project_id: master_pid,
            version: version
          )
        end

        def path_to_release_table_file(domain_id, data_prod_id, segment_id)
          nsf_directory = ENV['RELEASE_TABLE_NFS_DIRECTORY'] || DEFAULT_NFS_DIRECTORY
          [nsf_directory, domain_id, data_prod_id + '-' + segment_id + '.csv'].join('/')
        end
      end
    end
  end
end
