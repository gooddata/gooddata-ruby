# encoding: UTF-8

require 'pmap'
require 'gooddata'

describe GoodData::Project, :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper::create_default_connection
    @project = ProjectHelper.get_default_project(:client => @client)
    @domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
  end

  after(:all) do
    @client.disconnect
  end

  describe 'projects' do
    it 'Can get all projects' do
      projects = @client.projects
      expect(projects).to_not be_nil
      expect(projects).to be_a_kind_of(Array)
      projects.pmap do |project|
        expect(project).to be_an_instance_of(GoodData::Project)
      end
    end

    it 'Returns project if ID passed' do
      expect(@project).to_not be_nil
      expect(@project).to be_a_kind_of(GoodData::Project)
      expect(@project.pid).to eq @project.pid
    end

    it 'Returns project if URL passed' do
      expect(@project).to_not be_nil
      expect(@project).to be_a_kind_of(GoodData::Project)
      expect(@project.pid).to eq @project.pid
    end

    it 'Throws an exception when invalid format of URL passed' do
      invalid_url = '/gdc/invalid_url'
      expect { GoodData::Project[invalid_url] }.to raise_error
    end
  end

  describe '#all' do
    it 'Returns all projects' do
      projects = GoodData::Project.all(:client => @client)
      expect(projects).to_not be_nil
      expect(projects).to be_a_kind_of(Array)
    end
  end

  describe '#get_role_by_identifier' do
    it 'Looks up for role by identifier' do
      role = @project.get_role_by_identifier('readOnlyUserRole')
      expect(role).to_not be_nil
      expect(role).to be_a_kind_of(GoodData::ProjectRole)
    end
  end

  describe '#get_role_by_summary' do
    it 'Looks up for role by summary' do
      role = @project.get_role_by_summary('read only user role')
      expect(role).to_not be_nil
      expect(role).to be_a_kind_of(GoodData::ProjectRole)
    end
  end

  describe '#get_role_by_title' do
    it 'Looks up for role by title' do
      role = @project.get_role_by_title('Viewer')
      expect(role).to_not be_nil
      expect(role).to be_a_kind_of(GoodData::ProjectRole)
    end
  end

  describe "#member" do
    it 'Returns GoodData::Membership when looking for existing user using login' do
      res = @project.get_user('svarovsky+gem_tester@gooddata.com')
      expect(res).to be_instance_of(GoodData::Membership)
    end

    it 'Returns GoodData::Membership when looking for existing user using URL' do
      res = @project.get_user(ConnectionHelper::DEFAULT_USER_URL)
      expect(res).to be_instance_of(GoodData::Membership)
    end

    it 'Returns GoodData::Membership when looking for existing user using GoodData::Profile' do
      user = @project.members.first
      res = @project.get_user(user)
      expect(res).to be_instance_of(GoodData::Membership)
    end

    it 'Returns null for non-existing user' do
      res = @project.get_user('john.doe@gooddata.com')
      expect(res).to be_nil
    end
  end

  describe "#member?" do
    it 'Returns true when looking for existing user using login' do
      res = @project.member?('svarovsky+gem_tester@gooddata.com')
      expect(res).to be_truthy
    end

    it 'Returns true when looking for existing user using URL' do
      res = @project.member?(ConnectionHelper::DEFAULT_USER_URL)
      expect(res).to be_truthy
    end

    it 'Returns true when looking for existing user using GoodData::Profile' do
      user = @project.members.first
      res = @project.member?(user)
      expect(res).to be_truthy
    end

    it 'Returns false for non-existing user' do
      res = @project.member?('john.doe@gooddata.com')
      expect(res).to be_falsey
    end

    it 'Returns true for existing user when using optional list' do
      list = @project.members
      res = @project.member?('svarovsky+gem_tester@gooddata.com', list)
      expect(res).to be_truthy
    end

    it 'Returns false for non-existing user when using optional list' do
      list = []
      res = @project.member?('svarovsky+gem_tester@gooddata.com', list)
      expect(res).to be_falsey
    end
  end

  describe '#members?' do
    it 'Returns array of bools when looking for existing users using GoodData::Profile' do
      users = @project.members.take(10)
      res = @project.members?(users)
      expect(res.all?).to be_truthy
    end

    it 'Support variety of inputs' do
      users = @project.members.take(1)
      res = @project.members?(users + ['john.doe@gooddata.com'])
      expect(res).to eq [true, false]
    end
  end

  # describe '#processes' do
  #   it 'Returns the processes' do
  #     @project.deploy_process('./spec/data/ruby_process',
  #                                   type: 'RUBY',
  #                                   name: 'Test ETL Process')
  #     processes = @project.processes
  #     expect(processes).to be_a_kind_of(Array)
  #     binding.pry
  #     expect(processes.count).to eq 1
  #     expect(processes.map(&:project).uniq).to eq [@project]
  #   end
  # end

  describe '#roles' do
    it 'Returns array of GoodData::ProjectRole' do
      roles = @project.roles
      expect(roles).to be_instance_of(Array)

      roles.each do |role|
        expect(role).to be_instance_of(GoodData::ProjectRole)
      end
    end
  end

  # describe '#users' do
  #   it 'Returns array of GoodData::Users' do
  # 
  #     invitations = @project.invitations
  #     expect(invitations).to_not be_nil
  #     expect(invitations).to be_instance_of(Array)
  # 
  #     users = @project.users
  #     expect(users).to be_instance_of(Array)
  # 
  #     users.each do |user|
  #       expect(user).to be_instance_of(GoodData::Membership)
  # 
  #       roles = user.roles
  #       expect(roles).to_not be_nil
  #       expect(roles).to be_instance_of(Array)
  # 
  #       roles.each do |role|
  #         expect(role).to be_instance_of(GoodData::ProjectRole)
  #       end
  # 
  #       permissions = user.permissions
  #       expect(permissions).to_not be_nil
  #       expect(permissions).to_not be_nil
  #       expect(permissions).to be_instance_of(Hash)
  # 
  #       # invitations = user.invitations
  #       # invitations.should_not be_nil
  # 
  #       if (user.email == 'tomas.korcak@gooddata.com')
  #         projects = user.projects
  #         expect(projects).to_not be_nil
  #         expect(projects).to be_instance_of(Array)
  # 
  #         projects.each do |project|
  #           expect(project).to be_instance_of(GoodData::Project)
  #         end
  #       end
  #     end
  #   end
  # end
  # 
  # describe '#add_user' do
  #   it 'Adding user without domain should fail if it is not in the project' do
  #     user = ProjectHelper.create_random_user(@client)
  #     expect do
  #       @project.add_user(user, 'Admin')
  #     end.to raise_exception(ArgumentError)
  #   end
  # 
  #   it 'Adding user with domain should be added to a project' do
  #     user = ProjectHelper.create_random_user(@client)
  #     @domain.create_users([user])
  #     res = @project.add_user(user, 'Admin', domain: @domain)
  #     expect(@project.member?(res['projectUsersUpdateResult']['successful'].first)).to be_truthy
  #   end
  # end
  # 
  # describe '#add_users' do
  #   it 'Adding user without domain should fail if it is not in the project' do
  #     users = (1..5).to_a.map do |x|
  #       {
  #         user: ProjectHelper.create_random_user(@client),
  #         role: 'Admin'
  #       }
  #     end
  #     res = @project.add_users(users)
  #     expect(res.all? { |x| x[:type] == :error }).to eq true
  #   end
  # 
  #   it 'Adding users with domain should pass and users should be added to domain' do
  #     users = (1..5).to_a.map do |x|
  #       {
  #         user: ProjectHelper.create_random_user(@client),
  #         role: 'Admin'
  #       }
  #     end
  #     @domain.create_users(users.map {|u| u[:user]})
  #     res = @project.add_users(users, domain: @domain)
  #     links = res.map {|i| i[:result]['projectUsersUpdateResult']['successful'].first}
  #     expect(@project.members?(links).all?).to be_truthy
  #     # users.map { |r| r[:user] }.each { |u| u.delete }
  #   end
  # end
  # 
  # describe '#import_users' do
  #   it "Updates user's name and surname and removes the users" do
  #     users = (1..2).to_a.map { |x| ProjectHelper.create_random_user(@client) }
  #     @project.import_users(users, domain: @domain, whitelists: [/gem_tester@gooddata.com/])
  #     expect(@domain.members?(users)).to be_truthy
  #     expect(@project.members?(users)).to be_truthy
  #     expect(@project.members.count).to eq 3
  #     # update some user stuff
  #     bill = users[0]
  #     bill.first_name = 'buffalo'
  #     bill.last_name = 'bill'
  #     # import
  #     @project.import_users(users, domain: @domain, whitelists: [/gem_tester@gooddata.com/])
  #     # it should be updated
  #     bill_changed = @domain.get_user(bill)
  #     expect(bill_changed.first_name).to eql('buffalo')
  #     expect(bill_changed.last_name).to eql('bill')
  #     expect(@project.members?(users)).to be_truthy
  #     expect(@project.members.count).to eq 3
  #     expect(@project.member?(bill_changed)).to be_truthy
  # 
  #     # remove everybody but buffalo bill.
  #     @project.import_users([bill], domain: @domain, whitelists: [/gem_tester@gooddata.com/])
  #     expect(@project.members.count).to eq 2
  #     expect(@project.member?(bill)).to be_truthy
  #     expect(@project.members?(users - [bill]).any?).to be_falsey
  # 
  #     # Add additional user while changing Buffalos surname and role.
  #     bill.last_name = 'Billie'
  #     other_guy = ProjectHelper.create_random_user(@client)
  # 
  #     additional_batch = [bill, other_guy].map { |u| {user: u, role: u.role} }
  #     @project.import_users(additional_batch, domain: @domain, whitelists: [/gem_tester@gooddata.com/])
  #     expect(@project.members.count).to eq 3
  #     expect(@project.member?(bill)).to be_truthy
  #     expect(@project.members?(users - additional_batch.map {|x| x[:user]}).any?).to be_falsey
  #   end
  # 
  #   it "Updates user's role in a project" do
  #     users = (1..5).to_a.map { |x| ProjectHelper.create_random_user(@client).to_hash }
  #     @project.import_users(users, domain: @domain, whitelists: [/gem_tester@gooddata.com/])
  # 
  #     expect(@project.members?(users)).to be_truthy
  #     user_role_changed = users[1]
  #     users_unchanged = users - [user_role_changed]
  #     new_role = users[1][:role] = users[1][:role] == "admin" ? "editor" : "admin"
  #     @project.import_users(users, domain: @domain, whitelists: [/gem_tester@gooddata.com/])
  #     expect(@project.get_user(user_role_changed).role.identifier).to eql("#{new_role}Role")
  #     expect(users_unchanged.map {|u| @project.get_user(u)}.map(&:role).map(&:title).uniq).to eq ['Editor']
  #   end
  # 
  #   it "ignores user from both project and end state batch when whitelisted" do
  #     u = @project.get_user(ConnectionHelper::DEFAULT_USERNAME)
  #     uh = u.to_hash
  #     uh[:role] = 'editor'
  # 
  #     users = (1..5).to_a.map { |x| ProjectHelper.create_random_user(@client).to_hash } + [uh]
  #     expect(@project.member?(u)).to be_truthy
  #     expect(u.role.title).to eq 'Admin'
  #     @project.import_users(users, domain: @domain, whitelists: [/gem_tester@gooddata.com/])
  #     expect(@project.member?(u)).to be_truthy
  #     expect(@project.members?(users).all?).to be_truthy
  #     expect(@project.get_user(ConnectionHelper::DEFAULT_USERNAME).role.title).to eq 'Admin'
  #   end
  # 
  # end
  # 
  # describe '#set_user_roles' do
  #   it 'Properly updates user roles as needed' do
  #     users_to_import = @domain.users.sample(5).map {|u| { user: u, role: 'admin' }}
  #     @project.import_users(users_to_import, domain: @domain, whitelists: [/gem_tester@gooddata.com/])
  #     users_without_owner = @project.users.reject { |u| u.login == ConnectionHelper::DEFAULT_USERNAME }.pselect { |u| u.role.title == 'Admin' }
  # 
  #     user_to_change = users_without_owner.sample
  #     @project.set_user_roles(user_to_change, 'editor')
  #     expect(user_to_change.role.title).to eq 'Editor'
  #     @project.set_user_roles(user_to_change, 'admin')
  #     expect(user_to_change.role.title).to eq 'Admin'
  # 
  #     # Try different notation
  #     @project.set_users_roles([user: user_to_change, role: 'editor'])
  #     expect(user_to_change.role.title).to eq 'Editor'
  #     @project.set_users_roles([user: user_to_change, role: 'admin'])
  #     expect(user_to_change.role.title).to eq 'Admin'
  #   end
  # 
  #   it 'Properly updates user roles when user specified by email and :roles specified as array of string with role names' do
  #     # pick non deleted users that are not owner and have other roles than admin or editor
  #     users = @project.users
  #     users_without_owner = users
  #       .reject { |u| u.login == ConnectionHelper::DEFAULT_USERNAME }
  #       .reject { |u| u.login =~ /^deleted/ }
  #       .pselect { |u| u.role.title =~ /^(Admin|Editor)/ }
  # 
  #     # take 10 users that we will exercise
  #     users_to_change = users_without_owner.sample(10)
  # 
  #     # alternate roles and prepare structure
  #     logins = users_to_change.map(&:login)
  #     roles = users_to_change.map { |u| u.role.title == 'Admin' ? ['Editor'] : ['Admin'] }
  # 
  #     list = users_to_change.map do |u|
  #       {
  #         :user => u.login,
  #         :roles => u.role.title == 'Admin' ? ['Editor'] : ['Admin']
  #       }
  #     end
  # 
  #     # set the roles
  #     res = @project.set_users_roles(list)
  #     expect(res.length).to equal(list.length)
  #     expect(logins.map {|l| users.find {|u| u.login == l}}.pmap {|u| u.role.title}).to eq roles.flatten
  #   end
  # 
  #   it 'Properly updates user roles when user specified by email and :roles specified as string with role name' do
  #     users = @project.users
  #     users_without_owner = users
  #       .reject { |u| u.login == ConnectionHelper::DEFAULT_USERNAME }
  #       .reject(&:deleted?)
  #       .pselect { |u| u.role.title =~ /^(Admin|Editor)/ }
  # 
  #     users_to_change = users_without_owner.sample(10)
  # 
  #     logins = users_to_change.map(&:login)
  #     roles = users_to_change.map { |u| u.role.title == 'Admin' ? 'Editor' : 'Admin' }
  # 
  #     list = users_to_change.map do |u|
  #       {
  #         :user => u.login,
  #         :roles => u.role.title == 'Admin' ? 'Editor' : 'Admin'
  #       }
  #     end
  # 
  #     res = @project.set_users_roles(list)
  #     expect(res.length).to equal(list.length)
  #     expect(logins.map {|l| users.find {|u| u.login == l}}.pmap {|u| u.role.title}).to eq roles.flatten
  #     
  #   end
  # end
  # 
  # describe '#summary' do
  #   it 'Properly gets summary of project' do
  #     res = @project.summary
  #     expect(res).to include(ProjectHelper::PROJECT_SUMMARY)
  #   end
  # end
  # 
  # describe '#title' do
  #   it 'Properly gets title of project' do
  #     res = @project.title
  #     expect(res).to include(ProjectHelper::PROJECT_TITLE)
  #   end
  # end
  # 
  # describe 'enabling and disabling users' do
  #   it 'should be able to enable and disable a user' do
  #     users_without_owner = @project.users
  #       .reject { |u| u.login == ConnectionHelper::DEFAULT_USERNAME }
  #       .reject(&:deleted?)
  #       .select(&:enabled?)
  #     user = users_without_owner.sample
  #     expect(user.enabled?).to be_truthy
  #     expect(user.disabled?).to be_falsey
  #     user.disable
  #     expect(user.disabled?).to be_truthy
  #     expect(user.enabled?).to be_falsey
  #     user.enable
  #     expect(user.enabled?).to be_truthy
  #     expect(user.disabled?).to be_falsey
  #     expect(user.project).not_to be_nil
  #   end
  # end
end
