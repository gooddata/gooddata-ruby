require 'gooddata'

describe "Object export between projects", :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection

    spec = MultiJson.load(File.read("./spec/data/blueprints/test_project_model_spec.json"), :symbolize_keys => true)
    
    @source_project = @client.create_project_from_blueprint(spec, token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
    @target_project = @client.create_project_from_blueprint(spec, token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
  end

  after(:all) do
    @source_project.delete unless @source_project.nil?
    @target_project.delete unless @target_project.nil?

    @client.disconnect
  end

  it "should transfer a metric" do
    f = GoodData::Fact.find_first_by_title('Lines Changed', :client => @client, :project => @source_project)
    metric_title = "Testing metric to be exported"
    metric = @source_project.create_metric("SELECT SUM(#\"#{f.title}\")", :title => metric_title)
    metric.save

    @target_project.metrics.count.should == 0

    @source_project.partial_md_export(metric, :project => @target_project)

    expect(@target_project.metrics.count).to eq 1
    metric = GoodData::Metric.find_first_by_title(metric_title, :client => @client, :project => @target_project)
    expect(metric).not_to be_nil
    expect(metric.title).to eq metric_title
  end

end
