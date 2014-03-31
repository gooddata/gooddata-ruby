# encoding: UTF-8

require 'gooddata/commands/api'

describe GoodData::Command::Api do
  before(:each) do
    ConnectionHelper.create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  it "Is Possible to create GoodData::Command::Api instance" do
    cmd = GoodData::Command::Api.new()
    cmd.should be_a(GoodData::Command::Api)
  end

  describe "#get" do
    it "Call without arguments" do
      GoodData::Command::Api.get('/gdc')
    end
  end

  describe "#delete" do
    it "Call without arguments" do
      pending('Create resource which can be deleted first')
      GoodData::Command::Api.delete('/some/resource')
    end
  end

  describe "#test" do
    it "Call without arguments" do
      GoodData::Command::Api.test()
    end
  end

end