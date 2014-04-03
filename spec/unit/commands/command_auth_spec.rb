require 'highline'

require 'gooddata/cli/terminal'
require 'gooddata/commands/auth'

describe GoodData::Command::Auth do
  ORIG_TERMINAL = GoodData::CLI::DEFAULT_TERMINAL

  before(:all) do
    @input = StringIO.new
    @output = StringIO.new
    @terminal = HighLine.new(@input, @output)

    GoodData::CLI::DEFAULT_TERMINAL = @terminal
  end

  after(:all) do
    GoodData::CLI::DEFAULT_TERMINAL = ORIG_TERMINAL
  end


  before(:each) do
    ConnectionHelper::create_default_connection
  end

  it "Is Possible to create GoodData::Command::Auth instance" do
    cmd = GoodData::Command::Auth.new()
    cmd.should be_a(GoodData::Command::Auth)
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
    credentials = {
      :email => 'joedoe@example.com',
      :password => 'secretPassword',
      :token => 't0k3n1sk0',
    }

    it 'Interactively asks user for crendentials' do
      pending("Mock STDIO")

      @input << credentials[:email] << "\n"
      @input << credentials[:password] << "\n"
      @input << credentials[:token] << "\n"
      @input.rewind

      GoodData::Command::Auth.ask_for_credentials
    end
  end

  describe "#store" do
    it 'Stores credentials' do
      pending("Mock STDIO")
    end
  end

  describe "#unstore" do
    it 'Removes stored credentials' do
      pending("Mock fileutils")
    end
  end
end