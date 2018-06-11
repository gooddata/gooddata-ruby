# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/connection'
require 'gooddata/core/project'
require 'gooddata/models/project'

describe 'GoodData - project', :vcr do
  before(:each) do
    @client = ConnectionHelper.create_default_connection
  end

  after(:each) do
    @client.disconnect
  end

  describe '#project=' do
    it 'Assigns nil' do
      GoodData.project = nil
    end

    it 'Assigns project using project ID' do
      GoodData.use(ProjectHelper::PROJECT_ID, client: @client)
    end

    it 'Assigns project using project URL' do
      GoodData.use ProjectHelper::PROJECT_URL, client: @client
    end

    it 'Assigns project directly' do
      GoodData.project = GoodData::Project[ProjectHelper::PROJECT_ID, client: @client]
    end
  end

  describe '#project' do
    it 'Returns project assigned' do
      GoodData.project = nil
      expect(GoodData.project).to be_nil

      GoodData.use ProjectHelper::PROJECT_ID, client: @client
      expect(GoodData.project).not_to be_nil
    end
  end

  describe '#with_project' do
    it 'Uses project specified' do
      GoodData.with_project GoodData::Project[ProjectHelper::PROJECT_ID, :client => @client] do
      end
    end
  end
end
