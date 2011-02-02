require 'logger'
require 'tempfile'

require 'helper'
require 'gooddata/command'

GoodData.logger = Logger.new(STDOUT)

class TestRestApiBasic < Test::Unit::TestCase
  context "datasets command" do
    SAMPLE_DATASET_CONFIG = {
      "columns" => [
        {
          "type"  => "CONNECTION_POINT",
          "name"  => "A1",
          "title" =>"A1"
        },
        {
          "type"  => "ATTRIBUTE",
          "name"  => "A2",
          "title" => "A2",
          "folder"=> "Test"
        },
        {
          "type"  => "FACT",
          "name"  => "F2",
          "title" => "F2 \"asdasd\"",
          "folder"=> "Test"
        }
      ],
      "title" => "Test"
    }

    should "list datasets" do
      GoodData::Command.run "datasets", [ "--project", "FoodMartDemo" ]
    end

    should "apply a dataset model" do
      GoodData::Command.connect
      project = GoodData::Project.create :title => "gooddata-ruby TestRestApi #{Time.new.to_i}"

      Tempfile.open 'gdrb-test-' do |file|
        file.puts SAMPLE_DATASET_CONFIG.to_json
        file.close
        GoodData::Command.run "datasets:apply", [ "--project", project.uri, file.path ]
      end
      project.delete
    end
  end

  context "projects command" do
    should "list projects" do
      GoodData::Command.run "projects", []
    end
  end

  context "api command" do
    should "perform a test login" do
      GoodData::Command.run "api:test", []
    end

    should "get FoodMartDemo metadata" do
      GoodData::Command.run "api:get", [ '/gdc/md/FoodMartDemo' ]
    end
  end

  context "profile command" do
    should "show my GoodData profile" do
      GoodData::Command.run "profile", []
    end
  end

  context "help command" do
    should "print help screen" do
      GoodData::Command.run "help", []
    end
  end

  context "version command" do
    should "print version" do
      GoodData::Command.run "version", []
    end
  end
end
