# encoding: UTF-8

require 'pry'
require 'gooddata/models/model'

describe GoodData::Model do

  before(:each) do
    @base_blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/test_project_model_spec.json")
    @additional_blueprint = GoodData::Model::ProjectBlueprint.from_json("./spec/data/model_module.json")

    @blueprint_with_duplicate = GoodData::Model::ProjectBlueprint.new(
      {
        title: "x",
        datasets: [
          {
            name: "commits",
            columns: [
              {
                name: "lines_changed",
                type: "fact",
              }
            ]
          }
        ]
      }
    )

    @conflicting_blueprint = GoodData::Model::ProjectBlueprint.new(
      {
        title: "x",
        datasets: [
          {
            name: "commits",
            columns: [
              {
                name: "lines_changed",
                type: "attribute",
              }
            ]
          }
        ]
      }
    )
  end

  describe ".title" do

    it "returns title" do
      expect(GoodData::Model.title(@base_blueprint.to_hash)).to eq "RubyGem Dev Week test"
    end
    
    it "returns titleized name when title is not present" do
      hash = @base_blueprint.to_hash
      hash.delete(:title)
      hash[:name] = "ruby test"
      expect(GoodData::Model.title(hash)).to eq "Ruby Test"
    end
  end

  describe ".has_gd_type?" do

    it "returns true for supported gd_type" do
      expect(GoodData::Model.has_gd_type?("GDC.link")).to eq true
      expect(GoodData::Model.has_gd_type?("GDC.text")).to eq true
      expect(GoodData::Model.has_gd_type?("GDC.geo")).to eq true
      expect(GoodData::Model.has_gd_type?("GDC.time")).to eq true
    end
    
    it "returns false for not supported gd_type" do
      expect(GoodData::Model.has_gd_type?("gdc.time")).to eq false
      expect(GoodData::Model.has_gd_type?("GDC.time3")).to eq false
    end
  end
  
  describe ".has_gd_datatype?" do

    it "returns true for supported gd_datatype" do
      expect(GoodData::Model.has_gd_datatype?("INT")).to eq true
      expect(GoodData::Model.has_gd_datatype?("VARCHAR")).to eq true
      expect(GoodData::Model.has_gd_datatype?("DECIMAL")).to eq true
    end
    
    it "returns false for not supported gd_datatype" do
      expect(GoodData::Model.has_gd_datatype?("int")).to eq false
      expect(GoodData::Model.has_gd_datatype?("FLOAT")).to eq false
      expect(GoodData::Model.has_gd_datatype?("CHAR")).to eq false
    end
  end

  describe ".merge_dataset_columns" do
    
    it "should be possible to merge Schema blueprints" do
      first_dataset = @base_blueprint.find_dataset("devs")
      additional_blueprint = @additional_blueprint.find_dataset("devs")
      stuff = GoodData::Model.merge_dataset_columns(first_dataset, additional_blueprint)
      stuff[:columns].include?({:type => "attribute", :name => "region"}).should == true
      stuff[:columns].include?({:type => "anchor", :name => "id"}).should == true
    end

    it "should pass when merging 2 columns with the same name if both columns are identical" do
      first_dataset = @base_blueprint.find_dataset("commits")
      additional_blueprint = @blueprint_with_duplicate.find_dataset("commits")

      stuff = GoodData::Model.merge_dataset_columns(first_dataset, additional_blueprint)

      stuff[:columns].count.should == 4
      stuff[:columns].include?({:type => "fact", :name => "lines_changed"}).should == true
      stuff[:columns].group_by { |col| col[:name] }["lines_changed"].count.should == 1
    end

    it "should pass when merging 2 columns with the same name if all attributes are identical" do
      first_dataset = @base_blueprint.find_dataset("commits")
      additional_blueprint = @conflicting_blueprint.find_dataset("commits")

      expect { GoodData::Model.merge_dataset_columns(first_dataset, additional_blueprint) }.to raise_error
    end

    it "should be possible to merge directly whole bleuprints. Blueprint is changed in place when merge! is used" do
      @base_blueprint.merge!(@additional_blueprint)
      @base_blueprint.find_dataset("repos").attributes.include?({:type => "attribute", :name => "department"})
    end
  end
end