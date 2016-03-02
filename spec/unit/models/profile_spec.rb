# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.


require 'gooddata/models/profile'
require 'gooddata/models/domain'
require 'gooddata/models/project'

describe GoodData::Profile do
  before(:each) do
    @client = ConnectionHelper.create_default_connection
    @domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
    
    @user1 = @domain.get_user(ConnectionHelper::DEFAULT_USERNAME)
    @user2 = @domain.get_user(ConnectionHelper::DEFAULT_USERNAME)

    @users = [
      @client.create(GoodData::Profile,
        {
          'accountSetting' => {
            'email' => 'petr.cvengros@gooddata.com',
            'firstName' => 'Petr',
            'lastName' => 'Cvengros'
          }
        }
      ),

      @client.create(GoodData::Profile,
        {
          'accountSetting' => {
            'email' => 'tomas.korcak@gooddata.com',
            'firstName' => 'Tomas',
            'lastName' => 'Korcak'
          }
        }
      ),

      @client.create(GoodData::Profile,
        {
          'accountSetting' => {
            'email' => 'patrick.mcconlogue@gooddata.com',
            'firstName' => 'Patrick',
            'lastName' => 'McConlogue'

          }
        }
      ),

      @client.create(GoodData::Profile,
        {
          'accountSetting' => {
            'email' => 'tomas.svarovsky@gooddata.com',
            'firstName' => 'Tomas',
            'lastName' => 'Svarovsky'
          }
        }
      ),
    ]
  end

  after(:all) do
    @client.disconnect
  end

  describe '#[]' do
    it 'Finds the profile by URL' do
      project = ProjectHelper.get_default_project
      users = project.users
      user = GoodData::Profile[users.first.uri, :client => @client]
      expect(user).to be_kind_of(GoodData::Profile)
    end

    it 'Finds the profile by ID' do
      project = ProjectHelper.get_default_project
      users = project.users
      user = GoodData::Profile[users.first.uri.split('/').last, :client => @client]
      expect(user).to be_kind_of(GoodData::Profile)
    end
  end

  describe '#==' do
    it 'Returns true for same objects' do
      expect(@user1).to eq @user2
      expect(@user1.to_hash).to eq @user2.to_hash
    end

    it 'Returns false for different objects' do
      # Do some little modification
      @user2.first_name = 'kokos'
      expect(@user1).not_to eq @user2
      expect(@user1.to_hash).not_to eq @user2.to_hash
    end
  end

  describe '#!=' do
    it 'Returns false for same objects' do
      res = @user1 != @user2
      res.should be_falsey
    end

    it 'Returns true for different objects' do
      # Do some little modification
      @user2.first_name = 'kokos'

      res = @user1 != @user2
      res.should be_truthy
    end
  end

  describe '#apply' do
    it 'When diff of two objects applied to first result should be same as second object' do
      skip('Problem with created and updated')
      # Do some little modification
      @user2.first_name = 'kokos'
      expect(@user1).not_to eq @user2

      diff = @user1.diff(@user2)
      expect(diff).to be_instance_of(Hash)
      updated_user = GoodData::Profile.create_object(@user1.to_hash.merge(diff))
      expect(@user1).to eq updated_user
      expect(@user2).not_to eq updated_user
    end
  end

  describe '#diff' do
    it 'Returns empty hash for same objects' do
      res = @user1.diff(@user2)
      expect(res).to be_instance_of(Hash)
      res.length.should eql(0)
    end
  
    it 'Returns non empty hash for different objects' do
      # Do some little modification
      @user2.first_name = 'kokos'
  
      res = @user1.diff(@user2)
      expect(res).to be_instance_of(Hash)
      res.length.should_not eql(0)
    end
  end

  describe '#diff_list' do
    it 'Returns empty diff for same arrays' do
      l1 = [
        @users[0]
      ]
  
      l2 = [
        @users[0]
      ]
  
      diff = GoodData::Profile.diff_list(l1, l2)
      diff[:added].length.should eql(0)
      diff[:changed].length.should eql(0)
      diff[:removed].length.should eql(0)
    end
  
    it 'Recognizes added element' do
      l1 = []
  
      l2 = [
        @users[0]
      ]
  
      diff = GoodData::Profile.diff_list(l1, l2)
      diff[:added].length.should eql(1)
      diff[:changed].length.should eql(0)
      diff[:removed].length.should eql(0)
    end
  
    it 'Recognizes changed element' do
      l1 = [
        @users[0]
      ]
  
      l2 = [
        GoodData::Profile.new(GoodData::Helpers.deep_dup(@users[0].json))
      ]
      l2[0].first_name = 'Peter'
  
      diff = GoodData::Profile.diff_list(l1, l2)
      diff[:added].length.should eql(0)
      diff[:changed].length.should eql(1)
      diff[:removed].length.should eql(0)
    end
  
    it 'Recognizes removed element' do
      l1 = [
        @users[0]
      ]
  
      l2 = []
  
      diff = GoodData::Profile.diff_list(l1, l2)
      diff[:added].length.should eql(0)
      diff[:changed].length.should eql(0)
      diff[:removed].length.should eql(1)
    end
  end

  describe '#projects' do
    it 'Returns user projects as array of GoodData::Project' do
      projects = @user1.projects
      expect(projects).to be_an_instance_of(Array)

      projects.each do |project|
        expect(project).to be_an_instance_of(GoodData::Project)
      end
    end
  end
end
