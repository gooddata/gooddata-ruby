# encoding: UTF-8

require 'gooddata/models/user'

describe GoodData::User do
  before(:each) do
    ConnectionHelper.create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end
end
