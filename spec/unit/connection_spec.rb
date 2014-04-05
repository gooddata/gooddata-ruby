# encoding: UTF-8

require 'gooddata/connection'

describe GoodData::Connection do
  it "Has DEFAULT_URL defined" do
    GoodData::Connection::DEFAULT_URL.should be_a(String)
  end

  it "Has LOGIN_PATH defined" do
    GoodData::Connection::LOGIN_PATH.should be_a(String)
  end

  it "Has TOKEN_PATH defined" do
    GoodData::Connection::TOKEN_PATH.should be_a(String)
  end

  describe '#connect' do
    it "Connects using username and password" do
      c = GoodData.connect(ConnectionHelper::DEFAULT_USERNAME, ConnectionHelper::DEFAULT_PASSWORD)
      c.should be_a(GoodData::Connection)
      GoodData.disconnect
    end
  end

  describe '#disconnect' do
    it "Connects using username and password" do
      GoodData.connect(ConnectionHelper::DEFAULT_USERNAME, ConnectionHelper::DEFAULT_PASSWORD)
      GoodData.disconnect
    end
  end

  describe '#connect_with_sst' do
    it 'Connects using SST' do
      pending('Get SST')
    end
  end

  describe '#create_authenticated_connection' do
    it "Creates authenticated connection" do
      pending('Investigate how the credentials should be passed')
      GoodData.connect(ConnectionHelper::DEFAULT_USERNAME, ConnectionHelper::DEFAULT_PASSWORD)
      opts = {
        :username => ConnectionHelper::DEFAULT_USERNAME,
        :password => ConnectionHelper::DEFAULT_PASSWORD
      }
      GoodData.create_authenticated_connection(opts)
      GoodData.disconnect
    end
  end
end