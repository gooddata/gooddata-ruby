require 'gooddata/commands/user'

describe GoodData::Command::User do
  before(:each) do
    @client = ConnectionHelper.create_default_connection
  end

  after(:each) do
    @client.disconnect
  end

  it "Is Possible to create GoodData::Command::Membership instance" do
    cmd = GoodData::Command::User.new()
    cmd.should be_a(GoodData::Command::User)
  end

  describe "#show" do
    it "Shows profile" do
      GoodData::Command::User.show(:client => @client)
    end
  end
end