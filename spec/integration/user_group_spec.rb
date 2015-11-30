# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

describe GoodData::UserGroup do
  before(:all) do
    @bulk_size = 3

    @user_group_name = 'My Test Group'
    @user_group_description = 'My Test Description'

    @client = ConnectionHelper::create_default_connection
    @project = @client.create_project(title: 'UserGroup Testing Project', token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
    @domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)

    users = (1..5).to_a.map do |x|
      {
        user: ProjectHelper.create_random_user(@client),
        role: 'Admin'
      }
    end

    @project.add_users(users)
    @users = @project.users.to_a

    @group = @project.add_user_group(:name => @user_group_name, :description => @user_group_description)
  end

  after(:all) do
    @group && @group.delete
    @project && @project.delete
    @client.disconnect
  end

  describe '#[]' do
    it 'Should list user groups as Array' do
      res = GoodData::UserGroup[:all, :client => @client, :project => @project]
      expect(res).to be_kind_of(Array)
    end
  end

  describe '#add_members' do
    it 'Should add member' do
      users = @users.to_a.take(@bulk_size)

      old_count = @group.members.to_a.length
      @group.add_member(users)

      new_count = @group.members.to_a.length
      expect(new_count).to eql(old_count + 1)

      group_members = @group.members.to_a

      users.each do |user|
        res = group_members.find do |group_member|
          group_member.uri == user.uri
        end
        expect(res).to be_a_kind_of(GoodData::Profile)
      end
    end
  end

  describe '#set_members' do
    it 'Should set new members' do
      users = @users.to_a.take(@bulk_size)

      @group.set_members(users)

      group_members = @group.members.to_a
      expect(group_members.length).to eql(users.length)
    end
  end

  describe '#remove_members' do
    it 'Should remove existing members' do
      users = @users.to_a.take(@bulk_size)

      @group.set_members(users)

      group_members = @group.members.to_a
      expect(group_members.length).to eql(users.length)

      @group.remove_members(users)
      group_members = @group.members.to_a
      expect(group_members.length).to eql(0)
    end
  end

  describe '#members' do
    it 'Should return members as array' do
      expect(@group.members).to be_a_kind_of(Enumerator)

      members = @group.members.to_a
      expect(members).to be_kind_of(Array)
    end
  end

  describe '#name' do
    it 'Should return name of user group' do
      expect(@group.name).to eql(@user_group_name)
    end
  end

  describe '#name=' do
    it 'Should assign name of user group' do
      new_name = 'This is new name'
      @group.name = new_name
      expect(@group.name).to eql(new_name)
    end
  end

  describe '#description' do
    it 'Should return name of user group' do
      expect(@group.description).to eql(@user_group_description)
    end
  end

  describe '#description=' do
    it 'Should assign description of user group' do
      new_description = 'This is new description'
      @group.description = new_description
      expect(@group.description).to eql(new_description)
    end
  end
end
