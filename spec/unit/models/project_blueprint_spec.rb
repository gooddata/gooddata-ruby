# encoding: UTF-8

require 'gooddata'

describe GoodData::Model::ProjectBlueprint do

  before(:each) do
    @blueprint = GoodData::Model::ProjectBlueprint.from_json('./spec/data/test_project_model_spec.json')
    @invalid_blueprint = GoodData::Model::ProjectBlueprint.from_json('./spec/data/blueprint_invalid.json')

    @repos = @blueprint.find_dataset('repos')
    @repos_schema = @repos.to_schema

    @commits = @blueprint.find_dataset('commits')
    @commits_schema = @commits.to_schema
  end

  it "should return the title" do
    @blueprint.title.should == ProjectHelper::TEST_PROJECT_NAME
  end

  it 'valid blueprint should be marked as valid' do
    @blueprint.model_valid?.should == true
  end

  it 'valid blueprint should give you empty array of errors' do
    expect(@blueprint.validate_model).to be_empty
  end

  it 'invalid blueprint should be marked as invalid' do
    @invalid_blueprint.model_valid?.should == false
  end
  
  it 'invalid blueprint should give you list of violating references' do
    errors = @invalid_blueprint.validate_model
    errors.size.should == 1
    errors.first.should == {
        type: 'reference',
        name: 'user_id',
        dataset: 'users',
        reference: 'user_id'
    }
  end

  it 'references return empty array if there is no reference' do
    refs = @blueprint.find_dataset('devs').references
    expect(refs).to be_empty
  end

  it 'should be able to get dataset by name' do
    ds = @blueprint.find_dataset('devs')
    ds.name.should == 'devs'
  end

  it 'should throw an error if the dataset with a given name could not be found' do
    expect { @blueprint.find_dataset('nonexisting_dataset') }.to raise_error
  end

  it 'should be able to tell me if ceratain dataset by name is in the blueprint' do
    @blueprint.dataset?('devs').should be_true
  end

  it 'should tell you it has anchor when it does' do
    @repos.anchor?.should == true
  end

  it 'should tell you it does not have anchor when it does not' do
    @commits.anchor?.should == false
  end

  it 'should be able to grab attribute' do
    @repos_schema.labels.size.should == 1
    @repos_schema.labels.first.attribute.name.should == 'repo_id'
  end

  it 'anchor should have labels' do
    @repos_schema.anchor.labels.first.identifier.should == 'label.repos.repo_id'
  end

  it 'attribute should have labels' do
    @repos_schema.attributes.first.labels.first.identifier.should == 'label.repos.department'
  end

  it 'commits should have one fact' do
    @commits_schema.facts.size.should == 1
  end

  it 'Anchor on repos should have a label' do
    @repos_schema.anchor.labels.size.should == 2
  end

  it 'should not have a label for a dataset without anchor with label' do
    @commits.anchor.should == nil
    @commits.to_schema.anchor.labels.empty?.should == true 
  end

  it 'should be able to provide wire representation' do
    @commits.to_wire_model
  end

  it 'invalid label is caught correctly' do
    builder = GoodData::Model::ProjectBuilder.create("my_bp") do |p|
      p.add_date_dimension("committed_on")

      p.add_dataset("repos") do |d|
        d.add_anchor("repo_id")
        d.add_label("name", :reference => "invalid_ref")
      end
    end
    bp = GoodData::Model::ProjectBlueprint.from_json(builder.to_hash)
    bp.model_valid?.should == false
    errors = bp.validate_model
    errors.count.should == 1
  end

  it "should return attributes form all datasets" do
    @blueprint.attributes.count.should == 1
  end

  it "should return facts form all datasets" do
    @blueprint.facts.count.should == 1
  end

  it "should return labels form all datasets" do
    @blueprint.labels.count.should == 2
  end

  it "should return labels form all datasets" do
    @blueprint.attributes_and_anchors.count.should == 3
  end

  it "should be able to add datasets on the fly" do
    builder = GoodData::Model::SchemaBuilder.new("stuff") do |d|
      d.add_attribute("id", :title => "My Id")
      d.add_fact("amount", :title => "Amount")
    end
    dataset = builder.to_blueprint
    @blueprint.datasets.count.should == 3
    @blueprint.add_dataset(dataset)
    @blueprint.datasets.count.should == 4
  end

  it "should be able to remove dataset by name" do
    @blueprint.datasets.count.should == 3
    @blueprint.remove_dataset('repos')
    @blueprint.datasets.count.should == 2
  end

  it "should be able to remove dataset by reference" do
    @blueprint.datasets.count.should == 3
    dataset = @blueprint.find_dataset('repos')
    @blueprint.remove_dataset(dataset)
    @blueprint.datasets.count.should == 2
  end

  it "should be able to serialize itself to a hash" do
    ser = @blueprint.to_hash
    ser.is_a?(Hash)
    ser.keys.should == [:title, :datasets, :date_dimensions]
  end

  it "should be able to tell you whether a dataset is referenced by any other" do
    referenced_datasets = @blueprint.referenced_by('commits')
    referenced_datasets.count.should == 2
  end

  it "should be able to find star centers - datasets that are not referenced by any other - these are typical fact tables" do
    centers = @blueprint.find_star_centers
    centers.count.should == 1
    centers.first.name.should == 'commits'
  end

  it "should be able to return all attributes or anchors that can break metrics computed in the context of given dataset" do
    attrs = @blueprint.can_break('commits')
    attrs.count.should == 3

    pending("At least those from the same dataset should be able to break")
    attrs = @blueprint.can_break('devs')
    attrs.count.should == 1
  end

  it "should be able to merge models" do
    additional_blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/additional_dataset_module.json") 
    @blueprint.datasets.count.should == 3
    @blueprint.merge!(additional_blueprint)
    @blueprint.datasets.count.should == 4
  end

  it "should be merging in the additive matter. Order should not matter." do
    builder = GoodData::Model::ProjectBuilder.create("my_bp") do |p|
      p.add_date_dimension("created_on")
      p.add_dataset("stuff") do |d|
        d.add_anchor("repo_id")
        d.add_label("name", :reference => "invalid_ref")
      end
    end
    dataset = builder.to_blueprint

    merged1 = @blueprint.merge(dataset)
    merged2 = dataset.merge(@blueprint)
  end
end