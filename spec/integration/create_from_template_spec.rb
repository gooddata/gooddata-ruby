require 'gooddata'

describe "Spin a project from template", :constraint => 'slow' do
  before(:all) do
    ConnectionHelper::create_default_connection
  end

  it "should spin a project from a template that does not exist. It should throw an error" do
    expect{GoodData::Project.create(:title => "Test project", :template => "/some/nonexisting/template/uri", :auth_token => ConnectionHelper::GD_PROJECT_TOKEN)}.to raise_error
  end

end