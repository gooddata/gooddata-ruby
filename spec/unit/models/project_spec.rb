# encoding: UTF-8

require 'gooddata'

describe GoodData::Project do
  before(:each) do
    ConnectionHelper::create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#[]' do
    it 'Accepts :all parameter' do
      pending 'Investigate which credentials use'
      
      project = GoodData::Project[:all]
      project.should_not be_nil
      project.should be_a_kind_of(Array)
    end

    it 'Returns project if ID passed' do
      project = ProjectHelper.get_default_project
      project.should_not be_nil
      project.should be_a_kind_of(GoodData::Project)
    end

    it 'Returns project if URL passed' do
      project = ProjectHelper.get_default_project
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
      pending 'Investigate which credentials use'

      GoodData::Project.all
    end
  end

  describe '#get_role_by_identifier' do
    it 'Looks up for role by identifier' do
      project = ProjectHelper.get_default_project
      role = project.get_role_by_identifier('readOnlyUserRole')
      role.should_not be_nil
      role.should be_a_kind_of(GoodData::ProjectRole)
    end
  end

  describe '#get_role_by_summary' do
    it 'Looks up for role by summary' do
      project = ProjectHelper.get_default_project
      role = project.get_role_by_summary('read only user role')
      role.should_not be_nil
      role.should be_a_kind_of(GoodData::ProjectRole)
    end
  end

  describe '#get_role_by_title' do
    it 'Looks up for role by title' do
      project = ProjectHelper.get_default_project
      role = project.get_role_by_title('Viewer')
      role.should_not be_nil
      role.should be_a_kind_of(GoodData::ProjectRole)
    end
  end

  describe "#member" do
    it 'Returns GoodData::Membership when looking for existing user using email' do
      project = ProjectHelper.get_default_project
      res = project.member('svarovsky+gem_tester@gooddata.com')
      expect(res).to be_instance_of(GoodData::Membership)
    end

    it 'Returns GoodData::Membership when looking for existing user using URL' do
      project = ProjectHelper.get_default_project
      res = project.member(ConnectionHelper::DEFAULT_USER_URL)
      expect(res).to be_instance_of(GoodData::Membership)
    end

    it 'Returns GoodData::Membership when looking for existing user using GoodData::Profile' do
      project = ProjectHelper.get_default_project
      user = project.members.first
      res = project.member(user)
      expect(res).to be_instance_of(GoodData::Membership)
    end

    it 'Returns null for non-existing user' do
      project = ProjectHelper.get_default_project
      res = project.member('jan.kokotko@gooddata.com')
      res.should be_nil
    end
  end

  describe "#member?" do
    it 'Returns true when looking for existing user using email' do
      project = ProjectHelper.get_default_project
      res = project.member?('svarovsky+gem_tester@gooddata.com')
      res.should be_true
    end

    it 'Returns true when looking for existing user using URL' do
      project = ProjectHelper.get_default_project
      res = project.member?(ConnectionHelper::DEFAULT_USER_URL)
      res.should be_true
    end

    it 'Returns true when looking for existing user using GoodData::Profile' do
      project = ProjectHelper.get_default_project
      user = project.members.first
      res = project.member?(user)
      res.should be_true
    end

    it 'Returns false for non-existing user' do
      project = ProjectHelper.get_default_project
      res = project.member?('jan.kokotko@gooddata.com')
      res.should be_false
    end

    it 'Returns true for existing user when using optional list' do
      project = ProjectHelper.get_default_project
      list = project.members
      res = project.member?('svarovsky+gem_tester@gooddata.com', list)
      res.should be_true
    end

    it 'Returns false for non-existing user when using optional list' do
      project = ProjectHelper.get_default_project
      list = []
      res = project.member?('svarovsky+gem_tester@gooddata.com', list)
      res.should be_false
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
    it 'Returns array of GoodData::ProjectRole' do
      project = ProjectHelper.get_default_project
      roles = project.roles
      expect(roles).to be_instance_of(Array)

      roles.each do |role|
        expect(role).to be_instance_of(GoodData::ProjectRole)
      end
    end
  end

  describe '#users' do
    it 'Returns array of GoodData::Users' do
      pending 'Investigate which credentials to use'

      project = GoodData::Project[ProjectHelper::PROJECT_ID]

      invitations = project.invitations
      invitations.should_not be_nil
      expect(invitations).to be_instance_of(Array)

      users = project.users
      expect(users).to be_instance_of(Array)

      users.each do |user|
        expect(user).to be_instance_of(GoodData::Membership)

        roles = user.roles
        roles.should_not be_nil
        expect(roles).to be_instance_of(Array)

        roles.each do |role|
          expect(role).to be_instance_of(GoodData::ProjectRole)
        end

        permissions = user.permissions
        permissions.should_not be_nil
        permissions.should_not be_nil
        expect(permissions).to be_instance_of(Hash)

        # invitations = user.invitations
        # invitations.should_not be_nil

        if(user.email == 'tomas.korcak@gooddata.com')
          projects = user.projects
          projects.should_not be_nil
          expect(projects).to be_instance_of(Array)

          projects.each do |project|
            expect(project).to be_instance_of(GoodData::Project)
          end
        end
      end
    end
  end

  describe '#users_export' do
    it 'Exports users to file specified' do

      project = GoodData::Project[ProjectHelper::PROJECT_ID]

      project.users_export(CsvHelper::CSV_PATH_EXPORT)
    end
  end

  describe '#users_import' do
    it 'Import users from CSV' do

      project = GoodData::Project[ProjectHelper::PROJECT_ID]

      project.users_import(CsvHelper::CSV_PATH_IMPORT) do |row|
        {
          'user' => {
            'content' => {
              'email' => row[2],
              'login' => row[2],
              'firstname' => row[0],
              'lastname' => row[1],

              # Following lines are ugly hack
              'role' => row[6],
              'password' => row[3],
              'domain' => row[9]
            },
            'meta' => {}
          }
        }
      end

    end
  end
end