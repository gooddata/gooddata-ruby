require 'logger'

require 'helper'
require 'gooddata/command'

GoodData.logger = Logger.new(STDOUT)

class TestRestApiBasic < Test::Unit::TestCase
  context "datasets command" do
    should "list datasets" do
      GoodData::Command.run "datasets", [ "--project", "FoodMartDemo" ]
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
