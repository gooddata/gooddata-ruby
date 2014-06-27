# encoding: UTF-8

require 'gooddata'

describe GoodData::Project do
  before(:each) do
    ConnectionHelper::create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  def load_users_from_csv
    GoodData::Helpers::Csv.read(:path => CsvHelper::CSV_PATH_IMPORT, :header => true) do |row|
      json = {
        'user' => {
          'content' => {
            'email' => row[2],
            'login' => row[2],
            'firstname' => row[0],
            'lastname' => row[1],

            # Following lines are ugly hack
            'role' => row[6],
            'password' => row[3],
            'domain' => row[9],

            # And following lines are even much more ugly hack
            # 'sso_provider' => '',
            # 'authentication_modes' => ['sso', 'password']
          },
          'meta' => {}
        }
      }

      GoodData::Membership.new(json)
    end
  end

  describe '#[]' do
    it 'Accepts :all parameter' do
      projects = GoodData::Project[:all]
      projects.should_not be_nil
      projects.should be_a_kind_of(Array)
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
      projects = GoodData::Project.all
      projects.should_not be_nil
      projects.should be_a_kind_of(Array)
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

      GoodData.project = ProjectHelper::PROJECT_ID
      proj = GoodData.project
      processes = proj.processes
      expect(processes).to be_a_kind_of(Array)
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

  describe '#users_create' do
    it 'Creates new users' do
      project = ProjectHelper.get_default_project

      users = (0...10).map do |i|
        num = rand(1e6)
        login = "gemtest#{num}@gooddata.com"

        json = {
          'user' => {
            'content' => {
              'email' => login,
              'login' => login,
              'firstname' => 'the',
              'lastname' => num.to_s,

              # Following lines are ugly hack
              'role' => 'admin',
              'password' => 'password',
              'domain' => ConnectionHelper::DEFAULT_DOMAIN,

              # And following lines are even much more ugly hack
              # 'sso_provider' => '',
              # 'authentication_modes' => ['sso', 'password']
            },
            'meta' => {}
          }
        }

        GoodData::Membership.new(json)
      end

      res = GoodData::Domain.users_create(users)

      project.users_create(users)

      expect(res).to be_an_instance_of(Array)
      res.each do |r|
        expect(r).to be_an_instance_of(GoodData::Profile)
        r.delete
      end
    end
  end

  describe '#users_import' do
    it 'Import users from CSV' do

      project = GoodData::Project[ProjectHelper::PROJECT_ID]

      new_users = load_users_from_csv

      project.users_import(new_users)
    end
  end

  describe '#set_user_roles' do
    it 'Properly updates user roles as needed' do
      project = ProjectHelper.get_default_project

      project.set_user_roles(ConnectionHelper::DEFAULT_USERNAME, 'admin')
    end
  end

  describe '#set_users_roles' do
    it 'Properly updates user roles as needed for bunch of users' do
      project = ProjectHelper.get_default_project

      new_users = load_users_from_csv
      old_users = project.users
      diff = GoodData::Membership.diff_list(old_users, new_users)

      # Get changed users objects from hash
      list = diff[:changed].map do |user|
        user[:user]
      end

      # Join list of changed users with 'same' users
      list = list.zip(diff[:same]).flatten.compact

      new_users_map = Hash[new_users.map { |u| [u.email, u] }]

      # Create list with user, desired_roles hashes
      list = list.map do |user|
        {
          :user => user,
          :roles => new_users_map[user.email].json['user']['content']['role'].split(' ').map { |r| r.downcase }.sort
        }
      end

      project.set_users_roles(list)
    end

    it 'Properly updates user roles when user specified by email and :roles specified as array of string with role names' do
      project = ProjectHelper.get_default_project

      users_roles = [
        {
          :user => ConnectionHelper::DEFAULT_USERNAME,
          :roles => ['admin']
        }
      ]

      project.set_users_roles(users_roles)
    end

    it 'Properly updates user roles when user specified by email and :roles specified as string with role name' do
      project = ProjectHelper.get_default_project

      users_roles = [
        {
          :user => ConnectionHelper::DEFAULT_USERNAME,
          :roles => 'admin'
        }
      ]

      project.set_users_roles(users_roles)
    end

  end
end