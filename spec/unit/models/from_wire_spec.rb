# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

include GoodData::Model

describe GoodData::Model::FromWire do

  before(:each) do
    @model_view = MultiJson.load(File.read('./spec/data/wire_models/model_view.json'))
    @blueprint = FromWire.from_wire(@model_view)
  end

  describe '#parse_label' do
    it "should be able to parse the attribute" do
      model = @model_view['projectModelView']['model']['projectModel']['datasets'][3]
      a = FromWire.parse_attribute(model['dataset']['attributes'].first['attribute'])
      expect(a.to_set).to eq Set.new([
        {
          type: :attribute,
          id: "attr.opportunityanalysis.month",
          title: "Month",
          folder: "Opportunity Benchmark",
          description: nil,
        },
        {
          type: :label,
          id: "label.opportunityanalysis.month",
          reference: "attr.opportunityanalysis.month",
          title: "Month",
          gd_data_type: "VARCHAR(128)",
          gd_type: "GDC.text",
          default_label: true
        },
        {
          type: :label,
          id: "label.opportunityanalysis.month.monthsortingnew",
          reference: "attr.opportunityanalysis.month",
          title: "MonthSortingNew",
          gd_data_type: "INT",
          gd_type: "GDC.text"
        }])
    end

    it "should be able to parse the anchor" do
      model = @model_view['projectModelView']['model']['projectModel']['datasets'][3]
      x = FromWire.parse_attribute(model['dataset']['anchor']['attribute'], :anchor)
      expect(x.to_set).to eq Set.new([
        {
          type: :anchor,
          id: "attr.opportunityanalysis.techoppanalysis",
          title: "Tech Opp. Analysis",
          folder: "Opportunity Benchmark",
          description: nil,
        },
        {
          type: :label,
          id: "label.opportunityanalysis.techoppanalysis",
          title: "Tech Opp. Analysis",
          reference: "attr.opportunityanalysis.techoppanalysis",
          gd_data_type: "VARCHAR(128)",
          gd_type: "GDC.text",
          default_label: true
        }])
    end
  end

  describe '#parse_attributes' do
    it "should be able to parse the attributes with one label" do
      model = @model_view['projectModelView']['model']['projectModel']['datasets'].first
      x = FromWire.parse_attributes(model)
      expect(x.to_set).to eq Set.new([
        {
          type: :attribute,
          id: "attr.stage_history.currentstatus",
          title: "Current Stage",
          description: nil,
          folder: nil
        },
        {
          type: :label,
          id: "label.stage_history.currentstatus",
          reference: "attr.stage_history.currentstatus",
          title: "Current Stage",
          gd_data_type: "VARCHAR(128)",
          gd_type: "GDC.text",
          default_label: true
        }
      ])
    end

    it "should be able to parse the attributes with several labels" do
      model = @model_view['projectModelView']['model']['projectModel']['datasets'][3]
      x = FromWire.parse_attributes(model)
      expect(x.to_set).to eq Set.new([
        {
          type: :attribute,
          id: "attr.opportunityanalysis.month",
          title: "Month",
          description: nil,
          folder: "Opportunity Benchmark"
        },
        {
          type: :label,
          reference: "attr.opportunityanalysis.month",
          id: "label.opportunityanalysis.month",
          title: "Month",
          gd_data_type: "VARCHAR(128)",
          gd_type: "GDC.text",
          default_label: true
        },
        {
          type: :label,
          id: "label.opportunityanalysis.month.monthsortingnew",
          reference: "attr.opportunityanalysis.month",
          title: "MonthSortingNew",
          gd_data_type: "INT",
          gd_type: "GDC.text"
        },
        {
          type: :attribute,
          id: "attr.opportunityanalysis.cohorttype",
          title: "Cohort Type",
          description: nil,
          folder: "Opportunity Benchmark"
        },
        {
          type: :label,
          id: "label.opportunityanalysis.cohorttype",
          reference: "attr.opportunityanalysis.cohorttype",
          title: "Cohort Type",
          gd_data_type: "VARCHAR(128)",
          gd_type: "GDC.text",
          default_label: true
        }
      ])
    end

    it "should be able to parse the attributes with no labels" do
      model = @model_view['projectModelView']['model']['projectModel']['datasets'][7]
      x = FromWire.parse_attributes(model)
      expect(x.to_set).to eq Set.new()
    end
  end

  describe '#parse_anchor' do
    it "should be able to parse the anchor without label" do
      model = @model_view['projectModelView']['model']['projectModel']['datasets'].first
      x = FromWire.parse_anchor(model)
      expect(x.to_set).to eq Set.new([{
        type: :anchor,
        id: "attr.stage_history.factsof",
        title: "Records of stage_history",
        description: nil,
        folder: nil
      }])
    end

    it "should be able to parse the anchor out of dataset when there are multiple labels" do
      model = @model_view['projectModelView']['model']['projectModel']['datasets'][7]
      x = FromWire.parse_anchor(model)
      expect(x.to_set).to eq Set.new([
        {
          type: :anchor,
          id: "attr.opp_records.factsof",
          title: "Records of opp_records",
          description: nil,
          folder: nil
        },
        {
          type: :label,
          id: "label.opp_records.opp_records_conctn_point",
          reference: "attr.opp_records.factsof",
          title: "opp_records_conctn_point",
          gd_data_type: "VARCHAR(128)",
          gd_type: "GDC.text",
          default_label: true
        },
        { 
          type: :label,
          id: "label.opp_records.factsof",
          reference: "attr.opp_records.factsof",
          title: "Records of opp_records",
          gd_data_type: "VARCHAR(128)",
          gd_type: "GDC.text"
        }
      ])
    end

    it 'should' do
      skip('primary vs default. Is it covered?')
    end
  end

  describe '#parse_facts' do
    it 'should be able to parse facts from dataset' do
      model = @model_view['projectModelView']['model']['projectModel']['datasets'].first
      facts = GoodData::Model::FromWire.parse_facts(model)
      expect(facts.to_set).to eq Set.new([
        {
          type: :fact,
          id: "fact.stage_history.stage_velocity",
          title: "Stage Velocity",
          description: "Velocity description",
          gd_data_type: "DECIMAL(12,2)",
          folder: nil
        },
        {
          type: :fact,
          id: "fact.stage_history.stage_duration",
          title: "Stage Duration",
          gd_data_type: "DECIMAL(12,2)",
          folder: nil
        },
        {
          type: :date_fact,
          id: "dt.stage_history.opp_created_date",
          title: "Opp. Created (Date) for Stage History",
          gd_data_type: "INT",
          folder: nil
        },
        {
          type: :date_fact,
          id: "dt.stage_history.opp_close_date",
          title: "Opp. Close (Date) for Stage History",
          gd_data_type: "INT",
          folder: nil
        }
      ])
    end
  end

  describe '#parse_dataset' do
    it 'should be able to parse dataset' do
      model_view = MultiJson.load(File.read('./spec/data/wire_models/nu_model.json'))
      dataset = GoodData::Model::FromWire.dataset_from_wire(model_view['projectModelView']['model']['projectModel']['datasets'].first)
      expect(dataset).to have_key(:type)
      expect(dataset[:type]).to eq :dataset
      expect(dataset[:id]).to eq 'dataset.bookingsactual'
      expect(dataset[:columns].select { |c| c[:type] == :attribute }.count).to eq 15
      expect(dataset[:columns].select { |c| c[:type] == :fact }.count).to eq 3
      expect(dataset[:columns].select { |c| c[:type] == :reference }.count).to eq 6
      expect(dataset[:columns].select { |c| c[:type] == :date }.count).to eq 5
    end
  end

  describe '#from_wire' do
    it 'should be able to parse dataset' do
      model_view = MultiJson.load(File.read('./spec/data/wire_models/nu_model.json'))
      bp = GoodData::Model::FromWire.from_wire(model_view)
    end
  end

  it "should parse the model view and return the blueprint" do
    expect(@blueprint.datasets.count).to eq 28
  end

  it "should have a datatype if defined" do
    dataset = @blueprint.datasets.find {|d| d.id == 'dataset.account' }
    dataset.labels_for_attribute('attr.account.accountemployeecount')

    dataset = @blueprint.find_dataset('dataset.stage_history')
    col = dataset.find_column_by_id('fact.stage_history.stage_duration')
    expect(col.gd_data_type).to eq 'DECIMAL(12,2)'
  end

  it "should have a datatype if defined" do
    col = @blueprint.find_dataset('dataset.stage_history').labels('label.stage_history.currentstatus')
    expect(col.gd_type).to eq 'GDC.text'
  end

  it "should validate a gd_type" do
    expect(GoodData::Model.check_gd_type("GDC.time")).to eq true
    expect(GoodData::Model.check_gd_type("gdc.time")).to eq false
    expect(GoodData::Model.check_gd_type("gdc.time3")).to eq false
  end

  it "should validate a gd_datatype" do
    expect(GoodData::Model.check_gd_data_type("INT")).to eq true
    expect(GoodData::Model.check_gd_data_type("int")).to eq true
    expect(GoodData::Model.check_gd_data_type("VARCHAR(128)")).to eq true
    expect(GoodData::Model.check_gd_data_type("varchar(128)")).to eq true
    expect(GoodData::Model.check_gd_data_type("DECIMAL(10, 5)")).to eq true
    expect(GoodData::Model.check_gd_data_type("DECIMAL(10,5)")).to eq true
    expect(GoodData::Model.check_gd_data_type("DECIMAL(10,  5)")).to eq true
    expect(GoodData::Model.check_gd_data_type("decimal(10, 5)")).to eq true
    expect(GoodData::Model.check_gd_data_type("decimal(10,5)")).to eq true
    expect(GoodData::Model.check_gd_data_type("decimal(10,  5)")).to eq true
  end

  it "should be able to parse description from both attributes and facts" do
    expect(@blueprint.find_dataset('dataset.opportunity').anchor.description).to eq 'This is opportunity attribute description'
    expect(@blueprint.find_dataset('dataset.stage_history').facts.find {|f| f.id == 'fact.stage_history.stage_velocity'}.description).to eq 'Velocity description'
    expect(@blueprint.find_dataset('dataset.opp_owner').attributes.find {|f| f.id == 'attr.opp_owner.region'}.description).to eq 'Owner Region description'
  end
end
