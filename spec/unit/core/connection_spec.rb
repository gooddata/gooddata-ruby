require 'gooddata/connection'

describe GoodData::Connection do
  before(:all) do
    USERNAME = DEFAULT_USERNAME
    PASSWORD = DEFAULT_PASSWORD
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
    pending("This will no longer work. Discuss with Korczis")
    c = ConnectionHelper::create_default_connection(USERNAME, PASSWORD)
    c.should be_a(GoodData::Connection)
  end
end