require 'logger'

require 'helper'
require 'gooddata/command'
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
  
  context "schema creation" do
    should "be created with hash" do
      schema = Schema.new 'title' => 'schema title', 'columns' => COLUMNS

      assert_equal 'schema title', schema.title
      assert_equal 2, schema.attributes.size
      assert_equal 2, schema.facts.size
      assert_equal 5, schema.fields.size
      assert_equal 'test', schema.folders[:attributes]['test'].title
      assert_equal 'test', schema.folders[:facts]['test'].title
    end
    
    should "require a name" do
      assert_raise RuntimeError do
        config = {}
        Schema.new({}) 
      end
    end
    
  end
  
  context "add dataset twice to project" do
    should "add dataset happy case" do
      schema = Schema.new 'title' => 'yo', 'columns' => COLUMNS
      GoodData::Command::connect
      project = GoodData::Project.create :title => "gooddata-ruby test #{Time.now.to_i}"
      project.add_dataset schema
      e = assert_raise RestClient::InternalServerError do 
        project.add_dataset schema
      end
      #assert e.message =~ /Duplicate entry/
    end
  end
end