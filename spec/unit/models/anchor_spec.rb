# encoding: UTF-8

require 'gooddata/models/anchor'

describe GoodData::Model::Anchor do
  SCHEMA = []

  describe '#initialize' do
    it 'Creates new instance' do
      instance = GoodData::Model::Anchor.new(nil, SchemaHelper::SCHEMA)
      instance.should_not == nil
    end
  end

  describe '#table' do
    it 'Returns Table ' do
      instance = GoodData::Model::Anchor.new(nil, SchemaHelper::SCHEMA)
      result = instance.table
      result.should_not == nil
    end
  end

  describe '#to_maql_create' do
    it 'Returns MAQL string for schema' do
      pending('Not working, investigate')
      instance = GoodData::Model::Anchor.new(nil, SchemaHelper::SCHEMA)
      result = instance.to_maql_create
      result.should_not == nil
      result.should be_an_instance_of(String)
    end
  end
end