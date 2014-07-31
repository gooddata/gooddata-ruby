# encoding: UTF-8
require 'gooddata'

include GoodData::Model

describe GoodData::Model::ToManifest do

  before(:each) do
    @spec = JSON.parse(File.read("./spec/data/test_project_model_spec.json"), :symbolize_names => true)
    @result = JSON.parse(File.read("./spec/data/manifest_test_project.json"))
  end

  it "should parse the model view and return the blueprint" do
    expect(ToManifest.to_manifest(@spec)).to eq @result
  end
end
