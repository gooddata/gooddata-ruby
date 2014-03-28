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

  it "Connects using username and password" do
    c = ConnectionHelper.create_default_connection(ConnectionHelper::DEFAULT_USERNAME, ConnectionHelper::DEFAULT_PASSWORD)
    c.should be_a(GoodData::Connection)
  end
end