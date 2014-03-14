require 'gooddata/commands/datasets'

describe GoodData::Command::Datasets do
  before(:each) do
    @connection = ConnectionHelper::create_default_connection
  end

  it "Is Possible to create GoodData::Command::Datasets instance" do
    cmd = GoodData::Command::Datasets.new()
    cmd.should be_a(GoodData::Command::Datasets)
  end
end