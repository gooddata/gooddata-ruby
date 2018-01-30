# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe GoodData::Label do
  before(:all) do
    @rest_client = ConnectionHelper.create_default_connection
    @suffix = AppstoreProjectHelper.suffix
    @opts = {
      client: @rest_client,
      title: "Project for label spec #{@suffix}",
      auth_token: ConnectionHelper::GD_PROJECT_TOKEN,
      environment: 'TESTING',
      prod_organization: 'staging-lcm-prod'
    }
    project_helper = AppstoreProjectHelper.create(@opts)
    project_helper.create_ldm
    project_helper.load_data
    @project = project_helper.project
    @label = @project.attributes('label.csv_policies.customer')
  end
  after(:all) do
    @project.delete unless @project.deleted?
  end
  # this is a substring of another value in the set, AA10041
  let(:expected_id) { 'AA1004' }

  describe '#get_valid_elements' do
    it 'returns an exact match' do
      eles = @label.get_valid_elements filter: expected_id
      eles['validElements']['items'].each do |ele|
        expect(ele['element']['title']).to eq expected_id
      end
    end
  end
end
