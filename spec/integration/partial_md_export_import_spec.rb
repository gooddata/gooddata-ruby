require 'gooddata'

describe "Spin a project", :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection

    spec = MultiJson.load(File.read("./spec/data/test_project_model_spec.json"), :symbolize_keys => true)

    @source_project = GoodData::Model::ProjectCreator.migrate({:spec => spec, :token => ConnectionHelper::GD_PROJECT_TOKEN, :client => @client})
    @target_project = GoodData::Model::ProjectCreator.migrate({:spec => spec, :token => ConnectionHelper::GD_PROJECT_TOKEN, :client => @client})
  end

  after(:all) do
    @source_project.delete unless @source_project.nil?
    @target_project.delete unless @target_project.nil?

    @client.disconnect
  end

  it "should transfer a metric" do
    f = GoodData::Fact.find_first_by_title('Lines Changed', :client => @client, :project => @source_project)
    metric_title = "Testing metric to be exported"
    metric = GoodData::Metric.xcreate("SELECT SUM(#\"#{f.title}\")", :title => metric_title, :client => @client, :project => @source_project)
    metric.save

    GoodData.with_project(@target_project) { |p| GoodData::Metric[:all, :client => @client, :project => @target_project].count.should == 0 }

    @project.partial_md_export([metric.uri], :project => @target_project)
    GoodData.with_project(@target_project) do |p|
      GoodData::Metric[:all].count.should == 1
      metric = GoodData::Metric.find_first_by_title(metric_title)
      metric.should_not be_nil
      metric.title.should == metric_title
    end
  end

end
