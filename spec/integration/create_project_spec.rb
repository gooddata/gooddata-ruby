# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe 'Create project using GoodData client', :vcr, :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
  end

  after(:all) do
    @client.disconnect
  end

  it 'Should create project using GoodData::Rest::Client#create_project' do
    project_title = 'Test #create_project'
    begin
      project = @client.create_project(:title => project_title, :auth_token => ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
      expect(project.title).to eq(project_title)
    ensure
      project.delete if project
    end
  end
end
