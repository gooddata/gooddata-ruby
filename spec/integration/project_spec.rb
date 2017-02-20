# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'pmap'
require 'gooddata'

describe GoodData::Project, :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
    @project = @client.create_project(title: ProjectHelper::PROJECT_TITLE, auth_token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
    @domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
  end

  after(:all) do
    @project && @project.delete
    @client.disconnect
  end

  describe '#add_user' do
    it 'Adding user without domain should fail if it is not in the domain' do
      user = ProjectHelper.create_random_user(@client)
      expect do
        @project.add_user(user, 'Admin')
      end.to raise_exception(ArgumentError)
    end

    it 'Adding user with domain should be added to a project' do
      user = ProjectHelper.create_random_user(@client)
      @domain.create_users([user])
      res = @project.add_user(user, 'Admin', domain: @domain)
      login = GoodData::Helpers.last_uri_part(res['projectUsersUpdateResult']['successful'].first)
      expect(@project.member?(login)).to be_truthy
    end
  end

  describe '#add_users' do
    it 'Adding user without domain should fail if it is not in the project' do
      users = (1..5).to_a.map do
        {
          user: ProjectHelper.create_random_user(@client),
          role: 'Admin'
        }
      end

      res = @project.add_users(users)
      expect(res.select { |r| r[:type] == :failed }.count).to eq users.length
    end

    it 'Adding users with domain should pass and users should be added to domain' do
      users = (1..5).to_a.map do
        {
          user: ProjectHelper.create_random_user(@client),
          role: 'Admin'
        }
      end
      @domain.create_users(users.map { |u| u[:user] })
      res = @project.add_users(users, domain: @domain)
      links = res.select { |r| r[:type] == :successful }.map { |i| GoodData::Helpers.last_uri_part(i[:user]) }
      expect(@project.members?(links).all?).to be_truthy
    end
  end

  describe '#import_users' do
    it "Updates user's name and surname and removes the users" do
      users = (1..2).to_a.map { ProjectHelper.create_random_user(@client) }
      @domain.create_users(users)
      @project.import_users(users, domain: @domain, whitelists: [/tester@gooddata.com/])
      expect(@domain.members?(users)).to be_truthy
      expect(@project.members?(users)).to be_truthy
      expect(@project.members.count).to eq 3
      # update some user stuff
      bill = users[0]
      bill.first_name = 'buffalo'
      bill.last_name = 'bill'
      # import
      @domain.create_users(users, domain: @domain, whitelists: [/tester@gooddata.com/])
      @project.import_users(users, domain: @domain, whitelists: [/tester@gooddata.com/])
      # it should be updated
      bill_changed = @domain.get_user(bill)
      expect(bill_changed.first_name).to eq 'buffalo'
      expect(bill_changed.last_name).to eq 'bill'
      expect(@project.members?(users)).to be_truthy
      expect(@project.members.count).to eq 3
      expect(@project.member?(bill_changed)).to be_truthy

      # remove everybody but buffalo bill.
      @project.import_users([bill], domain: @domain, whitelists: [/tester@gooddata.com/])
      expect(@project.members.count).to eq 2
      expect(@project.member?(bill)).to be_truthy
      disabled_users = users - [bill]
      expect(@project.members?(disabled_users).any?).to be_falsey
      disabled_users.each do |user|
        expect(@project.users(disabled: true).find { |member| member.login.downcase == user.login.downcase }).not_to be_nil
      end

      # remove completely everybody but buffalo bill.
      @project.import_users([bill], domain: @domain, whitelists: [/gem_tester@gooddata.com/], remove_users_from_project: true)
      expect(@project.members.count).to eq 2
      expect(@project.member?(bill)).to be_truthy
      expect(@project.members?(disabled_users).any?).to be_falsey
      disabled_users.each do |user|
        expect(@project.users(disabled: true).find { |member| member.login.downcase == user.login.downcase }).to be_nil
      end

      # Add additional user while changing Buffalos surname and role.
      bill.last_name = 'Billie'
      other_guy = ProjectHelper.create_random_user(@client)
      additional_batch = [bill, other_guy]

      @domain.create_users(additional_batch, domain: @domain)
      @project.import_users(additional_batch.map { |u| { user: u, role: u.role } }, domain: @domain, whitelists: [/tester@gooddata.com/])

      expect(@project.members.count).to eq 3
      expect(@project.member?(bill)).to be_truthy
      expect(@project.members?(users - additional_batch).any?).to be_falsey
    end

    it "Updates user's role in a project" do
      users = (1..5).to_a.map { ProjectHelper.create_random_user(@client).to_hash }
      @domain.create_users(users, domain: @domain)
      @project.import_users(users, domain: @domain, whitelists: [/tester@gooddata.com/])

      expect(@project.members?(users)).to be_truthy
      user_role_changed = users[1]
      users_unchanged = users - [user_role_changed]
      new_role = users[1][:role] = users[1][:role] == "admin" ? "editor" : "admin"
      @project.import_users(users, domain: @domain, whitelists: [/tester@gooddata.com/])
      expect(@project.get_user(user_role_changed).role.identifier).to eq "#{new_role}Role"
      expect(users_unchanged.map { |u| @project.get_user(u) }.map(&:role).map(&:title).uniq).to eq ['Editor']
    end

    it "ignores user from both project and end state batch when whitelisted" do
      u = @project.get_user(ConnectionHelper::DEFAULT_USERNAME)
      uh = u.to_hash
      uh[:role] = 'editor'

      users = (1..5).to_a.map { ProjectHelper.create_random_user(@client).to_hash } + [uh]
      @domain.create_users(users, domain: @domain)
      expect(@project.member?(u)).to be_truthy
      expect(u.role.title).to eq 'Admin'
      @project.import_users(users, domain: @domain, whitelists: [/tester@gooddata.com/])
      expect(@project.member?(u)).to be_truthy
      expect(@project.members?(users).all?).to be_truthy
      expect(@project.get_user(ConnectionHelper::DEFAULT_USERNAME).role.title).to eq 'Admin'
    end
  end

  describe '#set_user_roles' do
    it 'Properly updates user roles as needed' do
      users_to_import = @domain.users.drop(rand(100)).take(5).map { |u| { user: u, role: 'admin' } }
      @project.import_users(users_to_import, domain: @domain, whitelists: [/tester@gooddata.com/])
      users_without_owner = @project.users.reject { |u| u.login == ConnectionHelper::DEFAULT_USERNAME }.pselect { |u| u.role.title == 'Admin' }

      user_to_change = users_without_owner.sample
      @project.set_user_roles(user_to_change, 'editor')
      expect(user_to_change.role.title).to eq 'Editor'
      @project.set_user_roles(user_to_change, 'admin')
      expect(user_to_change.role.title).to eq 'Admin'

      # Try different notation
      @project.set_users_roles([user: user_to_change, role: 'editor'])
      expect(user_to_change.role.title).to eq 'Editor'
      @project.set_users_roles([user: user_to_change, role: 'admin'])
      expect(user_to_change.role.title).to eq 'Admin'
    end

    it 'Properly updates user roles when user specified by email and :roles specified as array of string with role names' do
      # pick non deleted users that are not owner and have other roles than admin or editor
      users = @project.users
      users_without_owner = users
        .reject { |u| u.login == ConnectionHelper::DEFAULT_USERNAME }
        .reject { |u| u.login =~ /^deleted/ }
        .pselect { |u| u.role.title =~ /^(Admin|Editor)/ }

      # take 10 users that we will exercise
      users_to_change = users_without_owner.sample(10)

      # alternate roles and prepare structure
      logins = users_to_change.map(&:login)
      roles = users_to_change.map { |u| u.role.title == 'Admin' ? ['Editor'] : ['Admin'] }

      list = users_to_change.map do |u|
        {
          :user => u.login,
          :roles => u.role.title == 'Admin' ? ['Editor'] : ['Admin']
        }
      end

      # set the roles
      res = @project.set_users_roles(list)
      expect(res.select { |r| r[:type] == :successful }.length).to equal(list.length)
      expect(logins.map { |l| users.find { |u| u.login == l } }.pmap { |u| u.role.title }).to eq roles.flatten
    end

    it 'Properly updates user roles when user specified by email and :roles specified as string with role name' do
      users = @project.users
      users_without_owner = users
        .reject { |u| u.login == ConnectionHelper::DEFAULT_USERNAME }
        .reject(&:deleted?)
        .pselect { |u| u.role.title =~ /^(Admin|Editor)/ }

      users_to_change = users_without_owner.sample(10)

      logins = users_to_change.map(&:login)
      roles = users_to_change.map { |u| u.role.title == 'Admin' ? 'Editor' : 'Admin' }

      list = users_to_change.map do |u|
        {
          :user => u.login,
          :roles => u.role.title == 'Admin' ? 'Editor' : 'Admin'
        }
      end

      res = @project.set_users_roles(list)
      expect(res.select { |r| r[:type] == :successful }.length).to equal(list.length)
      expect(logins.map { |l| users.find { |u| u.login == l } }.pmap { |u| u.role.title }).to eq roles.flatten
    end

    it 'can work with groups as well. Groups have to be set up. It can only eat hashes on input in this case' do
      users = (1..5).to_a.map { ProjectHelper.create_random_user(@client).to_hash }
      group_names = %w(group_1 group_2)
      groups = group_names.map { |g| @project.create_group(name: g) }
      users_with_groups = users.map do |u|
        u[:user_group] = groups.take(rand(2) + 1).map(&:name)
        u
      end
      @domain.create_users(users_with_groups, domain: @domain)
      @project.import_users(users_with_groups, domain: @domain, whitelists: [/tester@gooddata.com/])
      expect(users_with_groups.flat_map { |u| u[:user_group].map { |g| [u[:login], g] } }.all? do |u, g|
        begin
          @project.user_groups(g).member?(@project.member(u).uri)
        rescue
          false
        end
      end).to be_truthy

      users_with_group = users.map do |u|
        u[:user_group] = ['group_1']
        u
      end
      to_whitelist = @project.user_groups('group_2').members.to_a.sample
      @project.import_users(users_with_group, domain: @domain, whitelists: [to_whitelist.login, /tester@gooddata.com/])
      expect(@project.user_groups('group_2').members.map(&:login)).to eq [to_whitelist.login]
      expect(users_with_group.flat_map { |u| u[:user_group].map { |g| [u[:login], g] } }.all? do |u, g|
        begin
          @project.user_groups(g).member?(@project.member(u).uri)
        rescue
          false
        end
      end).to be_truthy
    end
  end

  describe '#summary' do
    it 'Properly gets summary of project' do
      res = @project.summary
      expect(res).to include(ProjectHelper::PROJECT_SUMMARY)
    end
  end

  describe '#title' do
    it 'Properly gets title of project' do
      res = @project.title
      expect(res).to include(ProjectHelper::PROJECT_TITLE)
    end
  end

  describe 'enabling and disabling users' do
    it 'should be able to enable and disable a user' do
      users_without_owner = @project.users
        .reject { |u| u.login == ConnectionHelper::DEFAULT_USERNAME }
        .reject(&:deleted?)
        .select(&:enabled?)
      user = users_without_owner.sample
      expect(user.enabled?).to be_truthy
      expect(user.disabled?).to be_falsey
      user.disable
      expect(user.disabled?).to be_truthy
      expect(user.enabled?).to be_falsey
      user.enable
      expect(user.enabled?).to be_truthy
      expect(user.disabled?).to be_falsey
      expect(user.project).not_to be_nil
    end
  end

  describe 'color palette' do
    it 'should return empty when project is not set color' do
      expect(@project.current_color_palette.colors).to eq []
    end

    it 'should be able to set custom color' do
      colors = [{ r: 155, g: 255, b: 0 }]
      @project.create_custom_color_palette(colors)
      expect(@project.current_color_palette.colors).to eq colors
    end

    it 'should be able to reset custom color' do
      colors = [{ r: 155, g: 255, b: 0 }]
      @project.create_custom_color_palette(colors)
      @project.reset_color_palette
      expect(@project.current_color_palette.colors).to eq []
    end

    it 'should not contains duplicate color' do
      colors = [{ r: 155, g: 255, b: 0 }, { r: 155, g: 255, b: 0 }]
      @project.create_custom_color_palette(colors)
      expect(@project.current_color_palette.colors).to eq [{ r: 155, g: 255, b: 0 }]
    end
  end
end
