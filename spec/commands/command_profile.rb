require 'gooddata/commands/profile'

describe GoodData::Command::Profile do
  before(:each) do
    @connection = ConnectionHelper::create_default_connection
  end

  it "Is Possible to create GoodData::Command::Profile instance" do
    cmd = GoodData::Command::Profile.new(NEW_COMMAND_OPTIONS)
    cmd.should be_a(GoodData::Command::Profile)
  end
end