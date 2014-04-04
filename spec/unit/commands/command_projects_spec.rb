require 'gooddata/commands/projects'

describe GoodData::Command::Projects do
  before(:each) do
    ConnectionHelper.create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  it "Is Possible to create GoodData::Command::Projects instance" do
    cmd = GoodData::Command::Projects.new()
    cmd.should be_a(GoodData::Command::Projects)
  end
end