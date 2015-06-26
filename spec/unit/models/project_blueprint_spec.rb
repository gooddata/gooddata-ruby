# encoding: UTF-8
require 'gooddata'

describe GoodData::Model::ProjectBlueprint do

  before(:each) do
    @blueprint = GoodData::Model::ProjectBlueprint.from_json('./spec/data/test_project_model_spec.json')
    @invalid_blueprint = GoodData::Model::ProjectBlueprint.from_json('./spec/data/blueprint_invalid.json')

    @repos = @blueprint.find_dataset('repos')

    @commits = @blueprint.find_dataset('commits')
  end

  it "should return the title" do
    expect(@blueprint.title).to eq "RubyGem Dev Week test"
  end

  it 'valid blueprint should be marked as valid' do
    expect(@blueprint.valid?).to eq true
  end

  it 'valid blueprint should give you empty array of errors' do
    expect(@blueprint.validate).to be_empty
  end

  it 'model should be invalid if it contains more than one anchor' do
    builder = GoodData::Model::ProjectBuilder.create("my_bp") do |p|
      p.add_dataset("repos") do |d|
        d.add_anchor("repo_id")
        d.add_anchor("repo_id2")
        d.add_attribute("name")
      end
    end
    bp = GoodData::Model::ProjectBlueprint.new(builder)
    expect(bp.valid?).to be_falsey
    errors = bp.validate
    expect(errors.first).to eq ({ anchor: 2 })
    expect(errors.count).to eq 1
  end

  it 'model should be invalid if it invalid gd data type' do
    builder = GoodData::Model::ProjectBuilder.create("my_bp") do |p|
      p.add_dataset("repos") do |d|
        d.add_anchor("repo_id", gd_data_type: "INTEGERX")
        d.add_attribute("attr1")
        d.add_attribute("name")
      end
    end
    bp = GoodData::Model::ProjectBlueprint.new(builder)
    bp.valid?.should == false
    errors = bp.validate
    errors.count.should == 1
  end

  it 'model should be valid if it has int specified as integer and default should be decimal' do
    builder = GoodData::Model::ProjectBuilder.create("my_bp") do |p|
      p.add_dataset("repos") do |d|
        d.add_anchor("repo_id")
        d.add_fact("fact1", gd_data_type: "integer")
        d.add_fact("fact")
        d.add_attribute("name")
      end
    end
    bp = GoodData::Model::ProjectBlueprint.new(builder)
    bp.valid?.should == true
    errors = bp.validate
    errors.count.should == 0
    facts = bp.to_wire[:diffRequest][:targetModel][:projectModel][:datasets].first[:dataset][:facts]
    expect(facts[0][:fact][:dataType]).to eq 'INT'
    expect(facts[1][:fact][:dataType]).to eq 'DECIMAL(12,2)'
  end

  it 'invalid blueprint should be marked as invalid' do
    expect(@invalid_blueprint.valid?).to eq false
  end
  
  it 'invalid blueprint should give you list of violating references' do
    errors = @invalid_blueprint.validate
    expect(errors.size).to eq 1
    expect(errors.first).to eq({
        type: 'reference',
        name: 'user_id',
        dataset: 'users',
        reference: 'user_id'
    })
  end

  it 'references return empty array if there is no reference' do
    refs = @blueprint.find_dataset('devs').references
    expect(refs).to be_empty
  end

  it "should be possible to create from ProjectBlueprint from ProjectBuilder in several ways" do
    builder = GoodData::Model::SchemaBuilder.new("stuff") do |d|
      d.add_attribute("id", title: "My Id")
      d.add_fact("amount", title: "Amount")
    end
    bp1 = GoodData::Model::ProjectBlueprint.new(builder)
    expect(bp1.valid?).to eq true

    bp2 = builder.to_blueprint
    expect(bp2.valid?).to eq true
  end

  it 'should be able to get dataset by name' do
    ds = @blueprint.find_dataset('devs')
    expect(ds.name).to eq 'devs'
  end

  it 'should throw an error if the dataset with a given name could not be found' do
    expect { @blueprint.find_dataset('nonexisting_dataset') }.to raise_error
  end

  it "should not matter if I try to find a dataset using dataset" do
    ds = @blueprint.find_dataset('devs')
    sds = @blueprint.find_dataset(ds)
    ssds = @blueprint.find_dataset(ds.to_hash)
    expect(ds).to eq sds
    expect(ds).to eq ssds
  end

  it 'should be able to tell me if ceratain dataset by name is in the blueprint' do
    expect(@blueprint.dataset?('devs')).to be_truthy
  end

  it 'should tell you it has anchor when it does' do
    expect(@repos.anchor?).to eq true
  end

  it 'should tell you it does not have anchor when it does not' do
    expect(@commits.anchor?).to be_falsey
  end

  it 'should be able to grab attribute' do
    expect(@repos.labels.size).to eq 1
    expect(@repos.labels.first[:reference]).to eq 'repo_id'
    # TODO: this would be nice
    # expect(@repos.labels.first.attribute.name).to eq 'repo_id'
  end

  it 'anchor should have labels' do
    skip('Wrap into objects')
    expect(@repos.anchor.labels.first.identifier).to eq 'label.repos.repo_id'
  end

  it 'attribute should have labels' do
    skip('Wrap into object')
    expect(@repos.attributes.first.labels.first.identifier).to eq 'label.repos.department'
  end

  it 'commits should have one fact' do
    expect(@commits.facts.size).to eq 1
  end

  it 'Anchor on repos should have a label' do
    skip('wrap into objects')
    expect(@repos.anchor.labels.size).to eq 2
  end

  it 'should not have a label for a dataset without anchor with label' do
    expect(@commits.anchor).to eq nil
  end

  it 'should be able to provide wire representation' do
    @blueprint.to_wire
  end

  it 'invalid label is caught correctly' do
    builder = GoodData::Model::ProjectBuilder.create("my_bp") do |p|
      p.add_date_dimension("committed_on")

      p.add_dataset("repos") do |d|
        d.add_anchor("repo_id")
        d.add_label("name", reference: "invalid_ref")
      end
    end
    bp = GoodData::Model::ProjectBlueprint.new(builder)
    expect(bp.valid?).to be_falsey
    errors = bp.validate
    expect(errors.count).to eq 1
  end

  it "should return attributes form all datasets" do
    expect(@blueprint.attributes.count).to eq 1
  end

  it "should return facts form all datasets" do
    expect(@blueprint.facts.count).to eq 1
  end

  it "should return labels form all datasets" do
    expect(@blueprint.labels.count).to eq 2
  end

  it "should return labels form all datasets" do
    expect(@blueprint.attributes_and_anchors.count).to eq 3
  end

  it "should be able to add datasets on the fly" do
    builder = GoodData::Model::SchemaBuilder.new("stuff") do |d|
      d.add_attribute("id", title: "My Id")
      d.add_fact("amount", title: "Amount")
    end
    dataset = builder.to_blueprint
    expect(@blueprint.datasets.count).to eq 3
    @blueprint.add_dataset!(dataset)
    expect(@blueprint.datasets.count).to eq 4
  end

  it "should be able to remove dataset by name" do
    expect(@blueprint.datasets.count).to eq 3
    @blueprint.remove_dataset!('repos')
    expect(@blueprint.datasets.count).to eq 2
  end

  it "should be able to remove dataset by reference" do
    expect(@blueprint.datasets.count).to eq 3
    dataset = @blueprint.find_dataset('repos')
    @blueprint.remove_dataset!(dataset)
    expect(@blueprint.datasets.count).to eq 2
  end

  it "should be able to serialize itself to a hash" do
    ser = @blueprint.to_hash
    ser.is_a?(Hash)
    expect(ser.keys).to eq [:title, :datasets, :date_dimensions]
  end

  it "should be able to tell you whether a dataset is referencing any others including date dimensions" do
    referenced_datasets = @blueprint.referenced_by('commits')
    expect(referenced_datasets.count).to eq 3
  end

  it "should be able to find star centers - datasets that are not referenced by any other - these are typical fact tables" do
    centers = @blueprint.find_star_centers
    expect(centers.count).to eq 1
    expect(centers.first.name).to eq 'commits'
  end

  it "should be able to return all attributes or anchors that can break metrics computed in the context of given dataset" do
    attrs = @blueprint.can_break('commits')
    expect(attrs.count).to eq 3

    attrs = @blueprint.can_break('devs')
    expect(attrs.count).to eq 1
  end

  it "should be able to merge models" do
    additional_blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/additional_dataset_module.json") 
    expect(@blueprint.datasets.count).to eq 3
    @blueprint.merge!(additional_blueprint)
    expect(@blueprint.datasets.count).to eq 4
  end

  it "should be merging in the additive matter. Order should not matter." do
    builder = GoodData::Model::ProjectBuilder.create("my_bp") do |p|
      p.add_date_dimension("created_on")
      p.add_dataset("stuff") do |d|
        d.add_anchor('repo_id')
        d.add_label('name', reference: 'invalid_ref')
      end
    end
    dataset = builder.to_blueprint

    merged1 = @blueprint.merge(dataset)
    merged2 = dataset.merge(@blueprint)
  end

  it 'blueprint can be set with date reference and default format is set' do
    builder = GoodData::Model::ProjectBuilder.create("my_bp") do |p|
      p.add_date_dimension("committed_on")

      p.add_dataset("repos") do |d|
        d.add_anchor("repo_id")
        d.add_attribute("name")
        d.add_date('opportunity_comitted', dataset: 'committed_on')
      end
    end
    bp = GoodData::Model::ProjectBlueprint.new(builder)
    expect(bp.fields.find {|f| f[:type] == :date}[:format]).to eq GoodData::Model::DEFAULT_DATE_FORMAT
  end

  it 'blueprint can be set with date reference and default format is set' do
    builder = GoodData::Model::ProjectBuilder.create("my_bp") do |p|
      p.add_date_dimension("committed_on")

      p.add_dataset("repos") do |d|
        d.add_anchor("repo_id")
        d.add_attribute("name")
        d.add_date('opportunity_comitted', dataset: 'committed_on', format: 'yyyy/MM/dd')
      end
    end
    bp = GoodData::Model::ProjectBlueprint.new(builder)
    expect(bp.fields.find {|f| f[:type] == :date}[:format]).to eq 'yyyy/MM/dd'
  end
end
