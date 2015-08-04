# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe "Spin a project from template", :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
  end

  after(:all) do
    @client.disconnect
  end

  it "should spin a project from a template that does not exist. It should throw an error" do
    expect{GoodData::Project.create(:title => "Test project", :template => "/some/nonexisting/template/uri", :auth_token => ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT, :client => @client)}.to raise_error
  end

end
