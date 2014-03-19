require 'pry'
require 'gooddata/models/model'

describe GoodData::Model::SchemaBuilder do

  it "should create a schema" do
    builder = GoodData::Model::SchemaBuilder.new("a_title")
    schema = builder.to_schema
    schema.title.should == "A title"
    schema.name.should == "a_title"
  end

  it "should create a schema with some columns" do
    builder = GoodData::Model::SchemaBuilder.new("payments")
    builder.add_attribute("id", :title => "My Id")
    builder.add_fact("amount", :title => "Amount")

    schema = builder.to_schema
    schema.attributes.count == 1
    schema.attributes.first.title.should == "My Id"
  end

end