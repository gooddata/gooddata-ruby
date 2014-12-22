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

  describe :change do
    it "should be possible to easily change the dataset without touching the original" do
      name = 'some_numbers'
      ds = @base_blueprint.find_dataset("devs")
      new_ds = ds.change do |d|
        d.add_fact(name)
      end
      expect(ds.find_column_by_name(name)).to eq nil
      expect(new_ds.find_column_by_name(name)).to eq ({ type: :fact, name: "some_numbers"})
      expect(new_ds.equal?(ds)).to eq false
    end

    it "should be possible to remove columns as well" do
      name = 'some_numbers'
      ds = @base_blueprint.find_dataset("devs")
      new_ds = ds.change do |d|
        d.add_fact(name)
      end
      ds_without_column = new_ds.change do |d|
        d.remove_column(name)
      end

      expect(ds_without_column.find_column_by_name(name)).to eq nil
      expect(ds_without_column.eql?(ds)).to eq true
    end
  end

  describe :change! do
    it "should be possible to easily change the dataset inplace" do
      name = 'some_numbers'
      ds = @base_blueprint.find_dataset("devs")
      new_ds = ds.change! do |d|
        d.add_fact(name)
      end
      expect(ds.find_column_by_name(name)).to eq ({ type: :fact, name: "some_numbers"})
      expect(new_ds.find_column_by_name(name)).to eq ({ type: :fact, name: "some_numbers"})
      expect(new_ds.equal?(ds)).to eq true
    end
  end

end