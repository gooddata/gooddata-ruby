# encoding: UTF-8
require 'gooddata'

include GoodData::Model

describe GoodData::Model::ProjectBlueprint do

  before(:each) do
    @spec = JSON.parse(File.read("./spec/data/test_project_model_spec.json"), :symbolize_names => true)
    @result = JSON.parse(File.read("./spec/data/wire_test_project.json"), :symbolize_names => true)
  end

  it "should parse the model view and return the blueprint" do
    expect(ToWire.to_wire(@spec)).to eq @result
  end

  it "should generate anchor" do

    dataset_with_anchor = {
      type: "dataset",
      name: "repos",
      columns: [{ type: "anchor", name: "repo_id"}]}

    dataset_without_anchor = {
      type: "dataset",
      name: "repos",
      columns: [{ type: "attribute", name: "repo_id"}]}

    res = ToWire.anchor_to_wire(@spec, dataset_without_anchor)
    expect(res).to eq({ attribute: { identifier: 'attr.repos.factsof', title: 'Records of Repos', folder: 'Repos' }})

    res = ToWire.anchor_to_wire(@spec, dataset_with_anchor)
    expect(res).to eq({:attribute=>
      {:identifier=>"attr.repos.repo_id",
       :title=>"Repo",
       :folder => 'Repos',
       :labels=>
        [{:label=>
           {:identifier=>"label.repos.repo_id",
            :title=>"Repo",
            :type=>nil,
            :dataType=>nil}}],
       :defaultLabel=>"label.repos.repo_id"}})
  end

  it "should parse the model view and return the blueprint" do
    fact_table = {
      :type=>"dataset",
      :name=>"commits",
      :columns=>
       [{:type=>"reference",
         :name=>"dev_id",
         :dataset=>"devs",
         :reference=>"dev_id"}]}
    expect(ToWire.references_to_wire(@spec, fact_table)).to eq ["dataset.devs"]

    fact_table = {
      :type=>"dataset",
      :name=>"commits",
      :columns=>
       [{:type=>"date", :name=>"committed_on", :dataset=>"committed_on"}]}
    expect(ToWire.references_to_wire(@spec, fact_table)).to eq ["committed_on"]
  end
end
