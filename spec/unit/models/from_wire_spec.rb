# encoding: UTF-8

require 'gooddata'

include GoodData::Model

describe GoodData::Model::FromWire do

  before(:each) do
    @model_view = MultiJson.load(File.read('./spec/data/wire_models/model_view.json'))
    @blueprint = FromWire.from_wire(@model_view)
  end

  it "should parse the model view and return the blueprint" do
    expect(@blueprint.datasets.count).to eq 28
  end

  it "should have a datatype if defined" do
    col = @blueprint.find_dataset('stage_history').find_column_by_name('stage_duration', nil)
    expect(col.key?(:gd_data_type)).to eq true
    expect(col[:gd_data_type]).to eq 'DECIMAL(12,2)'
  end

  it "should have a datatype if defined" do
    col = @blueprint.find_dataset('stage_history').find_column_by_name('currentstatus', nil)
    expect(col.key?(:gd_type)).to eq true
    expect(col[:gd_type]).to eq 'GDC.text'
  end

  it "should validate a gd_datatype" do
    expect(GoodData::Model.check_gd_datatype("GDC.time")).to eq true
    expect(GoodData::Model.check_gd_datatype("gdc.time")).to eq false
    expect(GoodData::Model.check_gd_datatype("gdc.time3")).to eq false
  end

  it "should be able to omit titles if they are superfluous" do
    view = MultiJson.load(File.read('./spec/data/superfluous_titles_view.json'))
    blueprint = FromWire.from_wire(view)
    expect(blueprint.datasets.count).to eq 1
    expect(blueprint.datasets.first.find_column_by_name('current_status', nil).key?(:title)).to eq false
    expect(blueprint.datasets.mapcat { |ds| ds.columns }.any? {|col| col[:name].titleize == col[:title]}).to eq false
  end

  it "should enable sorting" do
    skip("UAAA")
  end

  it "should allow defining date dimensions" do
    skip('UAAA')
  end

  it "should generate the same thing it parsed" do
    a = @model_view['projectModelView']['model']['projectModel']['datasets'][3]
    b = @blueprint.to_wire
    # expect(b).to eq a
  end

  it "should be able to parse the anchor out of dataset" do
    x = FromWire.parse_anchor(@model_view['projectModelView']['model']['projectModel']['datasets'][3])
    expect(x).to eq [
      {
        type: 'anchor',
        name: "techoppanalysis",
        folder: "Opportunity Benchmark",
        title: "Tech Opp. Analysis",
        gd_data_type: "VARCHAR(128)",
        gd_type: "GDC.text",
        default_label: true
      }]
  end

  it "should be able to parse the anchor out of dataset" do
    x = FromWire.parse_attributes(@model_view['projectModelView']['model']['projectModel']['datasets'][3])
    expect(x).to eq [
      {
        :type=>'attribute',
        :folder => "Opportunity Benchmark",
        :name=>"month",
        :gd_data_type=>"VARCHAR(128)",
        :gd_type=>"GDC.text",
        :default_label=>true
      },
     {
       :type=>'label',
       :reference=>"month",
       :name=>"monthsortingnew",
       :title=>"MonthSortingNew",
       :gd_data_type=>"INT",
       :gd_type=>"GDC.text"
      },
     {
       :type=>'attribute',
       :folder => "Opportunity Benchmark",
       :name=>"cohorttype",
       :title=>"Cohort Type",
       :gd_data_type=>"VARCHAR(128)",
       :gd_type=>"GDC.text",
       :default_label=>true
      }]
  end

  it "should be able to parse the anchor out of dataset when there are multiple labels and primary label and default label are not the same" do
    x = FromWire.parse_anchor(@model_view['projectModelView']['model']['projectModel']['datasets'][7])
    expect(x).to eq [
      {
        :type=>"anchor",
        :name=>"factsof",
        :title=>"Records of opp_records",
        :gd_data_type=>"VARCHAR(128)",
        :gd_type=>"GDC.text"
      },
      {
        :type=>"label",
        :reference=>"factsof",
        :name=>"opp_records_conctn_point",
        :title=>"opp_records_conctn_point",
        :gd_data_type=>"VARCHAR(128)",
        :gd_type=>"GDC.text",
        :default_label => true
      }]
  end

  it "should be able to parse description from both attributes and facts" do
    expect(@blueprint.find_dataset('opportunity').anchor[:description]).to eq 'This is opportunity attribute description'
    expect(@blueprint.find_dataset('stage_history').facts.find {|f| f[:name] == 'stage_velocity'}[:description]).to eq 'Velocity description'
    expect(@blueprint.find_dataset('opp_owner').attributes.find {|f| f[:name] == 'region'}[:description]).to eq 'Owner Region description'
  end

  it "should be able to deal with fiscal dimensions with weird names" do
    model_view = MultiJson.load(File.read('./spec/data/wire_models/nu_model.json'))
    blueprint = FromWire.from_wire(model_view)
    blueprint.lint
  end

end
