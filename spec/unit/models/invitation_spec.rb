# encoding: UTF-8

require 'gooddata/models/invitation'

describe GoodData::Invitation do
  before(:each) do
    @client = ConnectionHelper.create_default_connection
  end

  after(:each) do
    @client.disconnect
  end
end
