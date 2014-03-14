require 'gooddata/commands/process'

describe GoodData::Command::Process do
  before(:each) do
    @connection = ConnectionHelper::create_default_connection
  end

  it "Is Possible to create GoodData::Command::Process instance" do
    cmd = GoodData::Command::Process.new()
    cmd.should be_a(GoodData::Command::Process)
  end
end