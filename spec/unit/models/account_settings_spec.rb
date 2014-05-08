# encoding: UTF-8


require 'gooddata/models/account_settings'
require 'gooddata/models/domain'
require 'gooddata/models/project'

describe GoodData::AccountSettings do
  before(:all) do
    ConnectionHelper.create_default_connection
    @user = GoodData::Domain.find_user_by_login(ConnectionHelper::DEFAULT_DOMAIN, ConnectionHelper::DEFAULT_USERNAME)
  end

  after(:all) do
    GoodData.disconnect
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
