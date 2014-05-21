# encoding: UTF-8

require 'gooddata/models/domain'

describe GoodData::Domain do
  before(:each) do
    ConnectionHelper.create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#add_user' do
    it 'Should add user' do
      GoodData::Domain.add_user(:domain => ConnectionHelper::DEFAULT_DOMAIN, :login => "gemtest#{rand(1e6)}@gooddata.com", :password => 'password')
    end
  end

  describe '#users' do
    it 'Should list users' do
      users = GoodData::Domain.users(ConnectionHelper::DEFAULT_DOMAIN)
      expect(users).to be_instance_of(Array)
      users.each do |user|
        expect(user).to be_an_instance_of(GoodData::Profile)
      end
    end

    it 'Accepts pagination options - limit' do
      users = GoodData::Domain.users(ConnectionHelper::DEFAULT_DOMAIN, {:limit =>1})
      expect(users).to be_instance_of(Array)
      users.each do |user|
        expect(user).to be_an_instance_of(GoodData::Profile)
      end
    end

    it 'Accepts pagination options - offset' do
      users = GoodData::Domain.users(ConnectionHelper::DEFAULT_DOMAIN, {:offset => 1})
      expect(users).to be_instance_of(Array)
      users.each do |user|
        expect(user).to be_an_instance_of(GoodData::Profile)
      end
    end
  end
end
