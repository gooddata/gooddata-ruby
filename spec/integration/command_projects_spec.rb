# encoding: UTF-8

require 'gooddata'
require 'gooddata/commands/projects'
require 'pry'

describe GoodData::Command::Projects, :constraint => 'slow' do
  before(:all) do
    @blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/test_project_model_spec.json")
    @module_blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/additional_dataset_module.json")

    GoodData.connect("svarovsky+gem_tester@gooddata.com", "jindrisska")
    @project = GoodData::Command::Projects.build({:spec => @blueprint, :token => ConnectionHelper::GD_PROJECT_TOKEN})
  end

  after(:all) do
    @project.delete unless @project.nil?
  end

  it "should update the project" do
    @blueprint.merge!(@module_blueprint)
    GoodData.with_project(@project) do |p|
      GoodData::Command::Projects.update({:spec => @blueprint, :project => p})
    end
  end

end