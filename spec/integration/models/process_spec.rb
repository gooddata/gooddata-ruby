# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe GoodData::Process do
  before(:all) do
    @rest_client = ConnectionHelper.create_default_connection
    @suffix = AppstoreProjectHelper.suffix
    @project = ProjectHelper.get_default_project client: @rest_client
  end

  describe '.deploy_component' do
    let(:name) { 'test component' }

    it 'deploys etl pluggable component' do
      component_data = {
        name: name,
        type: :etl,
        component: {
          name: 'gdc-etl-sql-executor',
          version: '1'
        }
      }
      component = GoodData::Process.deploy_component component_data,
                                                     client: @rest_client,
                                                     project: @project
      expect(component.name).to eq name
      expect(component.type).to eq :etl
    end
  end
end
