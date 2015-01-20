# encoding: UTF-8


require 'gooddata/models/profile'
require 'gooddata/models/domain'
require 'gooddata/models/project'

describe GoodData::Profile do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
    @domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
    @user = @domain.get_user(ConnectionHelper::DEFAULT_USERNAME)

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

  def deep_dup(obj)
    Marshal.load(Marshal.dump(obj))
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
      user1 = deep_dup(@user)
      user2 = deep_dup(@user)
      res = user1 == user2
      res.should be_truthy
    end

    it 'Returns false for different objects' do
      user1 = deep_dup(@user)
      user2 = deep_dup(@user)

      # Do some little modification
      user2.first_name = 'kokos'

      res = user1 == user2
      res.should be_falsey
    end
  end

  describe '#!=' do
    it 'Returns false for same objects' do
      user1 = deep_dup(@user)
      user2 = deep_dup(@user)
      res = user1 != user2
      res.should be_falsey
    end

    it 'Returns true for different objects' do
      user1 = deep_dup(@user)
      user2 = deep_dup(@user)

      # Do some little modification
      user2.first_name = 'kokos'

      res = user1 != user2
      res.should be_truthy
    end
  end

  describe '#apply' do
    it 'When diff of two objects applied to first result should be same as second object' do
      skip("We need to resolve this in a simpler way. The assignable members seem to be too complicated")
      user1 = deep_dup(@user)
      user2 = deep_dup(@user)

      # Do some little modification
      user2.first_name = 'kokos'
      diff = user1.diff(user2)

      expect(diff).to be_instance_of(Hash)
      diff.length.should_not eql(0)

      updated_user = GoodData::Profile.create(user1.to_hash.merge(diff))

      res = user1 == user2
      res.should be_truthy
    end
  end

  describe '#diff' do
    it 'Returns empty hash for same objects' do
      user1 = deep_dup(@user)
      user2 = deep_dup(@user)
      res = user1.diff(user2)
      expect(res).to be_instance_of(Hash)
      res.length.should eql(0)
    end
  
    it 'Returns non empty hash for different objects' do
      user1 = deep_dup(@user)
      user2 = deep_dup(@user)
  
      # Do some little modification
      user2.first_name = 'kokos'
  
      res = user1.diff(user2)
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
        GoodData::Profile.new(@users[0].json.deep_dup)
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
      projects = @user.projects
      expect(projects).to be_an_instance_of(Array)

      projects.each do |project|
        expect(project).to be_an_instance_of(GoodData::Project)
      end
    end
  end
end
