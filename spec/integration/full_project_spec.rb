require 'gooddata'

describe "Full project implementation", :constraint => 'slow' do
  before(:all) do
    ConnectionHelper.create_default_connection

    @spec = JSON.parse(File.read("./spec/data/test_project_model_spec.json"), :symbolize_names => true)
    @invalid_spec = JSON.parse(File.read("./spec/data/blueprint_invalid.json"), :symbolize_names => true)

    @project = GoodData::Model::ProjectCreator.migrate({:spec => @spec, :token => ConnectionHelper::GD_PROJECT_TOKEN})
  end

  after(:all) do
    @project.delete unless @project.nil?

    ConnectionHelper.disconnect
  end

  it "should not build an invalid model" do
    expect {
      GoodData::Model::ProjectCreator.migrate({:spec => @invalid_spec, :token => ConnectionHelper::GD_PROJECT_TOKEN})
    }.to raise_error(GoodData::ValidationError)
  end

  it "should contain datasets" do
    GoodData.with_project(@project) do |p|
      p.datasets.count.should == 4
    end
  end

  it "should compute an empty metric" do
    GoodData.with_project(@project) do |p|
      f = GoodData::Fact.find_first_by_title('Lines changed')
      metric = GoodData::Metric.xcreate("SELECT SUM(#\"#{f.title}\")")
      metric.execute.should be_nil
    end
  end

  it "should load the data" do
    GoodData.with_project(@project) do |p|
      blueprint = GoodData::Model::ProjectBlueprint.new(@spec)
      commits_data = [
        ["lines_changed","committed_on","dev_id","repo_id"],
        [1,"01/01/2014",1,1],
        [3,"01/02/2014",2,2],
        [5,"05/02/2014",3,1]]
      blueprint.find_dataset('commits').upload(commits_data)

      devs_data = [
        ["dev_id", "email"],
        [1, "tomas@gooddata.com"],
        [2, "petr@gooddata.com"],
        [3, "jirka@gooddata.com"]]
      blueprint.find_dataset('devs').upload(devs_data)
    end
  end

  it "should compute a metric" do
    GoodData.with_project(@project) do |p|
      f = GoodData::Fact.find_first_by_title('Lines changed')
      metric = GoodData::Metric.xcreate("SELECT SUM(#\"#{f.title}\")")
      metric.execute.should == 9
    end
  end

  it "should execute an anonymous metric twice and not fail" do
    GoodData.with_project(@project) do |p|
      f = GoodData::Fact.find_first_by_title('Lines changed')
      metric = GoodData::Metric.xcreate("SELECT SUM(#\"#{f.title}\")")
      metric.execute.should == 9
      # Since GD platform cannot execute inline specified metric the metric has to be saved
      # The code tries to resolve this as transparently as possible
      metric.execute.should == 9
    end
  end

  it "should compute a report" do
    GoodData.with_project(@project) do |p|
      f = GoodData::Fact.find_first_by_title('Lines changed')
      metric = GoodData::Metric.xcreate(:title => "My metric", :expression => "SELECT SUM(#\"#{f.title}\")")
      metric.save
      result = GoodData::ReportDefinition.execute(:title => "My report", :top => [metric], :left => ['label.devs.dev_id.email'])
      result[1][1].should == 3
      result.include_row?(["jirka@gooddata.com", 5]).should == true

      result2 = GoodData::ReportDefinition.create(:title => "My report", :top => [metric], :left => ['label.devs.dev_id.email']).execute
      result2[1][1].should == 3
      result2.include_row?(["jirka@gooddata.com", 5]).should == true
      result2.should == result
    end
  end

  it "should throw an exception if trying to access object without explicitely specifying a project" do
    expect do
      GoodData::Metric[:all]
    end.to raise_exception(GoodData::NoProjectError)
  end

  it "should be possible to get all metrics" do
    GoodData.with_project(@project) do |p|
      metrics1 = GoodData::Metric[:all]
      metrics2 = GoodData::Metric.all
      metrics1.should == metrics2
    end
  end

  it "should be possible to get all metrics with full objects" do
    GoodData.with_project(@project) do |p|
      metrics1 = GoodData::Metric[:all, :full => true]
      metrics2 = GoodData::Metric.all :full => true
      metrics1.should == metrics2
    end
  end

  it "should be able to get a metric by identifier" do
    GoodData.with_project(@project) do |p|
      metrics = GoodData::Metric.all :full => true
      metric = GoodData::Metric[metrics.first.identifier]
      metric.identifier == metrics.first.identifier
      metrics.first == metric
    end
  end

  it "should be able to get a metric by uri" do
    GoodData.with_project(@project) do |p|
      metrics = GoodData::Metric.all :full => true
      metric = GoodData::Metric[metrics.first.uri]
      metric.uri == metrics.first.uri
      metrics.first == metric
    end
  end

  it "should be able to get a metric by object id" do
    GoodData.with_project(@project) do |p|
      metrics = GoodData::Metric.all :full => true
      metric = GoodData::Metric[metrics.first.obj_id]
      metric.obj_id == metrics.first.obj_id
      metrics.first == metric
    end
  end

  it "should exercise the object relations and getting them in various ways" do
    GoodData.with_project(@project) do |p|

      # Find a metric by name
      metric = GoodData::Metric.find_first_by_title('My metric')

      # grab fact in several different ways
      fact1 = GoodData::Fact.find_first_by_title('Lines changed')
      fact2 = GoodData::Fact[fact1.identifier]
      fact3 = GoodData::Fact[fact2.obj_id]
      fact4 = GoodData::Fact[fact3.uri]
      fact5 = GoodData::Fact.new(fact4)

      # All should be the same
      fact1.should == fact2
      fact1.should == fact2
      fact1.should == fact3
      fact1.should == fact4
      fact1.should == fact5

      fact3.title = "Somewhat changed title"
      fact1.should_not == fact3

      metric.using
      metric.using('fact').count.should == 1

      fact1.used_by
      fact1.used_by('metric').count.should == 1

      metric.using?(fact1).should == true
      fact1.using?(metric).should == false

      metric.used_by?(fact1).should == false
      fact1.used_by?(metric).should == true
    end
  end

  it "should try setting and getting by tags" do
    GoodData.with_project(@project) do |p|
      fact = GoodData::Fact.find_first_by_title('Lines changed')
      fact.tags.should be_empty

      fact.tags = "tag1,tag2,tag3"
      fact.save

      tagged_facts = GoodData::Fact.find_by_tag('tag3')
      tagged_facts.count.should == 1
    end
  end

  it "should contain metadata for each dataset in project metadata" do
    GoodData.with_project(@project) do |p|
      k = GoodData::ProjectMetadata.keys
      k.should include("manifest_devs")
    end
  end

  it "should be able to interpolate metric based on" do
    GoodData.with_project(@project) do |p|
      res = GoodData::Metric.xexecute "SELECT SUM(![fact.commits.lines_changed])"
      res.should == 9

      res = GoodData::Metric.xexecute({:expression => "SELECT SUM(![fact.commits.lines_changed])"})
      res.should == 9

      res = GoodData::Metric.execute({:expression => "SELECT SUM(![fact.commits.lines_changed])", :extended_notation => true})
      res.should == 9

      res = GoodData::Metric.execute("SELECT SUM(![fact.commits.lines_changed])", :extended_notation => true)
      res.should == 9

      fact = GoodData::Fact.find_first_by_title('Lines changed')
      fact.fact?.should == true
      res = fact.create_metric(:type => :sum).execute
      res.should == 9
    end
  end

  it "should load the data" do
    GoodData.with_project(@project) do |p|
      blueprint = GoodData::Model::ProjectBlueprint.new(@spec)
      devs_data = [
        ["dev_id", "email"],
        [4, "josh@gooddata.com"]]
      blueprint.find_dataset('devs').upload(devs_data, :load => 'INCREMENTAL')
    end
  end

  it "should have more users"  do
    GoodData.with_project(@project) do |p|
      attribute = GoodData::Attribute['attr.devs.dev_id']
      attribute.attribute?.should == true
      attribute.create_metric.execute.should == 4
    end
  end

  it "should tell you whether metric contains a certain attribute" do
    GoodData.with_project(@project) do |p|
      attribute = GoodData::Attribute['attr.devs.dev_id']
      repo_attribute = GoodData::Attribute['attr.repos.repo_id']
      metric = attribute.create_metric(:title => "My test metric")
      metric.save
      metric.execute.should == 4

      metric.contain?(attribute).should == true
      metric.contain?(repo_attribute).should == false

      metric.replace(attribute, repo_attribute)
      metric.save
      metric.execute.should_not == 4

      l = attribute.primary_label
      value = l.values.first[:value]
      l.find_element_value(l.find_value_uri(value)).should == value
    end
  end

  it "Should be able to compute count o different datasets" do
    GoodData.with_project(@project) do |p|
      attribute = GoodData::Attribute['attr.devs.dev_id']
      dataset_attribute = GoodData::Attribute['attr.commits.id']
      attribute.create_metric(:attribute => dataset_attribute).execute.should == 3
    end
  end

  it "should be able to tell you if a value is contained in a metric" do
    GoodData.with_project(@project) do |p|
      attribute = GoodData::Attribute['attr.devs.dev_id']
      label = attribute.primary_label
      value = label.values.first
      fact = GoodData::Fact['fact.commits.lines_changed']
      metric = GoodData::Metric.xcreate("SELECT SUM([#{fact.uri}]) WHERE [#{attribute.uri}] = [#{value[:uri]}]")
      metric.contain_value?(label, value[:value]).should == true
    end
  end

  it "should be able to replace the values in a metric" do
    GoodData.with_project(@project) do |p|
      attribute = GoodData::Attribute['attr.devs.dev_id']
      label = attribute.primary_label
      value = label.values.first
      different_value = label.values[1]
      fact = GoodData::Fact['fact.commits.lines_changed']
      metric = GoodData::Metric.xcreate("SELECT SUM([#{fact.uri}]) WHERE [#{attribute.uri}] = [#{value[:uri]}]")
      metric.replace_value(label, value[:value], different_value[:value])
      metric.contain_value?(label, value[:value]).should == false
      metric.pretty_expression.should == "SELECT SUM([Lines changed]) WHERE [Dev] = [josh@gooddata.com]"
    end
  end

  it "should be able to lookup the attributes by regexp and return a collection" do
    GoodData.with_project(@project) do |p|
      attrs = GoodData::Attribute.find_by_title(/Date/i)
      attrs.count.should == 1
    end
  end

  it "should be able to give you values of the label as an array of hashes" do
    GoodData.with_project(@project) do |p|
      attribute = GoodData::Attribute['attr.devs.dev_id']
      label = attribute.primary_label
      label.values.map {|v| v[:value]}.should == [
        'jirka@gooddata.com',
        'josh@gooddata.com',
        'petr@gooddata.com',
        'tomas@gooddata.com'
      ]
    end
  end

  it "should be able to give you values for" do
    GoodData.with_project(@project) do |p|
      attribute = GoodData::Attribute['attr.devs.dev_id']
      attribute.values_for(2).should == ["tomas@gooddata.com", "1"]
    end
  end

  it "should be able to find specific element and give you the primary label value" do
    GoodData.with_project(@project) do |p|
      attribute = GoodData::Attribute['attr.devs.dev_id']
      GoodData::Attribute.find_element_value("#{attribute.uri}/elements?id=2").should == 'tomas@gooddata.com'
    end
  end

  it "should be able to give you label by name" do
    GoodData.with_project(@project) do |p|
      attribute = GoodData::Attribute['attr.devs.dev_id']
      label = attribute.label_by_name('email')
      label.label?.should == true
      label.title.should == 'Email'
      label.identifier.should == "label.devs.dev_id.email"
      label.attribute_uri.should == attribute.uri
      label.attribute.should == attribute
    end
  end

  it "should be able to return values of the attribute for inspection" do
    GoodData.with_project(@project) do |p|
      attribute = GoodData::Attribute['attr.devs.dev_id']
      vals = attribute.values
      vals.count.should == 4
      vals.first.count.should == 2
      vals.first.first[:value].should == "jirka@gooddata.com"
    end
  end

  it "should be able to save_as a metric" do
    GoodData.with_project(@project) do |p|
      m = GoodData::Metric.find_first_by_title("My test metric")
      cloned = m.save_as
      m_cloned = GoodData::Metric.find_first_by_title("Clone of My test metric")
      m_cloned.should == cloned
      m_cloned.execute.should == cloned.execute
    end
  end
end
