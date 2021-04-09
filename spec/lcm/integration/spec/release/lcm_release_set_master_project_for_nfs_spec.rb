# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../../support/constants'
require_relative '../../support/configuration_helper'
require_relative '../../support/lcm_helper'
require_relative '../brick_runner'
require_relative '../shared_contexts_for_lcm'

$master_projects = []
$client_projects = []

describe 'Release brick with NFS', :vcr do
  include_context 'lcm bricks',
                  ads: false

  it 'set master project - first run' do
    @test_context[:master_project_id] = 'fake_project_id'
    @test_context[:data_product] = 'LCM_DATA_PRODUCT_' + SecureRandom.urlsafe_base64(5).gsub('-', '_')
    puts "data_product 1: #{@test_context[:data_product]}"
    BrickRunner.release_brick context: @test_context, template_path: '../../params/release_brick_set_master_project.json.erb', client: @prod_rest_client, set_master_project: true
    segments = JSON.parse(@test_context[:segments])
    segments.each do |s|
      latest_master = GoodData::LCM2::Helpers.latest_master_project_from_nfs(@config[:prod_organization], @test_context[:data_product], s['segment_id'])
      expect(latest_master[:version].to_i).to eq 1
      expect(latest_master[:master_project_id]).to eq 'fake_project_id'
    end

  end

  it 'set master project - second run' do
    @test_context[:master_project_id] = 'project_id_1'
    @test_context[:data_product] = 'LCM_DATA_PRODUCT_' + SecureRandom.urlsafe_base64(5).gsub('-', '_')
    puts "data_product 2: #{@test_context[:data_product]}"
    BrickRunner.release_brick context: @test_context, template_path: '../../params/release_brick_set_master_project.json.erb', client: @prod_rest_client, set_master_project: true
    segments = JSON.parse(@test_context[:segments])
    segments.each do |s|
      latest_master = GoodData::LCM2::Helpers.latest_master_project_from_nfs(@config[:prod_organization], @test_context[:data_product], s['segment_id'])
      expect(latest_master[:version].to_i).to eq 1
      expect(latest_master[:master_project_id]).to eq 'project_id_1'
    end

    @test_context[:master_project_id] = 'project_id_2'
    BrickRunner.release_brick context: @test_context, template_path: '../../params/release_brick_set_master_project.json.erb', client: @prod_rest_client, set_master_project: true
    segments.each do |s|
      latest_master = GoodData::LCM2::Helpers.latest_master_project_from_nfs(@config[:prod_organization], @test_context[:data_product], s['segment_id'])
      expect(latest_master[:version].to_i).to eq 2
      expect(latest_master[:master_project_id]).to eq 'project_id_2'
    end
  end

end
