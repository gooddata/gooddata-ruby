require 'gooddata/connection'
require 'gooddata/core/connection'

describe GoodData::Connection do
  before(:all) do
    USERNAME = ConnectionHelper::DEFAULT_USERNAME
    PASSWORD = ConnectionHelper::DEFAULT_PASSWORD
  end

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
    c = ConnectionHelper::create_default_connection(USERNAME, PASSWORD)
    c.should be_a(GoodData::Connection)
  end
end