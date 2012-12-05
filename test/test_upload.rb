require 'logger'
require 'tempfile'

require 'helper'
require 'gooddata/model'
require 'gooddata/command'

GoodData.logger = Logger.new(STDOUT)

class TestModel < Test::Unit::TestCase
  FILE = [
    [ "cp", "a1", "a2", "f1", "f2" ],
    [ 1, "a1.1", "a2.1", "0", "5" ],
    [ 2, "a1.2", "a2.1", nil, 10 ],
    [ 3, "a1.2", "a2.2", 1, nil ],
    [ 4, "a1.3", "a2.2", 0, 0 ]
  ]
  COLUMNS = [
      { 'type' => 'CONNECTION_POINT', 'name' => 'cp', 'title' => 'CP', 'folder' => 'test' },
      { 'type' => 'ATTRIBUTE', 'name' => 'a1', 'title' => 'A1', 'folder' => 'test' },
      { 'type' => 'ATTRIBUTE', 'name' => 'a2', 'title' => 'A2', 'folder' => 'test' },
      { 'type' => 'FACT', 'name' => 'f1', 'title' => 'F1', 'folder' => 'test' },
      { 'type' => 'FACT', 'name' => 'f2', 'title' => 'F2', 'folder' => 'test' },
    ]
  SCHEMA = GoodData::Model::Schema.new 'title' => 'test', 'columns' => COLUMNS

  context "GoodData model tools" do
    # Initialize a GoodData connection using the credential
    # stored in ~/.gooddata
    #
    # And create a temporary CSV file to test the upload
    setup do
      GoodData::Command::connect
      @file = Tempfile.open 'test_csv'
      FasterCSV.open @file.path, 'w' do |csv|
        FILE.each { |row| csv << row }
      end
      @project = GoodData::Project.create :title => "gooddata-ruby test #{Time.now.to_i}"
    end

    teardown do
      @file.unlink
      @project.delete
    end

    should "upload CSV in a full mode" do
      @project.add_dataset SCHEMA
      assert_equal 1, @project.datasets.size
      assert_equal "test", @project.datasets.first.title
      @project.upload @file.path, SCHEMA, "FULL"
    end
  end
end
