require 'gooddata'
require 'gooddata/commands/project'

describe GoodData::Command::Project, :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection

    @blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/test_project_model_spec.json")
    @module_blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/additional_dataset_module.json")

    @project = GoodData::Command::Project.build({:spec => @blueprint, :token => ConnectionHelper::GD_PROJECT_TOKEN, :client => @client})
  end

  after(:all) do
    @project.delete unless @project.nil?

    @client.disconnect
  end

  it "should update the project" do
    @blueprint.merge!(@module_blueprint)
    @project.blueprint.datasets.count.should == 3
    @project.blueprint.datasets(:include_date_dimensions => true).count.should == 4
    GoodData::Command::Project.update({:spec => @blueprint, :client => @client, :project => @project})
    @project.blueprint.datasets.count.should == 4
    @project.blueprint.datasets(:include_date_dimensions => true).count.should == 5

  end
end
