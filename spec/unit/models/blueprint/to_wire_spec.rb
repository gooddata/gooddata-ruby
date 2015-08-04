# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

include GoodData::Model

describe GoodData::Model::ProjectBlueprint do

  before(:each) do
    @spec = JSON.parse(File.read("./spec/data/blueprints/big_blueprint_not_pruned.json"), :symbolize_names => true)
    @blueprint = GoodData::Model::ProjectBlueprint.new(@spec)
    @wire_spec = JSON.parse(File.read("./spec/data/wire_models/model_view.json"), :symbolize_names => true)
  end

  describe '#to_wire' do
    it 'should transform small spec to wire' do
      spec = JSON.parse(File.read("./spec/data/blueprints/test_blueprint.json"), :symbolize_names => true)
      wire_spec = JSON.parse(File.read("./spec/data/wire_models/test_blueprint.json"), :symbolize_names => true)
      res = ToWire.to_wire(spec)
      expect(res).to eq wire_spec
    end

    it 'it should turn into wire another project' do
      spec = JSON.parse(File.read("./spec/data/blueprints/test_project_model_spec.json"), :symbolize_names => true)
      res = ToWire.to_wire(spec)
    end

    it 'should create manifest' do
      spec = JSON.parse(File.read("./spec/data/blueprints/test_blueprint.json"), :symbolize_names => true)
      wire_spec = JSON.parse(File.read("./spec/data/wire_models/test_blueprint.json"), :symbolize_names => true)
      manifest_spec = JSON.parse(File.read("./spec/data/manifests/test_blueprint.json"))
      expect(ToWire.to_wire(spec)).to eq wire_spec
    end
  end

  describe '#anchor_to_wire' do
    it 'should generate anchor without label.' do
      dataset = ProjectBlueprint.find_dataset(@spec, 'dataset.stage_history')

      result = ToWire.anchor_to_wire(@spec, dataset)
      expect(result).to eq ({
        attribute: {
          identifier: "attr.dataset.stage_history.factsof",
          title: "Records of stage_history",
          folder: "stage_history"}})
    end

    it 'should generate anchor with label' do
      dataset = ProjectBlueprint.find_dataset(@spec, 'dataset.opportunityanalysis')
      result = ToWire.anchor_to_wire(nil, dataset)
      expect(result).to eq ({
        attribute: {
          :identifier=>"attr.opportunityanalysis.techoppanalysis",
          :title=>"Tech Opp. Analysis",
          :folder=>"Opportunity Benchmark",
          :labels=>[
            {:label=>
             {:identifier=>"label.opportunityanalysis.techoppanalysis",
              :title=>"Tech Opp. Analysis",
              :type=>"GDC.text",
              :dataType=>"VARCHAR(128)"}}],
          :defaultLabel=>"label.opportunityanalysis.techoppanalysis"}})
    end
  end

  describe '#anchor_to_attribute' do
    it 'should generate attribute without label' do
      dataset = ProjectBlueprint.find_dataset(@spec, 'dataset.stage_history')
      a = DatasetBlueprint.attributes(dataset).find {|a| a[:id] == 'attr.stage_history.currentstatus'}
      result = ToWire.attribute_to_wire(dataset, a)
      expect(result).to eq ({
        :attribute=>
        {:identifier=>"attr.stage_history.currentstatus",
         :title=>"Current Stage",
         :folder=>"stage_history",
         :labels=>
          [{:label=>
             {:identifier=>"label.stage_history.currentstatus",
              :title=>"Current Stage",
              :type=>"GDC.text",
              :dataType=>"VARCHAR(128)"}}],
          :defaultLabel=>"label.stage_history.currentstatus"}})
    end

    it 'should generate attributes with label' do
      dataset = ProjectBlueprint.find_dataset(@spec, 'dataset.opportunityanalysis')
      a = DatasetBlueprint.attributes(dataset).find {|a| a[:id] == 'attr.opportunityanalysis.month'}

      result = ToWire.attribute_to_wire(dataset, a)
      expect(result).to eq ({:attribute=>
        {:identifier=>"attr.opportunityanalysis.month",
         :title=>"Month",
         :folder=>"Opportunity Benchmark",
         :labels=>
          [{:label=>
             {:identifier=>"label.opportunityanalysis.month",
              :title=>"Month",
              :type=>"GDC.text",
              :dataType=>"VARCHAR(128)"}},
           {:label=>
             {:identifier=>"label.opportunityanalysis.month.monthsortingnew",
              :title=>"MonthSortingNew",
              :type=>"GDC.text",
              :dataType=>"INT"}}],
          :defaultLabel=>"label.opportunityanalysis.month" }})
    end
  end

  describe '#fact_to_wire' do
    it 'should generate anchor' do
      fact_def = {
        type: "fact",
        id: "fact.stage_history.stage_velocity",
        title: "Stage Velocity",
        folder: "My Folder",
        description: "Velocity description",
        gd_data_type: "DECIMAL(12,2)"
      }
      result = ToWire.fact_to_wire(nil, fact_def)
      expect(result).to eq ({
        fact: {
          identifier: "fact.stage_history.stage_velocity",
          title: "Stage Velocity",
          dataType: "DECIMAL(12,2)",
          folder: "My Folder",
          description: "Velocity description"}})
    end
  end

  describe '#references_to_wire' do
    it 'should produce references' do
      dataset = ProjectBlueprint.find_dataset(@spec, 'dataset.opp_snapshot')
      res = ToWire.references_to_wire(@spec, dataset)
      expect(res).to eq [
        "dataset.sdrowner",
        "dataset.leadsourceoriginal",
        "dataset.account",
        "dataset.amounttype",
        "dataset.product",
        "dataset.sourcingorigin",
        "dataset.leadsource",
        "dataset.productline",
        "dataset.stage",
        "dataset.opp_owner",
        "dataset.opportunity",
        "dataset.bookingtype",
        "dataset.forecast",
        "leadcreate",
        "snapshot",
        "oppclose",
        "oppcreated",
        "stage1plus",
        "mqldate",
        "effectivecontractstart",
        "effectivecontractend"
      ]
    end
  end

  describe '#date_dimension_to_wire' do
    it 'should be able to generate date dimension' do
      res = ToWire.date_dimension_to_wire(@spec, {
        type: "date_dimension",
        id: "timeline",
        title: "Timeline"
      })
      expect(res).to eq({:dateDimension=>{:name=>"timeline", :title=>"Timeline"}})
    end
  end
end
