# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

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
    blueprint = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
      p.add_date_dimension("committed_on")

      p.add_dataset("repos") do |d|
        d.add_anchor("repo_id")
        d.add_attribute("name")
        d.add_date('opportunity_comitted', dataset: 'committed_on')
      end
    end
    expect(blueprint.to_manifest.first['dataSetSLIManifest']['parts'][0]['constraints']).to eq ({ "date" => GoodData::Model::DEFAULT_DATE_FORMAT })
  end

  it 'blueprint can be set with date reference and default format is set' do
    blueprint = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
      p.add_date_dimension("committed_on")

      p.add_dataset("repos") do |d|
        d.add_anchor("repo_id")
        d.add_attribute("name")
        d.add_date('opportunity_comitted', dataset: 'committed_on', format: 'yyyy/MM/dd')
      end
    end
    expect(blueprint.to_manifest.first['dataSetSLIManifest']['parts'][0]['constraints']).to eq ({ "date" => "yyyy/MM/dd" })
  end

  it 'blueprint can handle date fact during creation of manifest' do
    blueprint = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
      p.add_date_dimension("committed_on")

      p.add_dataset("repos") do |d|
        d.add_anchor("repo_id")
        d.add_label("repo_label", reference: "repo_id")
        d.add_attribute("name")
        d.add_label("name_label", reference: "name")
        d.add_date('opportunity_comitted', dataset: 'committed_on', format: 'yyyy/MM/dd')
        d.add_column(type: :date_fact, id: 'dt.date_fact')
      end
    end
    expect(blueprint.to_manifest.first['dataSetSLIManifest']['parts'].count).to eq 4
  end

  it 'blueprint can be specified to have a reference key. The manifest respects it. If not it takes the first key.' do
    blueprint = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
      p.add_date_dimension("committed_on")

      p.add_dataset("repos") do |d|
        d.add_anchor("repo_id")
        d.add_label("repo_label_1", reference: "repo_id")
        d.add_label("repo_label_2", reference: "repo_id")
        d.add_attribute("name")
        d.add_label("name_label", reference: "name")

        d.add_date('opportunity_comitted', dataset: 'committed_on', format: 'yyyy/MM/dd')
        d.add_column(type: :date_fact, id: 'dt.date_fact')
      end
    end
    expect(blueprint.to_manifest.first['dataSetSLIManifest']['parts']).to include({"referenceKey"=>1, "populates"=>["repo_label_1"], "mode"=>"FULL", "columnName"=>"repo_label_1"})

    blueprint = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
      p.add_date_dimension("committed_on")

      p.add_dataset("repos") do |d|
        d.add_anchor("repo_id")
        d.add_label("repo_label_1", reference: "repo_id")
        d.add_label("repo_label_2", reference: "repo_id", reference_label: true)
        d.add_attribute("name")
        d.add_label("name_label", reference: "name")

        d.add_date('opportunity_comitted', dataset: 'committed_on', format: 'yyyy/MM/dd')
      end

      p.add_dataset("commits") do |d|
        d.add_anchor("commits_id")
        d.add_fact('lines')
        d.add_reference('repos')
      end
    end

    expect(blueprint.to_manifest.first['dataSetSLIManifest']['parts']).to include({"referenceKey"=>1, "populates"=>["repo_label_2"], "mode"=>"FULL", "columnName"=>"repo_label_2"})
    expect(blueprint.to_manifest[1]['dataSetSLIManifest']['parts']).to include({"populates"=>["repo_label_2"], "mode"=>"FULL", "columnName"=>"repos", "referenceKey"=>1})
  end

  it 'blueprint cannot have more than one reference key.' do
    blueprint = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
      p.add_date_dimension("committed_on")

      p.add_dataset("repos") do |d|
        d.add_anchor("repo_id")
        d.add_label("repo_label_1", reference: "repo_id", reference_label: true)
        d.add_label("repo_label_2", reference: "repo_id", reference_label: true)
        d.add_attribute("name")
        d.add_label("name_label", reference: "name")

        d.add_date('opportunity_comitted', dataset: 'committed_on', format: 'yyyy/MM/dd')
        d.add_column(type: :date_fact, id: 'dt.date_fact')
      end
    end
    
    expect(blueprint.valid?).to be false
    expect(blueprint.validate).to eq [
      {
        type: :error,
        message: "Anchor \"repo_id\" can have only one label with reference_label field set to true"
      }
    ]
  end
  
end
