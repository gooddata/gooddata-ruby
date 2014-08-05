# encoding: UTF-8

require 'gooddata/models/invitation'

describe GoodData::Invitation do
  before(:each) do
    ConnectionHelper.create_default_connection
  end

  after(:each) do
    ConnectionHelper.disconnect
  end
end
