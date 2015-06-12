# encoding: UTF-8
require 'gooddata'

describe GoodData::Model::ProjectBlueprint do

  before(:each) do
    @blueprint = GoodData::Model::ProjectBlueprint.from_json('./spec/data/blueprints/test_project_model_spec.json')
    @invalid_blueprint = GoodData::Model::ProjectBlueprint.from_json('./spec/data/blueprints/invalid_blueprint.json')
    @spec_blueprint = GoodData::Model::FromWire.from_wire(MultiJson.load(File.read('./spec/data/wire_models/model_view.json')))
    @repos = @blueprint.find_dataset('dataset.repos')
    @commits = @blueprint.find_dataset('dataset.commits')
  end

  describe '#title' do
    it "should return the title" do
      expect(@blueprint.title).to eq "RubyGem Dev Week test"
    end
  end

  describe '#valid?' do
    it 'valid blueprint should be marked as valid' do
      expect(@blueprint.valid?).to eq true
    end

    it 'model should be invalid if it contains more than one anchor' do
      bp = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
        p.add_dataset("dataset.repos") do |d|
          d.add_anchor("repo_id")
          d.add_anchor("repo_id2")
          d.add_fact("numbers")
          d.add_attribute("name")
        end
      end
      expect(bp.valid?).to be_falsey
      errors = bp.validate
      expect(errors.map {|x| x[:type]}.to_set).to eq [:attribute_without_label, :more_than_on_anchor].to_set
      expect(errors.count).to eq 2
    end

    it 'model should be invalid if it contains no anchor' do
      bp = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
        p.add_dataset("dataset.repos") do |d|
          d.add_fact("numbers")
          d.add_attribute("name")
          d.add_label('some_label', reference: 'name')
        end
      end
      expect(bp.valid?).to be_falsey
      errors = bp.validate
      expect(errors.first[:type]).to eq :no_anchor
      expect(errors.count).to eq 1
    end

    it 'model should be invalid if it has invalid gd data type' do
      bp = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
        p.add_dataset("dataset.repos") do |d|
          d.add_anchor("attr.repository", label_id: 'label.repo.name', label_gd_data_type: "INTEGERX")
          d.add_attribute("attr.attribute1", title: 'Some attribute')
          d.add_label('label.attribute1.name', gd_data_type: "SOMEOTHER", reference: "attr.attribute1")
        end
      end
      expect(bp.valid?).to be_falsey
      errors = bp.validate
      expect(errors.count).to eq 2
    end

    it 'model should be valid if it has int specified as integer and default should be decimal' do
      bp = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
        p.add_dataset("dataset.repos") do |d|
          d.add_anchor("attr.repository")
          d.add_label('label.repository.name', reference: 'attr.repository')
          d.add_attribute("attr.attribute1", title: 'Some attribute')
          d.add_label('label.attribute1.name', reference: 'attr.attribute1')
          d.add_fact('some_numbers', gd_data_type: 'INT')
          d.add_fact('more_numbers')
        end
      end
      bp.valid?.should == true
      errors = bp.validate
      expect(errors.count).to eq 0
      facts = bp.to_wire[:diffRequest][:targetModel][:projectModel][:datasets].first[:dataset][:facts]
      expect(facts[0][:fact][:dataType]).to eq 'INT'
      expect(facts[1][:fact][:dataType]).to eq 'DECIMAL(12,2)'
    end

    it 'invalid blueprint should be marked as invalid' do
      expect(@invalid_blueprint.valid?).to eq false
    end
  end
  
  describe '#validate' do
    it 'valid blueprint should give you empty array of errors' do
      expect(@blueprint.validate).to be_empty
    end

    it 'invalid blueprint should give you list of violating references' do
      errors = @invalid_blueprint.validate
      expect(errors.size).to eq 1
      expect(errors).to eq([{
        :type=>:wrong_label_reference,
        :label=>"some_label_id",
        :wrong_reference=>"attr.repos.repo_id                 ERROR"
        }])
    end

    it 'invalid label is caught correctly' do
      bp = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
        p.add_dataset("dataset.repos") do |d|
          d.add_anchor("attr.repository", label_id: 'label.repo.name')
          d.add_attribute("attr.attribute1", title: 'Some attribute')
          d.add_label('label.attribute1.name', reference: 'attr.attribute23123')
          d.add_label('label.attribute1.ssn', reference: 'attr.attribute23123')
          d.add_fact('some_numbers', gd_data_type: 'INT')
          d.add_fact('more_numbers')
        end
      end
      expect(bp.valid?).to be_falsey
      errors = bp.validate
      expect(errors.count).to eq 3
      expect(errors).to eq [
        {
          :type=>:wrong_label_reference,
          :label=>"label.attribute1.name",
          :wrong_reference=>"attr.attribute23123"
        },
        {
          :type=>:wrong_label_reference,
          :label=>"label.attribute1.ssn",
          :wrong_reference=>"attr.attribute23123"
        },
        {
          :type=>:attribute_without_label,
          :attribute=>"attr.attribute1"
        }
      ]
    end
  end

  describe '#remove_dataset!' do
    it "should be able to remove dataset by name" do
      expect(@blueprint.datasets.count).to eq 3
      bp = @blueprint.remove_dataset!('dataset.repos')
      expect(bp).to be_kind_of(GoodData::Model::ProjectBlueprint)
      expect(@blueprint.datasets.count).to eq 2
    end

    it "should be able to remove dataset by reference" do
      expect(@blueprint.datasets.count).to eq 3
      dataset = @blueprint.find_dataset('dataset.repos')
      bp = @blueprint.remove_dataset!(dataset)
      expect(bp).to be_kind_of(GoodData::Model::ProjectBlueprint)
      expect(@blueprint.datasets.count).to eq 2
    end

    it "should be able to remove dataset by name" do
      expect(@blueprint.datasets.count).to eq 3
      bp = GoodData::Model::ProjectBlueprint.remove_dataset!(@blueprint, 'dataset.repos')
      expect(bp).to be_kind_of(Hash)
      expect(@blueprint.datasets.count).to eq 2
    end

    it "should be able to remove dataset by reference" do
      expect(@blueprint.datasets.count).to eq 3
      dataset = @blueprint.find_dataset('dataset.repos')
      bp = GoodData::Model::ProjectBlueprint.remove_dataset!(@blueprint, dataset)
      expect(bp).to be_kind_of(Hash)
      expect(@blueprint.datasets.count).to eq 2
    end
  end

  describe '#references' do
    it 'references return empty array if there is no reference' do
      refs = @blueprint.find_dataset('dataset.devs').references
      expect(refs).to be_empty
    end
  end

  describe '#find_dataset' do
    it 'should be able to get dataset by identifier' do
      ds = @blueprint.find_dataset('dataset.devs')
      expect(ds.id).to eq 'dataset.devs'
      expect(ds).to be_kind_of(GoodData::Model::DatasetBlueprint)
    end

    it 'should throw an error if the dataset with a given name could not be found' do
      expect { @blueprint.find_dataset('nonexisting_dataset') }.to raise_error
    end

    it "should be pssible to find a dataset using dataset" do
      ds = @blueprint.find_dataset('dataset.devs')
      sds = @blueprint.find_dataset(ds)
      expect(ds).to eq sds
    end
  end

  describe '#to_blueprint' do
    it "should be possible to create ProjectBlueprint from SchemaBuilder" do
      builder = GoodData::Model::SchemaBuilder.create("stuff") do |d|
        d.add_anchor("anchor_id")
        d.add_attribute("id", title: "My Id")
        d.add_label("label", reference: "id")
        d.add_fact("amount", title: "Amount")
      end
      bp2 = builder.to_blueprint
      expect(bp2.valid?).to eq true
    end

    it "should be possible to create ProjectBlueprint from SchemaBuilder" do
      builder = GoodData::Model::SchemaBuilder.create("stuff") do |d|
        d.add_anchor("anchor_id")
        d.add_attribute("id", title: "My Id")
        d.add_label("label", reference: "id")
        d.add_fact("amount", title: "Amount")
      end

      bp1 = GoodData::Model::ProjectBlueprint.new(builder)
      expect(bp1.valid?).to eq true
    end
  end

  describe '#dataset?' do
    it 'should be able to tell me if ceratain dataset by name is in the blueprint' do
      expect(@blueprint.dataset?('dataset.devs')).to be_truthy
    end
  end

  describe '#anchor?' do
    it 'should tell you it has anchor when it does' do
      expect(@repos.anchor?).to eq true
    end
  end

  describe '#anchor' do
    it 'should tell you anchor does have labels' do
      expect(@commits.anchor.labels.count).to eq 0
    end

    it 'anchor should have labels' do
      expect(@repos.anchor.labels.first.id).to eq 'some_label_id'
    end
  end

  describe '#attributes' do
    it 'attribute should have labels' do
      expect(@repos.attributes.first.labels.first.id).to eq 'some_attr_label_id'
    end

    it "should return attributes form all datasets" do
      expect(@blueprint.attributes.count).to eq 1
    end

    it 'should be able to grab attribute' do
      expect(@repos.labels.size).to eq 2
      expect(@repos.labels('some_attr_label_id').attribute).to eq @repos.attributes('some_attr_id')
      expect(@repos.labels('some_label_id').attribute.id).to eq 'attr.repos.repo_id'
    end
  end

  describe '#facts' do
    it 'commits should have one fact' do
      expect(@commits.facts.size).to eq 1
    end

    it 'commits should have one fact' do
      expect(@repos.facts.size).to eq 0
    end

    it "should return facts form all datasets" do
      expect(@blueprint.facts.count).to eq 1
    end
  end
  
  describe '#labels' do
    it 'Anchor on repos should have a label' do
      expect(@repos.anchor.labels.size).to eq 1
    end

    it 'should not have a label for a dataset without anchor with label' do
      expect(@commits.anchor.labels).to eq []
    end

    it "should return labels form all datasets" do
      expect(@blueprint.labels.count).to eq 4
    end    
  end

  describe '#attributes_and_anchors' do
    it "should return labels form all datasets" do
      expect(@blueprint.attributes_and_anchors.count).to eq 4
    end
  end

  describe '#merge' do
    it "should be able to merge models without mutating the original" do
      additional_blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/blueprints/additional_dataset_module.json") 
      expect(@blueprint.datasets.count).to eq 3
      new_bp = @blueprint.merge(additional_blueprint)
      expect(@blueprint.datasets.count).to eq 3
      expect(new_bp.datasets.count).to eq 4
    end

    it "should perform merge in associative matter. Order should not matter." do
      a = GoodData::Model::ProjectBlueprint.build("p") do |p|
        p.add_date_dimension("updated_on")
        p.add_dataset('stuff') do |d|
          d.add_anchor('stuff_id')
          d.add_label('name', reference: 'stuff_id')
          d.add_date('updated_on')
        end
      end
      b = GoodData::Model::ProjectBlueprint.build("p") do |p|
        p.add_date_dimension("created_on")
        p.add_dataset('stuff') do |d|
          d.add_attribute('attr_id')
          d.add_label('attr_name', reference: 'attr_id')
          d.add_date('created_on')
        end
      end
      # those two are the same. Notice that we have made the titles the same
      # Merging titles is not associative
      a_b = a.merge(b)
      b_a = b.merge(a)
      expect(a_b.valid?).to eq true
      expect(b_a.valid?).to eq true
      expect(b_a).to eq a_b
    end

    it "should perform merge in associative matter. Order should not matter." do
      a = GoodData::Model::ProjectBlueprint.build("p") do |p|
        p.add_date_dimension("updated_on")
        p.add_dataset('stuff') do |d|
          d.add_anchor('stuff_id')
          d.add_label('name', reference: 'stuff_id')
          d.add_date('updated_on')
        end
      end
      b = GoodData::Model::ProjectBlueprint.build("p") do |p|
        p.add_date_dimension("created_on")
        p.add_dataset('stuff') do |d|
          d.add_attribute('attr_id')
          d.add_label('attr_name', reference: 'attr_id')
          d.add_date('created_on')
        end
      end
      # those two are the same. Notice that we have made the titles the same
      # Merging titles is not associative
      a_b = a.merge(b)
      b_a = b.merge(a)
      expect(a_b.valid?).to eq true
      expect(b_a.valid?).to eq true
      expect(b_a).to eq a_b
    end

    it "should fail if unable to merge date dimensions (they are different)." do
      a = GoodData::Model::ProjectBlueprint.build("p") do |p|
        p.add_date_dimension("created_on", title: 'title A')
        p.add_dataset('stuff') do |d|
          d.add_anchor('stuff_id')
          d.add_label('name', reference: 'stuff_id')
          d.add_date('created_on')
        end
      end
      b = GoodData::Model::ProjectBlueprint.build("p") do |p|
        p.add_date_dimension("created_on", title: 'title B')
        p.add_dataset('stuff') do |d|
          d.add_attribute('attr_id')
          d.add_label('attr_name', reference: 'attr_id')
          d.add_date('created_on')
        end
      end
      expect {
        c = a.merge(b)
      }.to raise_exception 'Unable to merge date dimensions created_on with defintion {:type=>:date_dimension, :urn=>nil, :id=>"created_on", :title=>"title B"} with {:type=>:date_dimension, :urn=>nil, :id=>"created_on", :title=>"title A"}'
    end
  end

  describe '#merge!' do
    it "should be able to merge models" do
      additional_blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/blueprints/additional_dataset_module.json") 
      expect(@blueprint.datasets.count).to eq 3
      @blueprint.merge!(additional_blueprint)
      expect(@blueprint.datasets.count).to eq 4
    end
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



  it "should be able to serialize itself to a hash" do
    ser = @blueprint.to_hash
    ser.is_a?(Hash)
    expect(ser.keys).to eq [:title, :datasets, :date_dimensions]
  end

  it "should be able to tell you whether a dataset is referencing any others including date dimensions" do
    d = @blueprint.datasets('dataset.commits')
    referenced_datasets = @blueprint.referenced_by(d)
    expect(referenced_datasets.count).to eq 3
  end

  it "should be able to find star centers - datasets that are not referenced by any other - these are typical fact tables" do
    centers = @blueprint.find_star_centers
    expect(centers.count).to eq 1
    expect(centers.first.id).to eq 'dataset.commits'
  end

  it "should be able to return all attributes or anchors that can break metrics computed in the context of given dataset" do
    commits = @blueprint.datasets('dataset.commits')
    expect(commits.broken_by.count).to eq 3
    expect(commits.broken_by.map(&:id)).to eq ["attr.devs.dev_id", "some_attr_id", "attr.repos.repo_id"]
  end

  it 'blueprint can be set without date reference and default format is set' do
    bp = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
      p.add_date_dimension("committed_on")

      p.add_dataset("dataset.repos") do |d|
        d.add_anchor("attr.repository")
        d.add_label('label.repo.name')
        d.add_attribute("attr.attribute1", title: 'Some attribute')
        d.add_label('label.attribute1.name', reference: 'attr.attribute1')
        d.add_label('label.attribute1.ssn', reference: 'attr.attribute1')
        d.add_fact('some_numbers', gd_data_type: 'INT')
        d.add_fact('more_numbers')
        d.add_date('opportunity_comitted', dataset: 'committed_on')
      end
    end
    expect(bp.datasets.flat_map { |d| d.find_columns_by_type(:date) }.map { |a| a.format }).to eq [GoodData::Model::DEFAULT_DATE_FORMAT]
  end

  it 'blueprint can be set with explicit date' do
    bp = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
      p.add_date_dimension("committed_on")

      p.add_dataset("dataset.repos") do |d|
        d.add_anchor("attr.repository", label_id: 'label.repo.name')
        d.add_attribute("attr.attribute1")
        d.add_label('label.attribute1.name', title: 'Some attribute', reference: 'attr.attribute1')
        d.add_label('label.attribute1.ssn', reference: 'attr.attribute1')
        d.add_fact('some_numbers', gd_data_type: 'INT')
        d.add_fact('more_numbers')
        d.add_date('opportunity_comitted', dataset: 'committed_on', format: 'yyyy/MM/dd')
      end
    end
    expect(bp.valid?).to be_truthy
    expect(bp.datasets.flat_map { |d| d.find_columns_by_type(:date) }.map { |a| a.format }).to eq ['yyyy/MM/dd']
  end

  describe '#remove' do
    it 'can remove the anchor' do
      bp = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
        p.add_dataset("dataset.repos") do |d|
          d.add_anchor("attr.repository", label_id: 'label.repo.name')
          d.add_label('label.repository.name', title: 'Some attribute', reference: 'attr.repository')
        end
      end
      expect(bp.datasets('dataset.repos').anchor.labels.count).to eq 1
      bp.datasets('dataset.repos').anchor.remove!
      expect(bp.datasets('dataset.repos').anchor.labels.count).to eq 0
    end
  end

  describe '#move!' do
    it 'can move attribute around' do
      expect(@blueprint.datasets('dataset.repos').fields.count).to eq 4
      expect(@blueprint.datasets('dataset.commits').fields.count).to eq 5
      attr_before = @blueprint.datasets('dataset.repos').attributes('some_attr_id')
      expect(attr_before).to_not be_nil
      expect(@blueprint.datasets('dataset.commits').attributes('some_attr_id')).to be_nil
      expect(attr_before.labels.first.dataset_blueprint.id).to eq 'dataset.repos'
      @blueprint.move!('some_attr_id', 'dataset.repos', 'dataset.commits')

      attr_after = @blueprint.datasets('dataset.commits').attributes('some_attr_id')

      expect(@blueprint.datasets('dataset.repos').fields.count).to eq 2
      expect(@blueprint.datasets('dataset.commits').fields.count).to eq 7
      expect(@blueprint.datasets('dataset.repos').attributes('some_attr_id')).to be_nil
      expect(attr_after).to_not be_nil
      expect(attr_after.labels.first.dataset_blueprint.id).to eq 'dataset.commits'
    end

    it 'can move fact around' do
      @blueprint.move!('fact.commits.lines_changed', 'dataset.commits', 'dataset.repos')
      expect(@blueprint.datasets('dataset.commits').facts.count).to eq 0
      expect(@blueprint.datasets('dataset.repos').facts.count).to eq 1
    end

    it 'crashes gracefully when nonexistent field is being moved' do
      expect {
        @blueprint.move!('nonexistent_field', 'dataset.commits', 'dataset.repos')
      }.to raise_exception 'Column nonexistent_field cannot be found in dataset dataset.commits'
    end

    it 'crashes gracefully when datasets does not exist' do
      expect {
        @blueprint.move!('nonexistent_field', 'dataset.A', 'dataset.repos')
      }.to raise_exception 'Dataset "dataset.A" could not be found'
    end

    it 'crashes gracefully when datasets does not exist' do
      expect {
        @blueprint.move!('nonexistent_field', 'dataset.commits', 'dataset.B')
      }.to raise_exception 'Dataset "dataset.B" could not be found'
    end
  end

  it 'should be able to refactor facts from attributes' do
    blueprint = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
      p.add_dataset('opportunities') do |d|
        d.add_anchor('opportunities.id')
        d.add_fact('opportunities.age')
        d.add_fact('opportunities.amount')
        d.add_attribute('opportunities.name')
        d.add_label('label.opportunities.name', reference: 'opportunities.name')
        d.add_attribute('opportunities.region')
        d.add_label('label.opportunities.region', reference: 'opportunities.region')
        d.add_reference('user_id', dataset: 'users')
        d.add_reference('account_id', dataset: 'accounts')
      end

      p.add_dataset('users') do |d|
        d.add_anchor('users.id')
        d.add_attribute('users.name')
        d.add_label('label.users.name', reference: 'users.name')
      end

      p.add_dataset('accounts') do |d|
        d.add_anchor('accounts.id')
        d.add_attribute('accounts.name')
        d.add_label('label.accounts.region', reference: 'accounts.name')
      end
    end

    refactored = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
      p.add_dataset('opportunities') do |d|
        d.add_anchor('opportunities.id')
        d.add_fact('opportunities.age')
        d.add_fact('opportunities.amount')
        d.add_reference('user_id', dataset: 'users')
        d.add_reference('accounts')
        d.add_reference('accounts')
        d.add_reference('opportunities_dim')
      end

      p.add_dataset('opportunities_dim') do |d|
        d.add_anchor('vymysli_id')
        d.add_label('label.vymysli_id', reference: 'vymysli_id')

        d.add_attribute('opportunities.name')
        d.add_label('label.opportunities.name', reference: 'opportunities.name')
        d.add_attribute('opportunities.region')
        d.add_label('label.opportunities.region', reference: 'opportunities.region')
      end

      p.add_dataset('users') do |d|
        d.add_anchor('users.id')
        d.add_attribute('users.name')
        d.add_label('label.users.name', reference: 'users.name')
      end

      p.add_dataset('accounts') do |d|
        d.add_anchor('accounts.id')
        d.add_attribute('accounts.name')
        d.add_label('label.accounts.region', reference: 'accounts.name')
      end
    end
    expect(blueprint.refactor_split_df('opportunities')).to eq refactored
  end

  it 'should be able to refactor facts as a split into 2 datasets' do
    blueprint = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
      p.add_dataset('opportunities') do |d|
        d.add_anchor('opportunities.id')
        d.add_fact('opportunities.age')
        d.add_fact('opportunities.amount')
        d.add_attribute('opportunities.name')
        d.add_label('label.opportunities.name', reference: 'opportunities.name')
        d.add_attribute('opportunities.region')
        d.add_label('label.opportunities.region', reference: 'opportunities.region')
        d.add_reference('user_id', dataset: 'users')
        d.add_reference('account_id', dataset: 'accounts')
      end

      p.add_dataset('users') do |d|
        d.add_anchor('users.id')
        d.add_attribute('users.name')
        d.add_label('label.users.name', reference: 'users.name')
      end

      p.add_dataset('accounts') do |d|
        d.add_anchor('accounts.id')
        d.add_attribute('accounts.name')
        d.add_label('label.accounts.region', reference: 'accounts.name')
      end
    end

    refactored = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
      p.add_dataset('opportunities') do |d|
        d.add_anchor('opportunities.id')
        d.add_fact('opportunities.amount')
        d.add_attribute('opportunities.name')
        d.add_label('label.opportunities.name', reference: 'opportunities.name')
        d.add_attribute('opportunities.region')
        d.add_label('label.opportunities.region', reference: 'opportunities.region')
        d.add_reference('user_id', dataset: 'users')
        d.add_reference('account_id', dataset: 'accounts')
      end

      p.add_dataset('users') do |d|
        d.add_anchor('users.id')
        d.add_attribute('users.name')
        d.add_label('label.users.name', reference: 'users.name')
      end

      p.add_dataset('accounts') do |d|
        d.add_anchor('accounts.id')
        d.add_attribute('accounts.name')
        d.add_label('label.accounts.region', reference: 'accounts.name')
      end

      p.add_dataset('opportunities_age_fact') do |d|
        d.add_anchor('opportunities_age_fact.id')
        d.add_fact('opportunities.age')
        d.add_reference('user_id', dataset: 'users')
        d.add_reference('account_id', dataset: 'accounts')
      end
    end

    col_names = ['opportunities.age']
    # that should be possible to express with #refactor_split_facts
    expect(blueprint.refactor_split_facts('opportunities', col_names, 'opportunities_age_fact')).to eq refactored
  end
end
