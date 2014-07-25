# encoding: UTF-8

require 'pry'
require 'gooddata/models/model'

describe GoodData::Model::SchemaBuilder do

  it "should create a schema" do
    # pending("Using of humanize")

    builder = GoodData::Model::SchemaBuilder.new("a_title")
    blueprint = builder.to_blueprint
    blueprint.title.should == "A Title"
    blueprint.name.should == "a_title"
  end

  it "should create a schema with some columns" do
    builder = GoodData::Model::SchemaBuilder.new("payments")
    builder.add_attribute("id", :title => "My Id")
    builder.add_fact("amount", :title => "Amount")

    blueprint = builder.to_blueprint
    blueprint.attributes.count == 1
  end

end