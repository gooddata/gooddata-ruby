# encoding: UTF-8
require 'gooddata'

include GoodData::Model

describe GoodData::Model::ToManifest do

  before(:each) do
    @spec = JSON.parse(File.read("./spec/data/blueprints/test_project_model_spec.json"), :symbolize_names => true)
    @result = JSON.parse(File.read("./spec/data/manifests/test_project.json"))
  end

  it "should parse the model view and return the blueprint" do
    expect(ToManifest.to_manifest(@spec)).to eq @result
  end

  it 'blueprint can be set with date reference and default format is set' do
    skip('not yet')
    blueprint = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
      p.add_date_dimension("committed_on")

      p.add_dataset("repos") do |d|
        d.add_anchor("repo_id")
        d.add_attribute("name")
        d.add_date('opportunity_comitted', dataset: 'committed_on')
      end
    end
    expect(blueprint.to_manifest.first['dataSetSLIManifest']['parts'][2]['constraints']).to eq ({ "date" => GoodData::Model::DEFAULT_DATE_FORMAT })
  end

  it 'blueprint can be set with date reference and default format is set' do
    skip('not yet')
    blueprint = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
      p.add_date_dimension("committed_on")

      p.add_dataset("repos") do |d|
        d.add_anchor("repo_id")
        d.add_attribute("name")
        d.add_date('opportunity_comitted', dataset: 'committed_on', format: 'yyyy/MM/dd')
      end
    end
    expect(blueprint.to_manifest.first['dataSetSLIManifest']['parts'][2]['constraints']).to eq ({ "date" => "yyyy/MM/dd" })
  end
end
