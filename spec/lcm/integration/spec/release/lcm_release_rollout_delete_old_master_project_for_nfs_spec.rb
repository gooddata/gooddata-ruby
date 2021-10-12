# encoding: UTF-8
#
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../../support/constants'
require_relative '../../support/configuration_helper'
require_relative '../../support/lcm_helper'
require_relative '../brick_runner'
require_relative '../shared_contexts_for_lcm'

$master_projects = []
$client_projects = []

describe 'Release and Rollout brick with NFS', :vcr do
  include_context 'lcm bricks',
                  ads: false

  let(:release_result) do
    [
        { master_project_id: 'nfs_master_project_id_1', version: 1 },
        { master_project_id: 'nfs_master_project_id_2', version: 2 }
    ]
  end

  it 'delete old master project - second run release and first run rollout' do
    rollout_result = []
    @test_context[:master_project_id] = release_result[0][:master_project_id]
    @test_context[:data_product] = 'LCM_DATA_PRODUCT_' + SecureRandom.urlsafe_base64(5).gsub('-', '_')
    @test_context[:release_table_name] = "#{@test_context[:data_product]}_LCM_RELEASE"
    BrickRunner.release_brick context: @test_context, template_path: '../../params/release_brick_delete_old_master_project.json.erb', client: @prod_rest_client, set_master_project: true

    @test_context[:master_project_id] = release_result[1][:master_project_id]
    BrickRunner.release_brick context: @test_context, template_path: '../../params/release_brick_delete_old_master_project.json.erb', client: @prod_rest_client, set_master_project: true
    segments = JSON.parse(@test_context[:segments])
    segments.each do |s|
      segment_id = s['segment_id']
      master_projects = GoodData::LCM2::Helpers.get_master_project_list_from_nfs(@test_context[:release_table_name], @ads_client, segment_id)
      expect(master_projects.size).to eq 2
      rollout_result << master_projects.find { |p| p[:version] == 2 }
    end

    @test_context[:keep_only_previous_masters_count] = '0'
    BrickRunner.rollout_brick context: @test_context, template_path: '../../params/rollout_brick_delete_old_master_project.json.erb', client: @prod_rest_client
    segments.each do |s|
      segment_id = s['segment_id']
      expected_master_project = rollout_result.select { |p| p[:segment_id].to_s == segment_id }
      rollout_master_projects = GoodData::LCM2::Helpers.get_master_project_list_from_ads(@test_context[:release_table_name], @ads_client, segment_id)
      expect(rollout_master_projects).to eq(expected_master_project)
    end
  end
end
