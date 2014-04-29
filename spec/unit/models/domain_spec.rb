# encoding: UTF-8

require 'gooddata/models/domain'

describe GoodData::Domain do
  TEST_DOMAIN_NAME = 'gooddata-tomas-korcak'

  before(:each) do
    ConnectionHelper.create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#add_user' do
    it 'Should add user' do
      pending 'Gem test user needs privileges for this'
      GoodData::Domain.add_user(TEST_DOMAIN_NAME, 'tomas', 'korcak', 'tomas.korcak@gooddata.com', 'password')
    end
  end

  describe '#list_user' do
    it 'Should list users' do
      pending 'Gem test user needs privileges for this'
      GoodData::Domain.list_users(TEST_DOMAIN_NAME)
    end
  end
end
