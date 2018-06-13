# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe GoodData::Project, :vcr, :vcr_all_cassette => 'model', :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
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
      res = @project.get_user(ConnectionHelper::DEFAULT_USERNAME)
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
      res = @project.get_user(ConnectionHelper::TEST_USERNAME)
      expect(res).to be_nil
    end
  end

  describe "#member?" do
    it 'Returns true when looking for existing user using login' do
      res = @project.member?(ConnectionHelper::DEFAULT_USERNAME)
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
      res = @project.member?(ConnectionHelper::TEST_USERNAME)
      expect(res).to be_falsey
    end

    it 'Returns true for existing user when using optional list' do
      list = @project.members
      res = @project.member?(ConnectionHelper::DEFAULT_USERNAME, list)
      expect(res).to be_truthy
    end

    it 'Returns false for non-existing user when using optional list' do
      list = []
      res = @project.member?(ConnectionHelper::DEFAULT_USERNAME, list)
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
      res = @project.members?(users + [ConnectionHelper::TEST_USERNAME])
      expect(res).to eq [true, false]
    end
  end

  describe '#roles' do
    it 'Returns array of GoodData::ProjectRole' do
      roles = @project.roles
      expect(roles).to be_instance_of(Array)

      roles.each do |role|
        expect(role).to be_instance_of(GoodData::ProjectRole)
      end
    end
  end

  describe '#export_clone' do
    context 'when exclude_schedule is true' do
      let(:options) { { exclude_schedules: true } }
      let(:clone) { GoodData::Project.create(title: 'project clone', client: @client, auth_token: ConnectionHelper::GD_PROJECT_TOKEN) }

      after do
        clone.delete if clone
      end

      it 'excludes scheduled emails' do
        @project.schedule_mail.save
        export_token = @project.export_clone(options)
        clone.import_clone(export_token)
        expect(@project.scheduled_mails.to_a).not_to be_empty
        expect(clone.scheduled_mails.to_a).to be_empty
      end
    end

    context 'when cross_data_center_export is true' do
      it 'is ok' do
        # there are no staging environments on other datacenters
        # so just checking if the parameter gets accepted
        @project.export_clone(cross_data_center_export: true)
      end
    end

    context 'when export task fails' do
      let(:fail_response) do
        response = { taskState: { status: 'ERROR' } }
        GoodData::Helpers.stringify_keys(response)
      end

      before do
        allow(@client)
          .to receive(:poll_on_response).and_return(fail_response)
      end

      it 'raises ExportCloneError' do
        expect { @project.export_clone }.to raise_error(GoodData::ExportCloneError)
      end
    end
  end

  describe '#import_clone' do
    let(:clone) { GoodData::Project.create(title: 'import clone test', client: @client, auth_token: ConnectionHelper::GD_PROJECT_TOKEN) }
    let(:fail_response) do
      response = { taskState: { status: 'ERROR' } }
      GoodData::Helpers.stringify_keys(response)
    end

    after do
      clone.delete if clone
    end

    context 'when import task fails' do
      it 'raises ImportCloneError' do
        export_token = @project.export_clone
        allow(@client).to receive(:poll_on_response).and_return(fail_response)
        expect { clone.import_clone(export_token) }.to raise_error(GoodData::ImportCloneError)
      end
    end
  end
end
