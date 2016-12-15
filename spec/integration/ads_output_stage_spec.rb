# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe GoodData::AdsOutputStage, :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
    # @ads = GoodData::DataWarehouse.create(client: @client, title: 'Test ADS', auth_token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)

    # try to delete all posible ads
    GoodData::DataWarehouse.all.map do |ads|
      begin
        ads.delete
      rescue => e
        puts "Cannot delete ads #{ads.id}. Reason: #{e.message}"
      end
    end

    @ads = GoodData::DataWarehouse.all.first
    @ads ||= GoodData::DataWarehouse.create(client: @client, title: 'Test ADS', auth_token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
    @project = @client.create_project(title: 'Test project', auth_token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
  end

  after(:all) do
    @project && @project.delete
    # @ads && @ads.delete // cannot delete because of c4 still contains the deleted project info
    @client && @client.disconnect
  end

  it 'should be able to create output stage' do
    @project.add.output_stage = GoodData::AdsOutputStage.create(client: @client, ads: @ads, client_id: 'Client_Id', project: @project)
    expect(@project.add.output_stage.schema).to eq "#{@ads.schemas}/default"
    expect(@project.add.output_stage.client_id).to eq 'Client_Id'
    expect(@project.add.process).not_to be_nil
    expect(@project.add.process.type).to eq :dataload
  end

  it 'shoule be able to show the sql diff' do
    expect(@project.add.output_stage.sql_diff).to eq '-- Output Stage and LDM column mapping matches.'
  end
end
