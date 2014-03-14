require 'gooddata/commands/auth'

describe GoodData::Command::Auth do
  before(:each) do
    @connection = ConnectionHelper::create_default_connection
  end

  it "Is Possible to create GoodData::Command::Auth instance" do
    cmd = GoodData::Command::Auth.new()
    cmd.should be_a(GoodData::Command::Auth)
  end
end