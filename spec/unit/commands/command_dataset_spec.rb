require 'gooddata/commands/datasets'

describe GoodData::Command::Datasets do
  before(:each) do
    ConnectionHelper::create_default_connection
    @cmd = GoodData::Command::Datasets.new()
  end

  after(:each) do
    GoodData.disconnect
  end

  it "Is Possible to create GoodData::Command::Datasets instance" do
    @cmd.should be_a(GoodData::Command::Datasets)
  end

  describe "#index" do
    it "Lists all datasets" do
      pending("GoodData::Command::Dataset#with_project not working")
      @cmd.index
    end
  end

  describe "#describe" do
    it "Describes dataset" do
      pending("GoodData::Command::Dataset#extract_option not working")
      @cmd.describe
    end
  end

  describe "#apply" do
    it "Creates a server-side model" do
      pending("GoodData::Command::Dataset#with_project not working")
      @cmd.apply
    end
  end

  describe "#load" do
    it "Loads a CSV file into an existing dataset" do
      pending("GoodData::Command::Dataset#with_project not working")
      @cmd.load
    end
  end
end