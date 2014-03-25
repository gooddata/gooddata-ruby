# encoding: UTF-8

require 'gooddata/commands/profile'

describe GoodData::Command::Profile do
  before(:each) do
    @connection = ConnectionHelper::create_default_connection
  end

  it "Is Possible to create GoodData::Command::Profile instance" do
    cmd = GoodData::Command::Profile.new()
    cmd.should be_a(GoodData::Command::Profile)
  end

  describe "#show" do
    it "Shows profile" do
      GoodData::Command::Profile.show
    end
  end
end