# encoding: UTF-8


require 'gooddata/models/profile'
require 'gooddata/models/domain'
require 'gooddata/models/project'

describe GoodData::Profile do
  before(:all) do
    ConnectionHelper.create_default_connection
    @user = GoodData::Domain.find_user_by_login(ConnectionHelper::DEFAULT_DOMAIN, ConnectionHelper::DEFAULT_USERNAME)
  end

  def deep_dup(obj)
    Marshal.load(Marshal.dump(obj))
  end

  after(:all) do
    GoodData.disconnect
  end

  describe '#==' do
    it 'Returns true for same objects' do
      user1 = deep_dup(GoodData.user)
      user2 = deep_dup(GoodData.user)
      res = user1 == user2
      res.should be_true
    end

    it 'Returns false for different objects' do
      user1 = deep_dup(GoodData.user)
      user2 = deep_dup(GoodData.user)

      # Do some little modification
      user2.first_name = 'kokos'

      res = user1 == user2
      res.should be_false
    end
  end

  describe '#!=' do
    it 'Returns false for same objects' do
      user1 = deep_dup(GoodData.user)
      user2 = deep_dup(GoodData.user)
      res = user1 != user2
      res.should be_false
    end

    it 'Returns true for different objects' do
      user1 = deep_dup(GoodData.user)
      user2 = deep_dup(GoodData.user)

      # Do some little modification
      user2.first_name = 'kokos'

      res = user1 != user2
      res.should be_true
    end
  end

  describe '#apply' do
    it 'When diff of two objects applied to first result should be same as second object' do
      user1 = deep_dup(GoodData.user)
      user2 = deep_dup(GoodData.user)

      # Do some little modification
      user2.first_name = 'kokos'

      diff = user1.diff(user2)

      expect(diff).to be_instance_of(Hash)
      diff.length.should_not eql(0)

      user1.apply(diff)

      res = user1 == user2
      res.should be_true
    end
  end

  describe '#diff' do
    it 'Returns empty hash for same objects' do
      user1 = deep_dup(GoodData.user)
      user2 = deep_dup(GoodData.user)
      res = user1.diff(user2)
      expect(res).to be_instance_of(Hash)
      res.length.should eql(0)
    end

    it 'Returns non empty hash for different objects' do
      user1 = deep_dup(GoodData.user)
      user2 = deep_dup(GoodData.user)

      # Do some little modification
      user2.first_name = 'kokos'

      res = user1.diff(user2)
      expect(res).to be_instance_of(Hash)
      res.length.should_not eql(0)
    end
  end

  describe '#projects' do
    it 'Returns user projects as array of GoodData::Project' do
      projects = @user.projects
      expect(projects).to be_an_instance_of(Array)

      projects.each do |project|
        expect(project).to be_an_instance_of(GoodData::Project)
      end
    end
  end
end
