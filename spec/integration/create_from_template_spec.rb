require 'gooddata'

describe "Spin a project from template", :constraint => 'slow' do
  before(:all) do
    GoodData.connect("svarovsky+gem_tester@gooddata.com", "jindrisska")
  end

  it "should spin a project from a template that does not exist. It should throw an error" do
    expect{GoodData::Project.create(:title => "Test project", :template => "/some/nonexisting/tempalte/uri", :auth_token => ENV['GD_PROJECT_TOKEN'])}.to raise_error
  end

end