# encoding: UTF-8

require 'gooddata/models/domain'
require 'gooddata/models/user'
require 'gooddata/models/project_role'

describe GoodData::User do
  before(:all) do
    ConnectionHelper.create_default_connection
  end

  after(:all) do
    GoodData.disconnect
  end
end
