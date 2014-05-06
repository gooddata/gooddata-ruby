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
      GoodData::Domain.add_user(TEST_DOMAIN_NAME, 'tomas.korcak@gooddata.com', 'password')
    end
  end

  describe '#users' do
    it 'Should list users' do
      pending 'Gem test user needs privileges for this'
      users = GoodData::Domain.users(TEST_DOMAIN_NAME)
      expect(users).to be_instance_of(Array)
      users.each do |user|
        expect(user).to be_an_instance_of(GoodData::AccountSettings)
      end
    end

    it 'Accepts pagination options - limit' do
      pending 'Gem test user needs privileges for this'
      users = GoodData::Domain.users(TEST_DOMAIN_NAME, {:limit =>1})
      expect(users).to be_instance_of(Array)
      users.each do |user|
        expect(user).to be_an_instance_of(GoodData::AccountSettings)
      end
    end

    it 'Accepts pagination options - offset' do
      pending 'Gem test user needs privileges for this'
      users = GoodData::Domain.users(TEST_DOMAIN_NAME, {:offset => 1})
      expect(users).to be_instance_of(Array)
      users.each do |user|
        expect(user).to be_an_instance_of(GoodData::AccountSettings)
      end
    end
  end
end
