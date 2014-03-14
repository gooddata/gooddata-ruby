require 'gooddata/commands/scaffold'

describe GoodData::Command::Scaffold do
  before(:each) do
    @connection = ConnectionHelper::create_default_connection
  end

  it "Is Possible to create GoodData::Command::Scaffold instance" do
    cmd = GoodData::Command::Scaffold.new()
    cmd.should be_a(GoodData::Command::Scaffold)
  end
end