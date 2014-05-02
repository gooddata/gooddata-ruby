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

  describe '#all' do
    it 'Returns all projects' do
      pending 'Throws 403 sometimes on some machines, investigate why'
      GoodData::Project.all
    end
  end

  describe '#[]' do
    it 'Accepts :all parameter' do
      pending 'Throws 403 sometimes on some machines, investigate why'
      GoodData::Project[:all]
    end
  end

  describe '#get_roles' do
    it 'Returns array' do
      proj = get_default_proj
      roles = proj.get_roles
      expect(roles).to be_instance_of(Array)
    end
  end

  describe '#get_role_by_identifier' do
    it 'Looks up for role by identifier' do
      proj = get_default_proj
      proj.get_role_by_identifier('admin')
    end
  end

  describe '#get_role_by_title' do
    it 'Looks up for role by title' do
      proj = get_default_proj
      proj.get_role_by_title('admin')
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

end