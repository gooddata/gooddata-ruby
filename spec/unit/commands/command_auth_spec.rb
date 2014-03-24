require 'gooddata/commands/auth'

describe GoodData::Command::Auth do
  before(:each) do
    @connection = ConnectionHelper::create_default_connection
  end

  it "Is Possible to create GoodData::Command::Auth instance" do
    cmd = GoodData::Command::Auth.new()
    cmd.should be_a(GoodData::Command::Auth)
  end

  describe "#connect" do
    it "Connects to GoodData Platform" do
      GoodData::Command::Auth.connect
    end
  end

  describe "#user" do
    it "Returns user" do
      GoodData::Command::Auth.user
    end
  end

  describe "#password" do
    it "Returns password" do
      GoodData::Command::Auth.user
    end
  end

  describe "#url" do
    it "Returns url" do
      GoodData::Command::Auth.url
    end
  end

  describe "#auth_token" do
    it "Returns authentication token" do
      GoodData::Command::Auth.auth_token
    end
  end

  describe "#credentials_file" do
    it "Returns credentials_file" do
      GoodData::Command::Auth.credentials_file
    end
  end

  describe "#ensure_credentials" do
    it "Ensures credentials existence" do
      pending("Mock STDIO")
    end
  end

  describe "#ask_for_credentials" do
    it 'Interactively asks user for crendentials' do
      pending("Mock STDIO")
    end
  end

  describe "#store" do
    it 'Stores credentials' do
      pending("Mock STDIO")
    end
  end

  describe "#unstore" do
    it 'Removes stored credentials' do
      pending("Mock STDIO")
    end
  end
end