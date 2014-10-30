require 'gooddata/commands/api'

describe GoodData::Command::Api do
  before(:each) do
    @connection = ConnectionHelper::create_default_connection
  end

  it "Is Possible to create GoodData::Command::Api instance" do
    cmd = GoodData::Command::Api.new()
    cmd.should be_a(GoodData::Command::Api)
  end
end