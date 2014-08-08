require 'highline'

require 'gooddata/cli/terminal'
require 'gooddata/commands/auth'

describe GoodData::Command::Auth do
  ORIG_TERMINAL = GoodData::CLI::DEFAULT_TERMINAL unless const_defined?(:ORIG_TERMINAL)

  DEFAULT_CREDENTIALS = {
    :email => 'joedoe@example.com',
    :password => 'secretPassword',
    :token => 't0k3n1sk0',
  }

  DEFAULT_CREDENTIALS_OVER = {
    :email => 'pepa@depo.com',
    :password => 'lokomotiva',
    :token => 'briketa',
  }

  DEFAULT_CREDENTIALS_TEMP_FILE_NAME = 'credentials'

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
    @client = ConnectionHelper::create_default_connection
  end

  after(:each) do
    @client.disconnect
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

  describe "#ask_for_credentials" do
    it 'Interactively asks user for crendentials' do
      pending("Mock STDIO")
      @input.string = ''
      @input << DEFAULT_CREDENTIALS[:email] << "\n"
      @input << DEFAULT_CREDENTIALS[:password] << "\n"
      @input << DEFAULT_CREDENTIALS[:token] << "\n"
      @input.rewind

      GoodData::Command::Auth.ask_for_credentials
    end
  end

  describe "#read_credentials" do
    it 'Reads credentials from default file if no path specified' do
      GoodData::Command::Auth.read_credentials
    end

    it 'Reads credentials from file specified' do
      temp_path = Tempfile.new(DEFAULT_CREDENTIALS_TEMP_FILE_NAME).path

      GoodData::Command::Auth.write_credentials(DEFAULT_CREDENTIALS, temp_path)

      result = GoodData::Command::Auth.read_credentials(temp_path)
      GoodData::Command::Auth.unstore(temp_path)

      result.should == DEFAULT_CREDENTIALS
    end

    it 'Returns empty hash if invalid path specified' do
      expect = {}
      result = GoodData::Command::Auth.read_credentials('/some/invalid/path')
      result.should == expect
    end
  end

  describe "#write_credentials" do
    it 'Writes credentials' do
      temp_path = Tempfile.new(DEFAULT_CREDENTIALS_TEMP_FILE_NAME).path

      result = GoodData::Command::Auth.write_credentials(DEFAULT_CREDENTIALS, temp_path)
      GoodData::Command::Auth.unstore(temp_path)

      result.should == DEFAULT_CREDENTIALS
    end
  end

  describe "#store" do
    it 'Stores credentials' do
      pending("Mock STDIO")

      @input.string = ''
      @input << DEFAULT_CREDENTIALS[:email] << "\n"
      @input << DEFAULT_CREDENTIALS[:password] << "\n"
      @input << DEFAULT_CREDENTIALS[:token] << "\n"
      @input << 'y' << "\n"
      @input.rewind

      temp_path = Tempfile.new(DEFAULT_CREDENTIALS_TEMP_FILE_NAME).path
      GoodData::Command::Auth.unstore(temp_path)
      GoodData::Command::Auth.store(temp_path)
    end

    it 'Overwrites credentials if confirmed' do
      pending("Mock STDIO")

      @input.string = ''
      @input << DEFAULT_CREDENTIALS[:email] << "\n"
      @input << DEFAULT_CREDENTIALS[:password] << "\n"
      @input << DEFAULT_CREDENTIALS[:token] << "\n"
      @input << 'y' << "\n"
      @input.rewind

      temp_path = Tempfile.new(DEFAULT_CREDENTIALS_TEMP_FILE_NAME).path
      GoodData::Command::Auth.write_credentials(DEFAULT_CREDENTIALS, temp_path)

      GoodData::Command::Auth.store(temp_path)
    end

    it 'Do not overwrites credentials if not confirmed' do
      pending("Mock STDIO")

      @input.string = ''
      @input << DEFAULT_CREDENTIALS_OVER[:email] << "\n"
      @input << DEFAULT_CREDENTIALS_OVER[:password] << "\n"
      @input << DEFAULT_CREDENTIALS_OVER[:token] << "\n"
      @input << 'n' << "\n"
      @input.rewind

      temp_path = Tempfile.new(DEFAULT_CREDENTIALS_TEMP_FILE_NAME).path
      GoodData::Command::Auth.write_credentials(DEFAULT_CREDENTIALS, temp_path)

      GoodData::Command::Auth.store(temp_path)
      result = GoodData::Command::Auth.read_credentials(temp_path)

      result.should == DEFAULT_CREDENTIALS
    end
  end

  describe "#unstore" do
    it 'Removes stored credentials' do
      temp_path = Tempfile.new(DEFAULT_CREDENTIALS_TEMP_FILE_NAME).path
      GoodData::Command::Auth.write_credentials(DEFAULT_CREDENTIALS, temp_path)
      GoodData::Command::Auth.unstore(temp_path)
    end
  end
end