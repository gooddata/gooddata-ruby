# encoding: UTF-8

require 'gooddata/models/account_settings'

describe GoodData::AccountSettings do
  before(:each) do
    ConnectionHelper.create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end
end
