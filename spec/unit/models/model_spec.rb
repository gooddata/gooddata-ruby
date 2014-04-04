# encoding: UTF-8

require 'pry'
require 'gooddata/models/model'

describe GoodData::Model do

  before(:each) do
    @base_blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/test_project_model_spec.json")
    @additional_blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/model_module.json")

    @blueprint_with_duplicate = GoodData::Model::ProjectBlueprint.new(
        {
            :title => "x",
            :datasets => [
                {
                    :name => "commits",
                    :columns => [
                        {:type => "fact", :name => "lines_changed"}
                    ]
                }
            ]})

    @conflicting_blueprint = GoodData::Model::ProjectBlueprint.new(
        {
            :title => "x",
            :datasets => [
                {
                    :name => "commits",
                    :columns => [
                        {:type => "attribute", :name => "lines_changed"}
                    ]
                }
            ]})
  end

  it "should be possible to merge Schema blueprints" do
    first_dataset = @base_blueprint.get_dataset("devs").to_hash
    additional_blueprint = @additional_blueprint.get_dataset("devs").to_hash
    stuff = GoodData::Model.merge_dataset_columns(first_dataset, additional_blueprint)
    stuff[:columns].include?({:type => "attribute", :name => "region"}).should == true
    stuff[:columns].include?({:type => "anchor", :name => "id"}).should == true
  end

  it "should pass when merging 2 columns with the same name if both columns are identical" do
    first_dataset = @base_blueprint.get_dataset("commits").to_hash
    additional_blueprint = @blueprint_with_duplicate.get_dataset("commits").to_hash

    stuff = GoodData::Model.merge_dataset_columns(first_dataset, additional_blueprint)

    stuff[:columns].count.should == 4
    stuff[:columns].include?({:type => "fact", :name => "lines_changed"}).should == true
    stuff[:columns].group_by { |col| col[:name] }["lines_changed"].count.should == 1
  end

  it "should pass when merging 2 columns with the same name if all attributes are identical" do
    first_dataset = @base_blueprint.get_dataset("commits").to_hash
    additional_blueprint = @conflicting_blueprint.get_dataset("commits").to_hash

    expect { GoodData::Model.merge_dataset_columns(first_dataset, additional_blueprint) }.to raise_error
  end

  it "should be possible to merge directly whole bleuprints. Blueprint is changed in place when merge! is used" do
    @base_blueprint.merge!(@additional_blueprint)
    @base_blueprint.get_dataset("repos").attributes.include?({:type => "attribute", :name => "department"})
  end

end