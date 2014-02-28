require 'gooddata/model'
require 'pry'

describe GoodData::Model::ProjectBlueprint do

  before(:each) do
    @base_blueprint = blueprint = GoodData::Model::ProjectBlueprint.new(
    {
      :title => "x",
      :datasets => [
        {
          :name=>"payments",
          :columns => [
            {:type=>:attribute, :name=>"id"},
            {:type=>:fact, :name=>"amount"},
            {:type=>:reference, :name=>"user_id", :dataset => "users", :reference => "user_id"},
            ]
        },
        {
          :name=>"users",
          :columns => [
            {:type=>:anchor, :name=>"user_id"},
            {:type=>:fact, :name=>"amount"}]
        }
      ]})
      
    @additional_blueprint = GoodData::Model::ProjectBlueprint.new(
    {
      :title => "x",
      :datasets => [
        {
          :name=>"users",
          :columns => [
            {:type=>:attribute, :name=>"region"}
          ]
        }
      ]})

    @blueprint_with_duplicate = GoodData::Model::ProjectBlueprint.new(
    {
      :title => "x",
      :datasets => [
        {
          :name=>"users",
          :columns => [
            {:type=>:fact, :name=>"amount"}
          ]
        }
      ]})

    @conflicting_blueprint = GoodData::Model::ProjectBlueprint.new(
    {
      :title => "x",
      :datasets => [
        {
          :name=>"users",
          :columns => [
            {:type=>:attribute, :name=>"amount"}
          ]
        }
      ]})
  end

  it "should be possible to merge Schema blueprints" do
    first_dataset = @base_blueprint.get_dataset("users").to_hash
    additional_blueprint = @additional_blueprint.get_dataset("users").to_hash
    stuff = GoodData::Model.merge_dataset_columns(first_dataset, additional_blueprint)
    stuff[:columns].include?({:type=>:attribute, :name=>"region"}).should == true
    stuff[:columns].include?({:type=>:fact, :name=>"amount"}).should == true
  end

  it "should pass when merging 2 columns with the same name if all attributes are identical" do
    first_dataset = @base_blueprint.get_dataset("users").to_hash
    additional_blueprint = @blueprint_with_duplicate.get_dataset("users").to_hash
    stuff = GoodData::Model.merge_dataset_columns(first_dataset, additional_blueprint)

    stuff[:columns].count.should == 2
    stuff[:columns].include?({:type=>:fact, :name=>"amount"}).should == true
    stuff[:columns].include?({:type=>:anchor, :name=>"user_id"}).should == true
  end
  
  it "should pass when merging 2 columns with the same name if all attributes are identical" do
    first_dataset = @base_blueprint.get_dataset("users").to_hash
    additional_blueprint = @conflicting_blueprint.get_dataset("users").to_hash

    expect{GoodData::Model.merge_dataset_columns(first_dataset, additional_blueprint)}.to raise_error
  end

end