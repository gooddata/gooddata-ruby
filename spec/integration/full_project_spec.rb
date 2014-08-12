require 'gooddata'

describe "Full project implementation", :constraint => 'slow' do
  before(:all) do
    @spec = JSON.parse(File.read("./spec/data/test_project_model_spec.json"), :symbolize_names => true)
    @invalid_spec = JSON.parse(File.read("./spec/data/blueprint_invalid.json"), :symbolize_names => true)
    @client = ConnectionHelper::create_default_connection
    @project = GoodData::Model::ProjectCreator.migrate({:spec => @spec, :token => ConnectionHelper::GD_PROJECT_TOKEN, :client => @client})
  end

  after(:all) do
    @project.delete unless @project.nil?

    @client.disconnect
  end

  it "should not build an invalid model" do
    expect {
      GoodData::Model::ProjectCreator.migrate({:spec => @invalid_spec, :token => ConnectionHelper::GD_PROJECT_TOKEN, :client => @client})
    }.to raise_error(GoodData::ValidationError)
  end

  it "should contain datasets" do
    @project.blueprint.tap do |bp|
      expect(bp.datasets.count).to eq 3
      expect(bp.datasets(:include_date_dimensions => true).count).to eq 4
    end
  end

  it "should be able to rename a project" do
    former_title = @project.title
    a_title = (0...8).map { (65 + rand(26)).chr }.join
    @project.title = a_title
    @project.save
    expect(@project.title).to eq a_title
    @project.title = former_title
    @project.save
  end

  it "should be able to validate a project" do
    @project.validate
  end

  it "should compute an empty metric" do
    f = GoodData::Fact.find_first_by_title('Lines Changed', :client => @client, :project => @project)
    metric = GoodData::Metric.xcreate("SELECT SUM(#\"#{f.title}\")", :client => @client, :project => @project)
    metric.execute(:client => @client, :project => @project).should be_nil
  end

  it "should load the data" do
    GoodData.with_project(@project) do |p|
      blueprint = GoodData::Model::ProjectBlueprint.new(@spec)
      commits_data = [
        ["lines_changed","committed_on","dev_id","repo_id"],
        [1,"01/01/2014",1,1],
        [3,"01/02/2014",2,2],
        [5,"05/02/2014",3,1]]
      GoodData::Model.upload_data(commits_data, blueprint, 'commits', :client => @client, :project => @project)
      # blueprint.find_dataset('commits').upload(commits_data)

      devs_data = [
        ["dev_id", "email"],
        [1, "tomas@gooddata.com"],
        [2, "petr@gooddata.com"],
        [3, "jirka@gooddata.com"]]
      GoodData::Model.upload_data(devs_data, blueprint, 'devs', :client => @client, :project => @project)
      # blueprint.find_dataset('devs').upload(devs_data)
    end
  end

  it "should compute a metric" do
    f = GoodData::Fact.find_first_by_title('Lines Changed', :client => @client, :project => @project)
    metric = GoodData::Metric.xcreate("SELECT SUM(#\"#{f.title}\")", :client => @client, :project => @project)
    metric.execute(:client => @client, :project => @project).should == 9
  end

  it "should execute an anonymous metric twice and not fail" do
    f = GoodData::Fact.find_first_by_title('Lines Changed', :client => @client, :project => @project)
    metric = GoodData::Metric.xcreate("SELECT SUM(#\"#{f.title}\")", :client => @client, :project => @project)
    metric.execute(:client => @client, :project => @project).should == 9
    # Since GD platform cannot execute inline specified metric the metric has to be saved
    # The code tries to resolve this as transparently as possible
    metric.execute(:client => @client, :project => @project).should == 9
  end

  it "should compute a report" do
    f = GoodData::Fact.find_first_by_title('Lines Changed', :client => @client, :project => @project)

    # TODO: Here we create metric which is not deleted and is used by another test - "should exercise the object relations and getting them in various ways"
    metric = GoodData::Metric.xcreate("SELECT SUM(#\"#{f.title}\")", :title => "My metric", :client => @client, :project => @project)
    metric.save(:client => @client, :project => @project)
    result = GoodData::ReportDefinition.execute(:title => "My report", :top => [metric], :left => ['label.devs.dev_id.email'], :client => @client, :project => @project)
    result[1][1].should == 3
    result.include_row?(["jirka@gooddata.com", 5]).should == true

    result2 = GoodData::ReportDefinition.create(:title => "My report", :top => [metric], :left => ['label.devs.dev_id.email'], :client => @client, :project => @project).execute(:client => @client, :project => @project)
    result2[1][1].should == 3
    result2.include_row?(["jirka@gooddata.com", 5]).should == true
    result2.should == result
  end

  it "should throw an exception if trying to access object without explicitely specifying a project" do
    expect do
      GoodData::Metric[:all, :client => @client]
    end.to raise_exception(ArgumentError, 'No :project specified')
  end

  it "should be possible to get all metrics" do
    metrics1 = GoodData::Metric[:all, :client => @client, :project => @project]
    metrics2 = GoodData::Metric.all(:client => @client, :project => @project)
    metrics1.should == metrics2
  end

  it "should be possible to get all metrics with full objects" do
    metrics1 = GoodData::Metric[:all, :full => true, :client => @client, :project => @project]
    metrics2 = GoodData::Metric.all(:full => true, :client => @client, :project => @project)
    metrics1.should == metrics2
  end

  it "should be able to get a metric by identifier" do
    metrics = GoodData::Metric.all(:full => true, :client => @client, :project => @project)
    metric = GoodData::Metric[metrics.first.identifier, :client => @client, :project => @project]
    metric.identifier == metrics.first.identifier
    metrics.first == metric
  end

  it "should be able to get a metric by uri" do
    metrics = GoodData::Metric.all(:full => true, :client => @client, :project => @project)
    metric = GoodData::Metric[metrics.first.uri, :client => @client, :project => @project]
    metric.uri == metrics.first.uri
    metrics.first == metric
  end

  it "should be able to get a metric by object id" do
    metrics = GoodData::Metric.all(:full => true, :client => @client, :project => @project)
    metric = GoodData::Metric[metrics.first.obj_id, :client => @client, :project => @project]
    metric.obj_id == metrics.first.obj_id
    metrics.first == metric
  end

  it "should exercise the object relations and getting them in various ways" do
    # Find a metric by name
    metric = GoodData::Metric.find_first_by_title('My metric', :client => @client, :project => @project)
    the_same_metric = GoodData::Metric[metric, :client => @client, :project => @project]
    metric.should == metric

    # grab fact in several different ways
    fact1 = GoodData::Fact.find_first_by_title('Lines Changed', :client => @client, :project => @project)
    fact2 = GoodData::Fact[fact1.identifier, :client => @client, :project => @project]
    fact3 = GoodData::Fact[fact2.obj_id, :client => @client, :project => @project]
    fact4 = GoodData::Fact[fact3.uri, :client => @client, :project => @project]
    fact5 = @client.create(GoodData::Fact, fact4)

    # All should be the same
    fact1.should == fact2
    fact1.should == fact2
    fact1.should == fact3
    fact1.should == fact4
    fact1.should == fact5

    fact3.title = "Somewhat changed title"
    fact1.should_not == fact3

    metric.using(nil, :client => @client, :project => @project)
    metric.using('fact', :client => @client, :project => @project).count.should == 1

    fact1.used_by(nil, :client => @client, :project => @project)
    fact1.used_by('metric', :client => @client, :project => @project).count.should == 1

    res = metric.using?(fact1, :client => @client, :project => @project)
    expect(res).to be(true)

    res = fact1.using?(metric, :client => @client, :project => @project)
    expect(res).to be(false)

    res = metric.used_by?(fact1, :client => @client, :project => @project)
    expect(res).to be(false)

    res = fact1.used_by?(metric, :client => @client, :project => @project)
    expect(res).to be(true)
  end

  it "should try setting and getting by tags" do
    fact = GoodData::Fact.find_first_by_title('Lines Changed', :client => @client, :project => @project)
    fact.tags.should be_empty

    fact.tags = "tag1,tag2,tag3"
    fact.save(:client => @client, :project => @project)

    tagged_facts = GoodData::Fact.find_by_tag('tag3', :client => @client, :project => @project)
    tagged_facts.count.should == 1
  end

  it "should contain metadata for each dataset in project metadata" do
    k = GoodData::ProjectMetadata.keys(:client => @client, :project => @project)
    k.should include("manifest_devs")
  end

  it "should be able to interpolate metric based on" do
    res = GoodData::Metric.xexecute "SELECT SUM(![fact.commits.lines_changed])", :client => @client, :project => @project
    res.should == 9

    res = GoodData::Metric.xexecute( "SELECT SUM(![fact.commits.lines_changed])", :client => @client, :project => @project)
    res.should == 9

    res = GoodData::Metric.execute("SELECT SUM(![fact.commits.lines_changed])", :extended_notation => true, :client => @client, :project => @project)
    res.should == 9

    res = GoodData::Metric.execute("SELECT SUM(![fact.commits.lines_changed])", :extended_notation => true, :client => @client, :project => @project)
    res.should == 9

    fact = GoodData::Fact.find_first_by_title('Lines Changed', :client => @client, :project => @project)
    fact.fact?.should == true
    res = fact.create_metric(:type => :sum, :client => @client, :project => @project).execute(:client => @client, :project => @project)
    res.should == 9
  end

  it "should load the data" do
    blueprint = GoodData::Model::ProjectBlueprint.new(@spec)
    devs_data = [
      ["dev_id", "email"],
      [4, "josh@gooddata.com"]]
    GoodData::Model.upload_data(devs_data, blueprint, 'devs', mode: 'INCREMENTAL', :client => @client, :project => @project)
    # blueprint.find_dataset('devs').upload(devs_data, :load => 'INCREMENTAL')
  end

  it "should have more users"  do
    attribute = GoodData::Attribute['attr.devs.dev_id', :client => @client, :project => @project]
    attribute.attribute?.should == true
    attribute.create_metric(:client => @client, :project => @project).execute(:client => @client, :project => @project).should == 4
  end

  it "should tell you whether metric contains a certain attribute" do
    attribute = GoodData::Attribute['attr.devs.dev_id', :client => @client, :project => @project]
    repo_attribute = GoodData::Attribute['attr.repos.repo_id', :client => @client, :project => @project]
    metric = attribute.create_metric(:title => "My test metric", :client => @client, :project => @project)
    metric.save(:client => @client, :project => @project)
    metric.execute(:client => @client, :project => @project).should == 4

    metric.contain?(attribute).should == true
    metric.contain?(repo_attribute).should == false

    metric.replace(attribute, repo_attribute)
    metric.save(:client => @client, :project => @project)
    metric.execute(:client => @client, :project => @project).should_not == 4

    l = attribute.primary_label(:client => @client, :project => @project)
    value = l.values.first[:value]
    l.find_element_value(l.find_value_uri(value)).should == value
    expect(l.value?(value)).to eq true
    expect(l.value?("DEFINITELY NON EXISTENT VALUE HOPEFULLY")).to eq false
  end

  it "should be able to compute count of different datasets" do
    attribute = GoodData::Attribute['attr.devs.dev_id', :client => @client, :project => @project]
    dataset_attribute = GoodData::Attribute['attr.commits.factsof', :client => @client, :project => @project]
    attribute.create_metric(:attribute => dataset_attribute, :client => @client, :project => @project).execute(:client => @client, :project => @project).should == 3
  end

  it "should be able to tell you if a value is contained in a metric" do
    attribute = GoodData::Attribute['attr.devs.dev_id', :client => @client, :project => @project]
    label = attribute.primary_label(:client => @client, :project => @project)
    value = label.values(:client => @client, :project => @project).first
    fact = GoodData::Fact['fact.commits.lines_changed', :client => @client, :project => @project]
    metric = GoodData::Metric.xcreate("SELECT SUM([#{fact.uri}]) WHERE [#{attribute.uri}] = [#{value[:uri]}]", :client => @client, :project => @project)
    metric.contain_value?(label, value[:value]).should == true
  end

  it "should be able to replace the values in a metric" do
    attribute = GoodData::Attribute['attr.devs.dev_id', :client => @client, :project => @project]
    label = attribute.primary_label(:client => @client, :project => @project)
    value = label.values(:client => @client, :project => @project).first
    different_value = label.values[1]
    fact = GoodData::Fact['fact.commits.lines_changed', :client => @client, :project => @project]
    metric = GoodData::Metric.xcreate("SELECT SUM([#{fact.uri}]) WHERE [#{attribute.uri}] = [#{value[:uri]}]", :client => @client, :project => @project)
    metric.replace_value(label, value[:value], different_value[:value])
    metric.contain_value?(label, value[:value]).should == false
    metric.pretty_expression.should == "SELECT SUM([Lines Changed]) WHERE [Dev] = [josh@gooddata.com]"
  end

  it "should be able to lookup the attributes by regexp and return a collection" do
    GoodData.with_project(@project) do |p|
      attrs = GoodData::Attribute.find_by_title(/Date/i, :client => @client, :project => @project)
      attrs.count.should == 1
    end
  end

  it "should be able to give you values of the label as an array of hashes" do
    attribute = GoodData::Attribute['attr.devs.dev_id', :client => @client, :project => @project]
    label = attribute.primary_label(:client => @client, :project => @project)
    label.values(:client => @client).map { |v| v[:value] }.should == [
      'jirka@gooddata.com',
      'josh@gooddata.com',
      'petr@gooddata.com',
      'tomas@gooddata.com'
    ]
  end

  it "should be able to give you values for" do
    attribute = GoodData::Attribute['attr.devs.dev_id', :client => @client, :project => @project]
    attribute.values_for(2, :client => @client, :project => @project).should == ["tomas@gooddata.com", "1"]
  end

  it "should be able to find specific element and give you the primary label value" do
    attribute = GoodData::Attribute['attr.devs.dev_id', :client => @client, :project => @project]
    GoodData::Attribute.find_element_value("#{attribute.uri}/elements?id=2", :client => @client, :project => @project).should == 'tomas@gooddata.com'
  end

  it "should be able to give you label by name" do
    attribute = GoodData::Attribute['attr.devs.dev_id', :client => @client, :project => @project]
    label = attribute.label_by_name('email', :client => @client, :project => @project)
    label.label?.should == true
    label.title.should == 'Email'
    label.identifier.should == "label.devs.dev_id.email"
    label.attribute_uri.should == attribute.uri
    label.attribute(:client => @client, :project => @project).should == attribute
  end

  it "should be able to return values of the attribute for inspection" do
    attribute = GoodData::Attribute['attr.devs.dev_id', :client => @client, :project => @project]
    vals = attribute.values(:client => @client, :project => @project)
    vals.count.should == 4
    vals.first.count.should == 2
    vals.first.first[:value].should == "jirka@gooddata.com"
  end

  it "should be able to save_as a metric" do
    m = GoodData::Metric.find_first_by_title("My test metric", :client => @client, :project => @project)
    cloned = m.save_as(nil, :client => @client, :project => @project)
    m_cloned = GoodData::Metric.find_first_by_title("Clone of My test metric", :client => @client, :project => @project)
    m_cloned.should == cloned
    m_cloned.execute(:client => @client, :project => @project).should == cloned.execute(:client => @client, :project => @project)
  end

  it "should be able to clone a project" do
    title = 'My new clone proejct'
    cloned_project = @project.clone(title: title, auth_token: ConnectionHelper::GD_PROJECT_TOKEN, :client => @client)
    expect(cloned_project.title).to eq title
    cloned_project.delete
  end
end
