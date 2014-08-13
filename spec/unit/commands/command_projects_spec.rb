require 'gooddata/commands/project'

describe GoodData::Command::Project do
  before(:each) do
    ConnectionHelper.create_default_connection
  end

  after(:each) do
    ConnectionHelper.disconnect
  end

  it "Is Possible to create GoodData::Command::Project instance" do
    cmd = GoodData::Command::Project.new()
    cmd.should be_a(GoodData::Command::Project)
  end
end