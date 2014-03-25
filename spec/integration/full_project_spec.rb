# encoding: UTF-8

require 'gooddata'

describe "Spin a project", :constraint => 'slow' do
  before(:all) do
    spec = JSON.parse(File.read("./spec/data/test_project_model_spec.json"), :symbolize_names => true)
    GoodData.connect("svarovsky+gem_tester@gooddata.com", "jindrisska")

    @project = GoodData::Model::ProjectCreator.migrate({:spec => spec, :token => GD_PROJECT_TOKEN})
  end

  after(:all) do
    @project.delete unless @project.nil?
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

      result = GoodData::ReportDefinition.execute(:title => "My report", :top => [metric], :left => ['label.devs.email'])
      result[1][1].should == 3
      result.include_row?(["jirka@gooddata.com", 5]).should == true
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
    end
  end

end