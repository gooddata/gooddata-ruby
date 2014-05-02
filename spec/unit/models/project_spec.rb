# encoding: UTF-8

require 'gooddata'

describe GoodData::Project do
  DEFAULT_PID = 'la84vcyhrq8jwbu4wpipw66q2sqeb923'

  def get_default_proj
    GoodData::Project[DEFAULT_PID]
  end


  before(:each) do
    ConnectionHelper::create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#[]' do
    it 'Accepts :all parameter' do
      project = GoodData::Project[:all]
      project.should_not be_nil
      project.should be_a_kind_of(Array)
    end

    it 'Returns project if ID passed' do
      project = GoodData::Project[ProjectHelper::PROJECT_ID]
      project.should_not be_nil
      project.should be_a_kind_of(GoodData::Project)
    end

    it 'Returns project if URL passed' do
      project = GoodData::Project[ProjectHelper::PROJECT_URL]
      project.should_not be_nil
      project.should be_a_kind_of(GoodData::Project)
    end

    it 'Throws an exception when invalid format of URL passed' do
      invalid_url = '/gdc/invalid_url'
      expect { GoodData::Project[invalid_url] }.to raise_error
    end
  end

  describe '#all' do
    it 'Returns all projects' do
      GoodData::Project.all
    end
  end

  describe '#get_role_by_identifier' do
    it 'Looks up for role by identifier' do
      project = get_default_proj
      role = project.get_role_by_identifier('readOnlyUserRole')
      role.should_not be_nil
      role.should be_a_kind_of(GoodData::ProjectRole)
    end
  end

  describe '#get_role_by_summary' do
    it 'Looks up for role by summary' do
      project = get_default_proj
      role = project.get_role_by_summary('read only user role')
      role.should_not be_nil
      role.should be_a_kind_of(GoodData::ProjectRole)
    end
  end

  describe '#get_role_by_title' do
    it 'Looks up for role by title' do
      project = get_default_proj
      role = project.get_role_by_title('Viewer')
      role.should_not be_nil
      role.should be_a_kind_of(GoodData::ProjectRole)
    end
  end

  describe '#processes' do
    it 'Returns the processes' do
      pending 'Investigate which credentials to use'

      GoodData.project = ProjectHelper::PROJECT_ID

      proj = GoodData.project
      procs = proj.processes
    end
  end

  describe '#roles' do
    it 'Returns array' do
      proj = get_default_proj
      roles = proj.roles
      expect(roles).to be_instance_of(Array)
    end
  end
end