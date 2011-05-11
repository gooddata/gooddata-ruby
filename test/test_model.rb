require 'logger'

require 'helper'
require 'gooddata/model'
require 'gooddata/command'

GoodData.logger = Logger.new(STDOUT)

class TestModel < Test::Unit::TestCase
  COLUMNS = [
      { 'type' => 'CONNECTION_POINT', 'name' => 'cp', 'title' => 'CP', 'folder' => 'test' },
      { 'type' => 'ATTRIBUTE', 'name' => 'a1', 'title' => 'A1', 'folder' => 'test' },
      { 'type' => 'ATTRIBUTE', 'name' => 'a2', 'title' => 'A2', 'folder' => 'test' },
      { 'type' => 'DATE', 'name' => 'event', 'title' => 'Event', 'folder' => 'test' },
      { 'type' => 'FACT', 'name' => 'f1', 'title' => 'F1', 'folder' => 'test' },
      { 'type' => 'FACT', 'name' => 'f2', 'title' => 'F2', 'folder' => 'test' },
    ]
  SCHEMA = GoodData::Model::Schema.new 'title' => 'test', 'columns' => COLUMNS

  context "GoodData model tools" do
    # Initialize a GoodData connection using the credential
    # stored in ~/.gooddata
    setup do
      GoodData::Command::connect
    end

    should "generate identifiers star  ting with letters and without ugly characters" do
      assert_equal 'fact.test.blah', GoodData::Model::Fact.new({ 'name' => 'blah' }, SCHEMA).identifier
      assert_equal 'attr.test.blah', GoodData::Model::Attribute.new({ 'name' => '1_2_3 blah' }, SCHEMA).identifier
      assert_equal 'dim.blaz', GoodData::Model::AttributeFolder.new(' b*ĺ*á#ž$').identifier
    end

    should "create a simple model in a sandbox project using Model.add_dataset" do
      project = GoodData::Project.create :title => "gooddata-ruby test #{Time.new.to_i}"
      GoodData.use project
      objects = GoodData::Model.add_dataset 'Mrkev', COLUMNS

      uris = objects['uris']
      assert_equal "#{project.md['obj']}/1", uris[0]
      # fetch last object (temporary objects can be placed at the begining of the list)
      GoodData.get uris[uris.length - 1]

      # created model should define SLI interface on the 'Mrkev' data set
      # TODO move this into a standalone test covering gooddata/metadata.rb
      ds = GoodData::DataSet['dataset.mrkev']
      assert_not_nil ds

      # create a similar data set but without the connection point column
      cols_no_cp = COLUMNS.select { |c| c['type'] != 'CONNECTION_POINT' }
      objects    = GoodData::Model.add_dataset 'No CP', cols_no_cp
      uris       = objects['uris']

      # Repeat check of metadata objects expected to be created on the server side
      GoodData.get uris[uris.length - 1]
      ds = GoodData::DataSet['dataset.nocp']
      assert_not_nil ds

      # clean-up
      project.delete
    end

    should "create a simple model in a sandbox project using project.model.add_dataset" do
      project = GoodData::Project.create :title => "gooddata-ruby test #{Time.new.to_i}"
      objects = project.add_dataset 'Mrkev', COLUMNS

      uris = objects['uris']
      assert_equal "#{project.md['obj']}/1", uris[0]
      # fetch last object (temporary objects can be placed at the begining of the list)
      GoodData.get uris[uris.length - 1]
      project.delete
    end
  end
end
