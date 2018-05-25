require 'gooddata'

describe GoodData::Metric, :vcr do
  before(:all) do
    @rest_client = ConnectionHelper.create_default_connection
    @project, * = ProjectHelper.load_full_project_implementation(@rest_client)
    @folder = GoodData::Folder.create(project: @project, client: @rest_client, title: 'aaa', type: 'metric')
    @folder.save.reload!
    @metric = @project.attributes.to_a.first.create_metric
    @metric.save.reload!
  end

  it 'should be able to update folders' do
    @metric.folders = [@folder.uri]
    @metric.save.reload!
    expect(@metric.folders).to eq([@folder.uri])
  end

  after(:all) do
    @metric.delete if @metric
    @folder.delete if @folder
    @project.delete if @project
  end
end
