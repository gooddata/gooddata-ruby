require 'logger'

require 'helper'
require 'gooddata/model'

include GoodData::Model

GoodData.logger = Logger.new(STDOUT)

class TestSchema < Test::Unit::TestCase
  COLUMNS = [
      { 'type' => 'CONNECTION_POINT', 'name' => 'cp', 'title' => 'CP', 'folder' => 'test' },
      { 'type' => 'ATTRIBUTE', 'name' => 'a1', 'title' => 'A1', 'folder' => 'test' },
      { 'type' => 'ATTRIBUTE', 'name' => 'a2', 'title' => 'A2', 'folder' => 'test' },
      { 'type' => 'FACT', 'name' => 'f1', 'title' => 'F1', 'folder' => 'test' },
      { 'type' => 'FACT', 'name' => 'f2', 'title' => 'F2', 'folder' => 'test' },
    ]
  
  context "a schema" do
    should "be created" do
      config = {}
      config['title'] = 'schema title'
      config['columns'] = COLUMNS
      schema = Schema.new config
      assert_equal 'schema title', schema.title
      assert_equal 2, schema.attributes.size
      assert_equal 2, schema.facts.size
      assert_equal 5, schema.fields.size
      assert_equal 'test', schema.folders[:attributes]['test'].title
      assert_equal 'test', schema.folders[:facts]['test'].title
    end
  end
end