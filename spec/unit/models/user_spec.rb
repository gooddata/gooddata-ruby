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

  describe '#==' do
    it 'Returns true for same objects' do
      user1 = GoodData.user.dup
      user2 = GoodData.user.dup
      res = user1 == user2
      res.should be_true
    end

    it 'Returns false for different objects' do
      user1 = GoodData.user.dup
      user2 = GoodData.user.dup

      # Do some little modification
      user2.first_name = 'kokos'

      res = user1 == user2
      res.should be_false
    end
  end

  describe '#!=' do
    it 'Returns false for same objects' do
      user1 = GoodData.user.dup
      user2 = GoodData.user.dup
      res = user1 != user2
      res.should be_false
    end

    it 'Returns true for different objects' do
      user1 = GoodData.user.dup
      user2 = GoodData.user.dup

      # Do some little modification
      user2.first_name = 'kokos'

      res = user1 != user2
      res.should be_true
    end
  end
end
