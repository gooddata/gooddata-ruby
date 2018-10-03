# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/models/domain'
require 'gooddata/helpers/csv_helper'

describe GoodData::Domain, :vcr do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
    @domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
    @users_to_delete = []
  end

  after(:all) do
    @users_to_delete.map(&:login).map { |login| @domain.find_user_by_login login }.each { |user| user.delete if user }
    @client.disconnect
  end

  describe '#add_user' do
    it 'Should add user using class method' do
      args = {
        :domain => ConnectionHelper::DEFAULT_DOMAIN,
        :login => "gemtest_#{rand(1e6)}@gooddata.com",
        :password => CryptoHelper.generate_password
      }

      user = GoodData::Domain.add_user(args)
      @users_to_delete << user
      expect(user).to be_an_instance_of(GoodData::Profile)
    end

    it 'Should add user using instance method' do
      domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)

      login = "gemtest_#{rand(1e6)}@gooddata.com"
      password = CryptoHelper.generate_password

      user = domain.add_user(:login => login, :password => password, :first_name => 'X', :last_name => 'X')
      @users_to_delete << user
      expect(user).to be_an_instance_of(GoodData::Profile)
    end
  end

  describe '#find_user_by_login' do
    it 'Should find user by login' do
      domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
      user = domain.find_user_by_login(ConnectionHelper::DEFAULT_USERNAME)

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
  end

  describe '#create_users' do
    it 'Creates new users from list' do |example|
      list = ProjectHelper.ensure_users(
        client: @client,
        amount: 2,
        caller: example.description
      )
      # as the test checks if the user was actually added to domain we delete it first
      list.map(&:login).map { |u| @domain.find_user_by_login u }.map { |u| u.delete if u }

      res = @domain.create_users(list)
      @users_to_delete += list

      # no errors
      expect(res.select { |x| x[:type] == :successful && x[:action] == :user_added_to_domain }.count).to eq res.count

      expect(@domain.members?(list.map(&:login)).all?).to be_truthy

      res.select { |x| x[:type] == :successful }.map { |r| r[:user] }.each do |r|
        expect(r).to be_an_instance_of(GoodData::Profile)
      end
    end

    it 'Update a user' do
      user = @domain.users.reject { |u| u.login == @client.user.login }.first
      login = user.login
      name = user.first_name
      modes = user.authentication_modes

      user.first_name = name.reverse
      choice = :password
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

    it 'Fails with an exception if you try to create a user that is in a different domain', broken: true do |example|
      user = ProjectHelper.ensure_users(client: @client, caller: example.description)
      user.login = 'svarovsky@gooddata.com'
      expect do
        @domain.create_user(user)
      end.to raise_exception(GoodData::UserInDifferentDomainError)
    end

    it 'updates properties of a profile' do
      user = @domain.users
        .reject { |u| u.login == ConnectionHelper::DEFAULT_USERNAME }.first

      old_email = user.email
      old_sso_provider = user.sso_provider || ''
      user.email = 'john.doe@gooddata.com'
      user.sso_provider = 'some_sso_provider'
      @domain.update_user(user)
      updated_user = @domain.find_user_by_login(user.login)
      expect(updated_user.email).to eq 'john.doe@gooddata.com'
      expect(updated_user.sso_provider).to eq 'some_sso_provider'

      updated_user.sso_provider = 'some_sso_provider'.reverse
      @domain.update_user(updated_user)
      updated_user = @domain.find_user_by_login(user.login)
      expect(updated_user.sso_provider).to eq 'some_sso_provider'.reverse

      updated_user.email = old_email
      updated_user.sso_provider = old_sso_provider
      @domain.update_user(updated_user)
      expect(@domain.find_user_by_login(user.login).email).to eq old_email
      expect(@domain.find_user_by_login(user.login).sso_provider).to eq old_sso_provider
    end
  end

  describe '#clients' do
    subject { GoodData::Domain.new('my_domain') }
    let(:client) { double('client') }
    let(:clients_response) { { 'client' => { 'id' => '123' }, 'domain' => subject } }

    before do
      allow(client).to receive(:get).and_return(clients_response)
      allow(subject).to receive(:client).and_return(client)
    end

    it 'accepts an integer as the id parameter' do
      expect(client).to receive(:create).with(
        GoodData::Client,
        clients_response
      )
      subject.clients('123')
    end
  end
end
