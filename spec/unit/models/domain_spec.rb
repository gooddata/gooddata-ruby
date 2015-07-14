# encoding: UTF-8

require 'gooddata/models/domain'
require 'gooddata/helpers/csv_helper'

describe GoodData::Domain do
  before(:each) do
    @client = ConnectionHelper.create_default_connection
    @domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
  end

  after(:each) do
    @client.disconnect
  end

  describe '#add_user' do
    before(:each) do
      @user = nil
    end

    after(:each) do
      @user.delete if @user
    end

    it 'Should add user using class method' do
      args = {
        :domain => ConnectionHelper::DEFAULT_DOMAIN,
        :login => "gemtest_#{rand(1e6)}@gooddata.com",
        :password => CryptoHelper.generate_password,
      }

      @user = GoodData::Domain.add_user(args)
      expect(@user).to be_an_instance_of(GoodData::Profile)
    end

    it 'Should add user using instance method' do
      domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)

      login = "gemtest#{rand(1e6)}@gooddata.com"
      password = CryptoHelper.generate_password

      @user = domain.add_user(:login => login, :password => password, :first_name => 'X', :last_name => 'X')
      expect(@user).to be_an_instance_of(GoodData::Profile)
    end
  end

  describe '#find_user_by_login' do
    it 'Should find user by login' do
      domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
      user = domain.find_user_by_login(ConnectionHelper::DEFAULT_USERNAME)
      # user = @domain.add_user(args, client: @client)
      expect(user).to be_an_instance_of(GoodData::Profile)
      expect(user.login).to eq ConnectionHelper::DEFAULT_USERNAME
    end
  end

  describe '#users' do
    it 'Should list users' do
      users = @domain.users
      expect(users).to be_instance_of(Enumerator)
      users.each do |user|
        expect(user).to be_an_instance_of(GoodData::Profile)
      end
    end

    it 'Accepts pagination options - offset' do
      pending('not that useful and takes very long')
      users = @domain.users(offset: 1)
      expect(users).to be_instance_of(Array)
      users.each do |user|
        expect(user).to be_an_instance_of(GoodData::Profile)
      end
    end
  end

  describe '#create_users' do
    it 'Creates new users from list' do
      list = (0..1).to_a.map { |i| ProjectHelper.create_random_user(@client) }
      res = @domain.create_users(list)

      # no errors
      expect(res.select { |x| x[:type] == :user_added_to_domain }.count).to eq res.count

      expect(@domain.members?(list.map(&:login)).all?).to be_truthy

      res.map { |r| r[:user] }.each do |r|
        expect(r).to be_an_instance_of(GoodData::Profile)
        r.delete
      end
    end

    it 'Update a user' do
      user = @domain.users.reject { |u| u.login == @client.user.login }.sample
      login = user.login
      name = user.first_name
      modes = user.authentication_modes
      possible_modes = [:sso, :password]


      user.first_name = name.reverse
      choice = SpecHelper.random_choice(possible_modes, user.authentication_modes)
      user.authentication_modes = choice
      @domain.create_users([user])
      changed_user = @domain.get_user(login)
      expect(changed_user.first_name).to eq name.reverse
      expect(changed_user.authentication_modes).to eq [choice]

      user.first_name = name
      user.authentication_modes = modes
      @domain.create_users([user])
      reverted_user = @domain.get_user(login)
      expect(reverted_user.first_name).to eq name
      expect(reverted_user.authentication_modes).to eq modes
    end

    it 'Fails with an exception if you try to create a user that is in a different domain' do
      user = ProjectHelper.create_random_user(@client)
      user.login = 'svarovsky@gooddata.com'
      expect do
        @domain.create_user(user)
      end.to raise_exception(GoodData::UserInDifferentDomainError)
    end

    it 'updates properties of a profile' do
      pending 'Add more users'

      user = @domain.users
        .reject { |u| u.login == ConnectionHelper::DEFAULT_USERNAME }.sample

      old_email = user.email
      old_sso_provider = user.sso_provider || ''
      user.email = 'john.doe@gooddata.com'
      user.sso_provider = user.sso_provider.blank? ? user.sso_provider.reverse : 'some_sso_provider'
      @domain.update_user(user)
      updated_user = @domain.find_user_by_login(user.login)
      expect(updated_user.email).to eq 'john.doe@gooddata.com'
      expect(updated_user.sso_provider).to eq 'some_sso_provider'
      updated_user.email = old_email
      updated_user.sso_provider = old_sso_provider
      @domain.update_user(updated_user)
      expect(@domain.find_user_by_login(user.login).email).to eq old_email
      expect(@domain.find_user_by_login(user.login).sso_provider).to eq old_sso_provider
    end
  end
end
