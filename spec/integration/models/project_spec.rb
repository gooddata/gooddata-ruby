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
    projects = @client.projects(:all)
    @number_project = projects.nil? ? 0 : projects.length
  end

  after(:all) do
    @client.disconnect
  end

  describe 'projects' do
    it 'Can get all projects and not limit' do
      projects = @client.projects(:all)
      expect(projects).to_not be_nil
      expect(projects).to be_a_kind_of(Array)

      projects.pmap do |project|
        expect(project).to be_an_instance_of(GoodData::Project)
      end
    end

    it 'Can get all projects with number limit' do
      projects = @client.projects(:all, 450)
      expect(projects).to_not be_nil
      expect(projects).to be_a_kind_of(Array)
      projects.pmap do |project|
        expect(project).to be_an_instance_of(GoodData::Project)
      end

      count_expected = @number_project > 450 ? 450 : @number_project

      expect(projects.length).to eq count_expected
    end

    it 'Can get all projects with max limit' do
      projects = @client.projects(:all, 1000)
      expect(projects).to_not be_nil
      expect(projects).to be_a_kind_of(Array)
      projects.pmap do |project|
        expect(project).to be_an_instance_of(GoodData::Project)
      end

      count_expected = @number_project > 500 ? 500 : @number_project

      expect(projects.length).to eq count_expected
    end


    it 'Can get all projects with limit and offset' do
      if (@number_project > 100)
        projects = @client.projects(:all, 400, 100)
        expect(projects).to_not be_nil
        expect(projects).to be_a_kind_of(Array)

        projects.pmap do |project|
          expect(project).to be_an_instance_of(GoodData::Project)
        end

        count_expected = @number_project > 500 ? 500 : @number_project

        expect(projects.length).to eq count_expected - 100
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
      projects = GoodData::Project.all({ client: @client }, 100)
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

  describe 'cloning' do
    let(:clone) { GoodData::Project.create(title: 'project clone', client: @client, auth_token: ConnectionHelper::SECRETS[:gd_project_token]) }
    describe '#export_clone' do
      context 'when exclude_schedule is true' do
        let(:options) { { exclude_schedules: true } }

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

  describe '#transfer_processes and #transfer_schedules' do
    let(:extra_process_name) { 'this process should be deleted' }
    before(:all) do
      @to_project = @client.create_project(
        title: '#transfer_processes and #transfer_schedules test',
        auth_token: ConnectionHelper::SECRETS[:gd_project_token],
        environment: ProjectHelper::ENVIRONMENT
      )
      @to_project.deploy_process(
        RUBY_HELLO_WORLD_PROCESS_PATH,
        name: 'this process should be deleted'
      )

      process_in_both_projects = @to_project.deploy_process(
        RUBY_HELLO_WORLD_PROCESS_PATH,
        name: 'Simple Ruby Process'
      )
      process_in_both_projects.create_schedule(
        nil,
        'main.rb',
        name: 'this schedule should be deleted'
      )

      etl_component = {
        name: 'test etl component',
        type: :etl,
        component: {
          name: 'gdc-etl-sql-executor',
          version: '1'
        }
      }

      @dataload_component = @project.deploy_process(etl_component)

      @data_source_id = GoodData::Helpers::DataSourceHelper.create_snowflake_data_source(@client)

      add_component_data = {
        name: ADD_V2_COMPONENT_NAME,
        type: :etl,
        component: {
          name: 'gdc-data-distribution',
          version: '1',
          config: {
            dataDistribution: {
              dataSource: @data_source_id
            }
          }
        }
      }

      @add_component = GoodData::Process.deploy_component(
        add_component_data,
        project: @project,
        client: @client
      )
      @add_component.create_schedule(nil, 'add-component-schedule')

      @from_processes = @project.processes.map(&:name).sort
      @from_schedules = @project.schedules.map(&:name).sort
      @project.transfer_processes(@to_project)
      @project.transfer_schedules(@to_project)
      @to_processes = @to_project.processes.map(&:name).sort
      @to_schedules = @to_project.schedules.map(&:name).sort
    end

    after(:all) do
      @add_component.delete if @add_component
      @dataload_component.delete if @dataload_component
      @to_project.delete if @to_project
      GoodData::Helpers::DataSourceHelper.delete(@client, @data_source_id) if @data_source_id
    end

    it 'keeps processes in the original project untouched' do
      expect(@from_processes).to eq(@project.processes.map(&:name).sort)
    end

    it 'transfers processes to the target project' do
      transferrable_processes = @from_processes - [ADD_V2_COMPONENT_NAME]
      expect(@to_processes).to eq(transferrable_processes)
    end

    it 'transfers etl components' do
      expect(@from_processes).to include('test etl component')
      expect(@to_processes).to include('test etl component')
    end

    it 'does not transfer ADDv2 components' do
      expect(@from_processes).to include(ADD_V2_COMPONENT_NAME)
      expect(@to_processes).not_to include(ADD_V2_COMPONENT_NAME)
    end

    it 'deletes extra processes in the target project' do
      expect(@from_processes).not_to include(extra_process_name)
      expect(@to_processes).not_to include(extra_process_name)
    end

    it 'keeps schedules in the original project untouched' do
      expect(@from_schedules).to eq(@project.schedules.map(&:name).sort)
    end

    it 'transfers schedules to the target project' do
      transferrable_schedules = @from_schedules - ['add-component-schedule']
      expect(@to_schedules).to eq(transferrable_schedules)
    end

    it 'deletes extra schedules in the target project' do
      expect(@to_schedules).not_to include(
        'this schedule should be deleted'
      )
    end

    it 'is idempotent' do
      @project.transfer_processes(@to_project)
      @project.transfer_schedules(@to_project)
      expect(@to_processes).to eq(@to_project.processes.map(&:name).sort)
      expect(@to_schedules).to eq(@to_project.schedules.map(&:name).sort)
    end
  end
end
