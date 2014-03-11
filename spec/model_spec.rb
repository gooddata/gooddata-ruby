require 'gooddata'

describe GoodData::Model::ProjectBlueprint do

  before(:each) do
    @blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/test_project_model_spec.json")
    @repos = @blueprint.get_dataset("repos")
    @repos_schema = @repos.to_schema

    @commits = @blueprint.get_dataset("commits")
    @commits_schema = @commits.to_schema
  end

  it "should be able to grab attribute" do
    @repos_schema.labels.size.should == 1
    @repos_schema.labels.first.attribute.name.should == "id"
  end

  it "anchor should have labels" do
    @repos_schema.anchor.labels.first.identifier.should == "label.repos.id"
  end

  it "attribute should have labels" do
    @repos_schema.attributes.first.labels.first.identifier.should == "label.repos.department"
  end

  it "commits should have one fact" do
    @commits_schema.facts.size.should == 1
  end

  it "Anchor on repos should have a label" do
    @repos_schema.anchor.labels.size.should == 2
  end

  it "should not have a label for a dataset without anchor with label" do
    @commits.anchor.should == nil
    @commits.to_schema.anchor.labels.empty?.should == true 
  end

  it "should be able to provide wire representation" do
    @commits.to_wire_model
  end

end