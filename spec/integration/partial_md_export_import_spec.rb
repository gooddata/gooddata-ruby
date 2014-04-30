require 'gooddata'

describe "Spin a project", :constraint => 'slow' do
  before(:all) do
    spec = MultiJson.load(File.read("./spec/data/test_project_model_spec.json"), :symbolize_keys => true)
    ConnectionHelper::create_default_connection

    @source_project = GoodData::Model::ProjectCreator.migrate({:spec => spec, :token => ConnectionHelper::GD_PROJECT_TOKEN})
    @target_project = GoodData::Model::ProjectCreator.migrate({:spec => spec, :token => ConnectionHelper::GD_PROJECT_TOKEN})
  end

  after(:all) do
    @source_project.delete unless @source_project.nil?
    @target_project.delete unless @target_project.nil?
  end

  it "should transfer a metric" do
    GoodData.with_project(@source_project) do |p|
      f = GoodData::Fact.find_first_by_title('Lines changed')
      metric_title = "Testing metric to be exported"
      metric = GoodData::Metric.xcreate(:expression => "SELECT SUM(#\"#{f.title}\")", :title => metric_title)
      metric.save

      GoodData.with_project(@target_project) {|p| GoodData::Metric[:all].count.should == 0}
      p.partial_md_export([metric.uri], :project => @target_project)
      GoodData.with_project(@target_project) do |p|
        GoodData::Metric[:all].count.should == 1
        metric = GoodData::Metric.find_first_by_title(metric_title)
        metric.should_not be_nil
        metric.title.should == metric_title
      end

    end
  end

end
