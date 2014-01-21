require 'gooddata/model'
require 'pry'

describe GoodData::Model::SchemaBuilder do

  it "should create a schema" do
    builder = GoodData::Model::SchemaBuilder.new("a_title")
    schema = builder.to_schema
    schema.title.should == "a_title"
  end

  it "should create a schema with some columns" do
    builder = GoodData::Model::SchemaBuilder.new("payments")
    builder.add_attribute("id", :title => "My Id")
    builder.add_fact("amount", :title => "Amount")

    schema = builder.to_schema
    schema.attributes.keys.count == 1
    schema.attributes["attr.payments.id"].title.should == "My Id"
  end

end