# encoding: UTF-8

require 'pry'
require 'gooddata/models/model'

describe GoodData::Model::SchemaBuilder do

  it "should create a schema" do
    builder = GoodData::Model::SchemaBuilder.new("a_title")
    blueprint = builder.to_blueprint
    expect(blueprint.datasets.first.title).to eq 'A Title'
  end

  it "should create a schema with some columns" do
    builder = GoodData::Model::SchemaBuilder.new("payments")
    builder.add_attribute("id", :title => "My Id")
    builder.add_fact("amount", :title => "Amount")

    blueprint = builder.to_blueprint
    blueprint.attributes.count == 1
  end

  it "should be able to create from block" do
    builder = GoodData::Model::SchemaBuilder.create("payments") do |d|
      d.add_attribute('attr.id', :title => 'Id')
      d.add_label('label.id.name', :title => 'Id Name', reference: 'attr.id')
      d.add_fact('amount', :title => 'Amount')
    end

    blueprint = builder.to_blueprint
    blueprint.attributes.count == 1
    blueprint.facts.count == 1
  end
end