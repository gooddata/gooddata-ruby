# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pry'
require 'gooddata/models/model'

describe GoodData::Model do

  before(:each) do
    @base_blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/blueprints/test_project_model_spec.json")
    @additional_blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/blueprints/model_module.json")

    @blueprint_with_duplicate = GoodData::Model::ProjectBlueprint.new(
      {
        title: "x",
        datasets: [{
          id: "dataset.commits",
          type: :dataset,
          columns: [
            {
              type: "fact",
              id: "fact.lines_changed",
              gd_data_type: 'INT',
              description: "Fact description"
            }
          ]
        }]
      })

    @conflicting_blueprint = GoodData::Model::ProjectBlueprint.new(
      {
        title: 'x',
        datasets: [{
          type: :dataset,
          id: 'dataset.commits',
          columns: [
            {
              type: 'fact',
              id: 'fact.commits.lines_changed'
            }
          ]
        }]
      })
  end

  it "should be possible to merge Schema blueprints" do
    
    first_dataset = @base_blueprint.find_dataset("dataset.devs").to_hash
    additional_blueprint = @additional_blueprint.find_dataset("dataset.devs").to_hash
    stuff = GoodData::Model.merge_dataset_columns(first_dataset, additional_blueprint)
    expect(GoodData::Model::ProjectBlueprint.new(stuff)).to be_valid

    expect(stuff[:columns].include?({:type => :attribute, :id => "attr.region"})).to be_truthy
    expect(stuff[:columns].include?({:type => :anchor, :id => "attr.devs.dev_id", title: 'Dev', :folder=>"Anchor folder" })).to be_truthy
  end

  it "should pass when merging 2 columns with the same name if both columns are identical" do
    first_dataset = @base_blueprint.find_dataset("dataset.commits").to_hash
    additional_blueprint = @blueprint_with_duplicate.find_dataset("dataset.commits").to_hash
    stuff = GoodData::Model.merge_dataset_columns(first_dataset, additional_blueprint)
    
    expect(GoodData::Model::ProjectBlueprint.new(stuff)).to be_valid

    expect(stuff[:columns].count).to eq 6
    expect(stuff[:columns].include?({ type: :fact, id: "fact.lines_changed", gd_data_type: 'INT', description: "Fact description"})).to be_truthy
    expect(stuff[:columns].group_by { |col| col[:id] }["fact.lines_changed"].count).to eq 1
  end

  it "should fail when merging" do
    first_dataset = @base_blueprint.find_dataset("dataset.commits").to_hash
    additional_blueprint = @conflicting_blueprint.find_dataset("dataset.commits").to_hash
    expect { GoodData::Model.merge_dataset_columns(first_dataset, additional_blueprint) }.to raise_error
  end

  it "should be possible to merge directly whole bleuprints. Blueprint is changed in place when merge! is used" do
    @base_blueprint.merge!(@additional_blueprint)
    @base_blueprint.find_dataset("dataset.repos").attributes.include?({ type: "attribute", id: "some_attr_id", :title=>"Repository Name" })
  end
end
