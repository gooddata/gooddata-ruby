require 'gooddata'

describe 'Create project using GoodData client', :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
  end

  after(:all) do
    @client.disconnect
  end

  it 'Should create project using GoodData::Rest::Client#create_project' do
    project_title = 'Test #create_project'
    project = @client.create_project(:title => project_title, :auth_token => ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
    expect(project.title).to eq(project_title)
    project.delete
  end
end
