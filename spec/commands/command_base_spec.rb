require 'gooddata/commands/commands'

describe GoodData::Command::Base do
  before(:all) do
    NEW_COMMAND_OPTIONS = {
    }
  end

  before(:each) do
    @connection = ConnectionHelper::create_default_connection
  end

  it "Is Possible to create GoodData::Command::Base instance" do
    cb = GoodData::Command::Base.new(NEW_COMMAND_OPTIONS)
    cb.should be_a(GoodData::Command::Base)
  end

  describe "#connect" do
    it "Properly uses GoodData::Connection created by GoodData::connect" do
      # Create new instance
      cb = GoodData::Command::Base.new(NEW_COMMAND_OPTIONS)

      # Try connect
      # cb.connect
    end
  end
end