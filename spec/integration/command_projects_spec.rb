require 'gooddata'
require 'gooddata/commands/project'

describe GoodData::Command::Project, :constraint => 'slow' do
  before(:all) do
    @blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/test_project_model_spec.json")
    @module_blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/additional_dataset_module.json")

    ConnectionHelper::create_default_connection
    @project = GoodData::Command::Project.build({:spec => @blueprint, :token => ConnectionHelper::GD_PROJECT_TOKEN})
  end

  after(:all) do
    @project.delete unless @project.nil?
  end

  it "should update the project" do
    @blueprint.merge!(@module_blueprint)
    GoodData.with_project(@project) do |p|
      GoodData::Command::Project.update({:spec => @blueprint, :project => p})
    end
  end
end