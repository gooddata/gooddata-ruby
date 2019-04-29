require 'gooddata'

describe GoodData::Metric, :vcr do
  before(:all) do
    @rest_client = ConnectionHelper.create_default_connection
    @project, * = ProjectHelper.load_full_project_implementation(@rest_client)
    @folder = GoodData::Folder.create(project: @project, client: @rest_client, title: 'aaa', type: 'metric')
    @folder.save.reload!
    @attribute = @project.attributes.to_a.first
    @metric = @attribute.create_metric
    @metric.save.reload!
  end

  it 'should be able to update folders' do
    @metric.folders = [@folder.uri]
    @metric.save.reload!
    expect(@metric.folders).to eq([@folder.uri])
  end

  it 'should accept number format in constructor' do
    metric = @project.create_metric("SELECT COUNT([#{@attribute.uri}])", title: 'Title', format: '#,##0%')
    metric.save
    expect(metric.format).to eq('#,##0%')
  end

  after(:all) do
    @metric.delete if @metric
    @folder.delete if @folder
    @project.delete if @project
  end

  it 'should allow updating metric format' do
    metric = @project.create_metric("SELECT COUNT([#{@attribute.uri}])", title: 'Title')
    metric.save
    metric.format = '#,##0%'
    metric.save
    expect(metric.format).to eq('#,##0%')
  end
end
