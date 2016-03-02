# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'
require 'gooddata/commands/project'

describe GoodData::Command::Project, :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection

    @blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/blueprints/test_project_model_spec.json")
    @module_blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/blueprints/additional_dataset_module.json")
    @project = GoodData::Command::Project.build({:spec => @blueprint, :token => ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT, :client => @client})
  end

  after(:all) do
    @project.delete unless @project.nil?
    @client.disconnect
  end

  it "should update the project" do
    @blueprint.merge!(@module_blueprint)
    @project.blueprint.datasets.count.should == 3
    @project.blueprint.datasets(:all, :include_date_dimensions => true).count.should == 4
    @project.update_from_blueprint(@blueprint)
    @project.blueprint.datasets.count.should == 4
    @project.blueprint.datasets(:all, :include_date_dimensions => true).count.should == 5
  end
end
