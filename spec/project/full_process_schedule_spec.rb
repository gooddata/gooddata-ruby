# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe "Full process and schedule exercise", :vcr, :constraint => 'slow' do
  COMPLEX_PARAMS ||= {
    type: 'Person',
    model_version: 1,
    data_version: 1.5,
    some_true_flag: true,
    some_false_flag: false,
    empty_value: nil,
    user: {
      firstname: 'Joe',
      lastname: 'Doe',
      age: 42
    },
    address: {
      street: '#111 Sutter St.',
      city: 'San Francisco',
      zip: '94133'
    }
  }

  before(:all) do
    @client = ConnectionHelper.create_default_connection
    @project = @client.create_project(title: 'Project for schedule testing', auth_token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
    @process = @project.deploy_process('./spec/data/ruby_process',
                                       type: 'RUBY',
                                       name: 'Test ETL Process (Ruby)')

    @process_cc = @project.deploy_process('./spec/data/cc',
                                          type: 'graph',
                                          name: 'Test ETL Process (CC)')
  end

  after(:all) do
    ScheduleHelper.remove_old_schedules(@project)
    ProcessHelper.remove_old_processes(@project)

    # @process.delete if @process
    @project.delete if @project
    GoodData::ChannelConfiguration.all.map(&:delete)

    @client.disconnect
  end

  it "should be able to execute a process" do
    result = @process.execute(@process.executables.first)
    log = result.log
    expect(log.index('Hello Ruby executors')).not_to eq nil
    expect(log.index('Hello Ruby from the deep')).not_to eq nil
  end

  it "should be able to start executing a process" do
    result = @process.start_execution(@process.executables.first)
    expect(result["executionTask"]).not_to be_nil
    expect(result["executionTask"]['links']['detail']).not_to be_nil
  end

  it "should be able to grab executables" do
    expect(@process.executables).to eq ['process.rb']
  end

  it "should have empty schedules on deploy" do
    expect(@process.schedules).to eq []
  end

  it "should be able to create schedule triggered by another schedule" do
    begin
      schedule_first = @process.create_schedule('0 15 27 7 *', @process.executables.first)
      schedule = @process.create_schedule(schedule_first, @process.executables.first)
      res = @process.schedules
      expect(res.count).to eq 2
      expect(@process.schedules.map(&:uri)).to include(schedule_first.uri, schedule.uri)
    ensure
      schedule && schedule.delete
      schedule_first && schedule_first.delete
    end
  end

  it "should be able to create schedule triggered by another schedule specified by ID" do
    begin
      schedule_first = @process.create_schedule('0 15 27 7 *', @process.executables.first)
      schedule = @process.create_schedule(schedule_first.obj_id, @process.executables.first)
      res = @process.schedules
      expect(res.count).to eq 2
      expect(schedule.after).to eq schedule_first
      expect(@process.schedules.map(&:uri)).to include(schedule_first.uri, schedule.uri)
    ensure
      schedule && schedule.delete
      schedule_first && schedule_first.delete
    end
  end

  it "should be able to delete schedule" do
    begin
      schedule = @process.create_schedule('0 15 27 7 *', @process.executables.first)
      res = @process.schedules
      expect(res.count).to eq 1
      expect(@process.schedules).to eq [schedule]
    ensure
      schedule && schedule.delete
    end
  end

  it "should be possible to read status of schedule" do
    begin
      schedule = @process.create_schedule('0 15 27 7 *', @process.executables.first)
      expect(schedule.state).to eq 'ENABLED'
    ensure
      schedule && schedule.delete
    end
  end

  it "should be possible to execute schedule" do
    begin
      schedule = @process.create_schedule('0 15 27 7 *', @process.executables.first)
      executions_count = schedule.executions.count
      result = schedule.execute
      expect(result.status).to eq :ok
      log = result.log
      expect(log.index('Hello Ruby executors')).not_to eq nil
      expect(log.index('Hello Ruby from the deep')).not_to eq nil
      expect(executions_count + 1).to eq schedule.executions.count
    ensure
      schedule && schedule.delete
    end
  end

  it "should be possible to deploy only a single file" do
    process = @project.deploy_process('./spec/data/hello_world_process/hello_world.rb',
                                      type: 'RUBY',
                                      name: 'Test ETL one file Process')
    begin
      schedule = process.create_schedule('0 15 27 7 *', process.executables.first)
      result = schedule.execute
      expect(result.status).to eq :ok
      log = result.log
      expect(log.index('HELLO WORLD')).not_to eq nil
      expect(schedule.enabled?).to be_truthy
      schedule.disable
      schedule.save
      expect(schedule.enabled?).to be_falsey
      expect(schedule.disabled?).to be_truthy
      schedule.enable
      schedule.save
      expect(schedule.enabled?).to be_truthy
    ensure
      schedule && schedule.delete
      process && process.delete
    end
  end

  it "should be possible to deploy already zipped file" do
    process = @project.deploy_process('./spec/data/hello_world_process/hello_world.zip',
                                      type: 'RUBY',
                                      name: 'Test ETL zipped file Process')
    begin
      expect(process.schedules.count).to eq 0
      schedule = process.create_schedule('0 15 27 7 *', process.executables.first)
      result = schedule.execute
      expect(result.status).to eq :ok
      log = result.log
      expect(log.index('HELLO WORLD')).not_to eq nil
      expect(process.schedules.count).to eq 1
    ensure
      schedule && schedule.delete
      process && process.delete
    end
  end

  it 'should be possible to deploy and run zipped file and print GoodData::VERSION' do
    process = @project.deploy_process('./spec/data/gooddata_version_process/gooddata_version.zip',
                                      type: 'RUBY',
                                      name: 'Test ETL zipped file GoodData Process')
    begin
      expect(process.schedules.count).to eq 0
      schedule = process.create_schedule('0 15 27 7 *', process.executables.first)
      result = schedule.execute
      expect(result.status).to eq :ok
      log = result.log
      expect(log.index('GoodData::VERSION - 0.6.')).not_to eq nil
      expect(process.schedules.count).to eq 1
    ensure
      schedule && schedule.delete
      process && process.delete
    end
  end

  it 'should be possible to deploy and run directory and use nested parameters' do
    process = @project.deploy_process('./spec/data/ruby_params_process',
                                      type: 'RUBY',
                                      name: 'Test ETL dir GoodData Process')
    begin
      expect(process.schedules.count).to eq 0
      schedule = process.create_schedule('0 15 27 7 *', process.executables.first, params: COMPLEX_PARAMS)
      result = schedule.execute
      expect(result.status).to eq :ok
      log = result.log
      expect(log.index('Joe')).not_to eq nil
      expect(log.index('San Francisco')).not_to eq nil
      expect(process.schedules.count).to eq 1
    ensure
      schedule && schedule.delete
      process && process.delete
    end
  end

  it 'should be possible to deploy and run directory and use nested hidden parameters' do
    process = @project.deploy_process('./spec/data/ruby_params_process',
                                      type: 'RUBY',
                                      name: 'Test ETL dir GoodData Process')
    begin
      expect(process.schedules.count).to eq 0
      schedule = process.create_schedule('0 15 27 7 *', process.executables.first, hidden_params: COMPLEX_PARAMS)
      result = schedule.execute
      # expect(result.status).to eq :ok
      result.log
      expect(process.schedules.count).to eq 1
    ensure
      schedule && schedule.delete
      process && process.delete
    end
  end

  it "should be possible to download deployed process" do
    size = File.size('./spec/data/hello_world_process/hello_world.zip')
    process = @project.deploy_process('./spec/data/hello_world_process/hello_world.zip',
                                      type: 'RUBY',
                                      name: 'Test ETL zipped file Process')
    begin
      Tempfile.open('downloaded-process') do |temp|
        temp << process.download
        temp.flush
        expect(File.size(temp.path)).to eq size
      end
    ensure
      process && process.delete
    end
  end

  it "should be able to redeploy via project" do
    begin
      process = @project.deploy_process('./spec/data/hello_world_process/hello_world.zip',
                                        type: 'RUBY',
                                        name: 'Test ETL zipped file Process',
                                        process_id: @process.obj_id)
    ensure
      process && process.delete
    end
  end

  it "should be able to redeploy directly" do
    begin
      process1 = @project.deploy_process(
        './spec/data/hello_world_process/hello_world.zip',
        type: 'RUBY',
        name: 'Test ETL zipped file Process'
      )

      process2 = process1.deploy('./spec/data/ruby_process/process.rb')
      expect(process1.executables).not_to eq process2.executables
    ensure
      process1 && process1.delete
    end
  end

  it 'should be able to deploy from app_store' do
    begin
      process = @project.deploy_process('${PRODUCTION_APPSTORE}:branch/master:/apps/hello_world_brick', name: 'hello_world_brick')
      expect(process.class).to eq GoodData::Process
    ensure
      process.delete if process
    end
  end

  it 'should be able to clone with etl' do
    begin
      # Deploy two schedules
      process = @project.processes.first
      schedule_first = process.create_schedule('0 15 27 7 *', process.executables.first)
      schedule_second = process.create_schedule('0 15 27 8 *', process.executables.first)
      cloned_project = GoodData::Project.clone_with_etl(@project, auth_token: ConnectionHelper::GD_PROJECT_TOKEN)
      a = @project.processes.flat_map { |p| p.schedules.map { |s| [p.name, s.name] } }
      b = cloned_project.processes.flat_map { |p| p.schedules.map { |s| [p.name, s.name] } }
      expect(a).to eq b
    ensure
      cloned_project && cloned_project.delete
      schedule_first && schedule_first.delete
      schedule_second && schedule_second.delete
    end
  end

  it 'should have no notification when creating a new process' do
    begin
      process = @project.deploy_process('./spec/data/ruby_params_process', type: 'RUBY', name: 'Ruby params process')
      expect(process.notification_rules).to eq []
    ensure
      process && process.delete
    end
  end

  it 'should be able to add a notification rule' do
    begin
      process = @project.deploy_process('./spec/data/ruby_params_process', type: 'RUBY', name: 'Ruby params process')
      old_notification_rules = process.notification_rules
      notification_rule = process.create_notification_rule(email: ConnectionHelper::DEFAULT_USERNAME, events: GoodData::Subscription::PROCESS_SUCCESS_EVENT)
      expect(notification_rule.class).to be GoodData::NotificationRule
      expect(old_notification_rules).not_to include(notification_rule)
      new_notification_rules = process.notification_rules
      expect(new_notification_rules).to include(notification_rule)
      expect(old_notification_rules.length + 1).to eq new_notification_rules.length
    ensure
      notification_rule && notification_rule.delete
      process && process.delete
    end
  end

  it 'should be able to remove a notification rule' do
    begin
      process = @project.deploy_process('./spec/data/ruby_params_process', type: 'RUBY', name: 'Ruby params process')
      old_notification_rules = process.notification_rules
      notification_rule = process.create_notification_rule(email: ConnectionHelper::DEFAULT_USERNAME, events: GoodData::Subscription::PROCESS_SUCCESS_EVENT)
      notification_rule.delete
      new_notification_rules = process.notification_rules
      expect(new_notification_rules).to eq old_notification_rules
    ensure
      process && process.delete
    end
  end

  it 'should be able to edit a notification rule' do
    begin
      process = @project.deploy_process('./spec/data/ruby_params_process', type: 'RUBY', name: 'Ruby params process')
      notification_rule = process.create_notification_rule(email: ConnectionHelper::DEFAULT_USERNAME, events: GoodData::Subscription::PROCESS_SUCCESS_EVENT)
      expect(notification_rule.email).to eq ConnectionHelper::DEFAULT_USERNAME
      expect(notification_rule.subject).to eq 'Email subject'
      expect(notification_rule.body).to eq 'Email body'
      expect(notification_rule.events).to eq [GoodData::Subscription::PROCESS_SUCCESS_EVENT]

      notification_rule = GoodData::NotificationRule[notification_rule.notification_rule_id, project: @project, process: process, client: @client]
      notification_rule.events = [GoodData::Subscription::PROCESS_SUCCESS_EVENT, GoodData::Subscription::PROCESS_STARTED_EVENT]
      notification_rule.save

      expect(process.notification_rules.first.events).to eq [GoodData::Subscription::PROCESS_SUCCESS_EVENT, GoodData::Subscription::PROCESS_STARTED_EVENT]
    ensure
      notification_rule && notification_rule.delete
      process && process.delete
    end
  end

  it 'should be able to get all notification rules' do
    begin
      process = @project.deploy_process('./spec/data/ruby_params_process', type: 'RUBY', name: 'Ruby params process')
      notification_rule = process.create_notification_rule(email: ConnectionHelper::DEFAULT_USERNAME, events: GoodData::Subscription::PROCESS_SUCCESS_EVENT)
      expect(process.notification_rules).to eq [notification_rule]
    ensure
      notification_rule && notification_rule.delete
      process && process.delete
    end
  end
end
