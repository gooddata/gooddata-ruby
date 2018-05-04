# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'
require 'gooddata/commands/project'

describe GoodData::Command::Project, :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection

    @blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/blueprints/test_project_model_spec.json")
    @module_blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/blueprints/additional_dataset_module.json")
    @project = GoodData::Command::Project.build(:spec => @blueprint, :token => ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT, :client => @client)
  end

  after(:all) do
    @project.delete unless @project.nil?
    @client.disconnect
  end

  it "should update the project" do
    @blueprint.merge!(@module_blueprint)
    expect(@project.blueprint.datasets.count).to eq(3)
    expect(@project.blueprint.datasets(:all, :include_date_dimensions => true).count).to eq(4)
    @project.update_from_blueprint(@blueprint)
    expect(@project.blueprint.datasets.count).to eq(4)
    expect(@project.blueprint.datasets(:all, :include_date_dimensions => true).count).to eq(5)
  end

  describe '#get_spec_and_project_id' do
    before do
      File.write '.gooddata', { model: 'model.rb', project_id:  @project.pid}.to_json
      File.write 'model.rb', 'puts "lolek"'
    end

    after do
      `rm .gooddata model.rb`
    end

    it 'works' do
      expect(GoodData::Command::Project.get_spec_and_project_id('.')).to be_truthy
    end
  end
end
