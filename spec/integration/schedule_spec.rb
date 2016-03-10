# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/models/schedule'
require 'gooddata/helpers/global_helpers'

describe GoodData::Schedule do
  SCHEDULE_ID = ScheduleHelper::SCHEDULE_ID
  SCHEDULE_URL = "/gdc/projects/#{ProjectHelper::PROJECT_ID}/schedules/#{SCHEDULE_ID}"

  before(:all) do
    @client = ConnectionHelper.create_default_connection

    @project = ProjectHelper.get_default_project(:client => @client)

    # ScheduleHelper.remove_old_schedules(@project)
    # ProcessHelper.remove_old_processes(@project)
  end

  before(:each) do
    @client = ConnectionHelper.create_default_connection

    @project = ProjectHelper.get_default_project(:client => @client)
    @test_cron = '0 15 27 7 *'
    @test_data = {
      :timezone => 'UTC',
      :cron => '2 2 2 2 *',
      :client => @client,
      :project => @project,
      :params => {
        'a' => 'b',
        'b' => 'c'
      }
    }

    @test_data_with_optional_param = {
      :timezone => 'UTC',
      :cron => '2 2 2 2 *',
      :reschedule => 15,
      :client => @client,
      :project => @project
    }
  end

  after(:each) do
    @client.disconnect
  end

  describe '#[]' do
    it 'Returns all schedules when :all passed' do
      res = @project.schedules
      res.should_not be_nil
      res.should be_a_kind_of(Array)
      res.each do |schedule|
        schedule.should be_a_kind_of(GoodData::Schedule)
      end
    end

    it 'Returns specific schedule when schedule ID passed' do
      res = @project.schedules(SCHEDULE_ID)
      res.should_not be_nil
      res.should be_a_kind_of(GoodData::Schedule)
    end

    it 'Returns specific schedule when schedule URL passed' do
      res = @project.schedules(SCHEDULE_ID)
      res.should_not be_nil
      res.should be_a_kind_of(GoodData::Schedule)
    end
  end

  describe '#all' do
    it 'Returns all schedules' do
      res = @project.schedules
      res.should_not be_nil
      res.should be_a_kind_of(Array)
      res.each do |schedule|
        schedule.should be_a_kind_of(GoodData::Schedule)
      end
    end
  end

  describe '#create' do
    it 'Creates new schedule if mandatory params passed' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        expect(schedule).to be_truthy
      ensure
        schedule && schedule.delete
      end
    end

    it 'Creates new schedule if mandatory params passed and optional params are present' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data_with_optional_param)
        expect(schedule).to be_truthy
      ensure
        schedule && schedule.delete
      end
    end

    it 'Throws exception when no process ID specified' do
      schedule = nil
      begin
        expect {
          schedule = @project.create_schedule(nil, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        }.to raise_error 'Process ID has to be provided'
      ensure
        schedule && schedule.delete
      end
    end

    it 'Throws exception when no executable specified' do
      schedule = nil
      begin
        expect {
          schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, nil, @test_data)
        }.to raise_error 'Executable has to be provided'
      ensure
        schedule && schedule.delete
      end
    end

    it 'Throws exception when no cron is specified' do
      data = GoodData::Helpers.deep_dup(@test_data)
      data[:cron] = nil
      schedule = nil
      begin
        expect {
          schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, nil, ProcessHelper::DEPLOY_NAME, data)
        }.to raise_error 'Trigger schedule has to be provided'
      ensure
        schedule && schedule.delete
      end
    end

    it 'Throws exception when no timezone specified' do
      data = GoodData::Helpers.deep_dup(@test_data)
      schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, data)
      schedule.timezone = nil
      begin
        expect {
          schedule.save
        }.to raise_error 'A timezone has to be provided'
      ensure
        schedule && schedule.delete
      end
    end

    it 'Throws exception when no schedule type is specified' do
      schedule = nil
      data = GoodData::Helpers.deep_dup(@test_data)
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, data)
        schedule.type = nil
        expect {
          schedule.save
        }.to raise_error 'Schedule type has to be provided'
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#cron' do
    it 'Should return cron as string' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        res = schedule.cron
        res.should_not be_nil
        res.should_not be_empty
        res.should be_a_kind_of(String)
        expect(schedule.time_based?).to be_truthy
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#cron=' do
    it 'Assigns the cron and marks the object dirty' do
      test_cron = '2 2 2 2 *'

      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        schedule.cron = test_cron
        expect(schedule.cron).to eq(test_cron)
        expect(schedule.dirty).to eq(true)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#executable' do
    it 'Should return executable as string' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        res = schedule.executable
        res.should_not be_nil
        res.should_not be_empty
        res.should be_a_kind_of(String)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#executable=' do
    it 'Assigns the executable and marks the object dirty' do
      test_executable = 'this/is/test.grf'

      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        schedule.executable = test_executable
        expect(schedule.executable).to eq(test_executable)
        expect(schedule.dirty).to eq(true)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#execute' do
    it 'Waits for execution result by default' do
      begin
        process = @project.deploy_process('./spec/data/gooddata_version_process/gooddata_version.zip',
                                           type: 'RUBY',
                                           name: 'Test ETL zipped file GoodData Process')
        schedule = process.create_schedule('0 15 27 7 *', process.executables.first)
        res = schedule.execute
        expect(res).to be_an_instance_of(GoodData::Execution)
        expect([:ok, :error].include?(res.status)).to be_truthy
      ensure
        schedule && schedule.delete
        process && process.delete
      end
    end

    it 'can be overridden to do not wait for execution result' do
      begin
        process = @project.deploy_process('./spec/data/gooddata_version_process/gooddata_version.zip',
                                          type: 'RUBY',
                                          name: 'Test ETL zipped file GoodData Process')
        schedule = process.create_schedule('0 15 27 7 *', process.executables.first)
        res = schedule.execute(:wait => false)
        expect(res).to be_an_instance_of(GoodData::Execution)
        expect([:scheduled, :running].include?(res.status)).to be_truthy
      ensure
        schedule && schedule.delete
        process && process.delete
      end
    end
  end

  describe '#execution_url' do
    it 'Should return execution URL as string' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        res = schedule.execution_url
        res.should_not be_nil
        res.should_not be_empty
        res.should be_a_kind_of(String)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#type' do
    it 'Should return execution type as string' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        res = schedule.type
        res.should_not be_nil
        res.should be_a_kind_of(String)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#hidden_params' do
    it 'Should return execution hidden_params as hash' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        res = schedule.hidden_params
        res.should_not be_nil
        res.should be_a_kind_of(Hash)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#hidden_params=' do
    it 'Assigns the hidden params and marks the object dirty' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        old_params = schedule.hidden_params

        test_params = {
          'PROCESS_ID' => '1-2-3-4'
        }

        schedule.hidden_params = test_params
        expect(schedule.hidden_params).to eq(old_params.merge(test_params))
        expect(schedule.dirty).to eq(true)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#set_hidden_parameter' do
    it 'Assigns the hidden parameter and marks the object dirty' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        old_params = schedule.hidden_params

        test_parameter = {'test_parameter' => 'just_testing' }
        schedule.set_hidden_parameter(test_parameter.keys.first, test_parameter.values.first)
        expect(schedule.hidden_params).to eq(old_params.merge(test_parameter))
        expect(schedule.dirty).to eq(true)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#set_parameter' do
    it 'Assigns the hidden parameter and marks the object dirty' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        old_params = schedule.params

        test_parameter = {'test_parameter' => 'just_testing' }
        schedule.set_parameter(test_parameter.keys.first, test_parameter.values.first)
        expect(schedule.params).to eq(old_params.merge(test_parameter))
        expect(schedule.dirty).to eq(true)
      ensure
        schedule && schedule.delete
      end
    end
  end
  

  describe '#params' do
    it 'Should return execution params as hash' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        res = schedule.params
        res.should_not be_nil
        res.should_not be_empty
        res.should be_a_kind_of(Hash)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#params=' do
    it 'Assigns the params and marks the object dirty' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        old_params = schedule.params

        test_params = {
          'some_new_param' => '1-2-3-4'
        }

        schedule.params = test_params
        expect(schedule.params.keys).to eq(%w(PROCESS_ID EXECUTABLE some_new_param))
        expect(schedule.params['some_new_param']).to eq '1-2-3-4'
        expect(schedule.dirty).to eq(true)
        schedule.save
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#process_id' do
    it 'Should return process id as string' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        res = schedule.process_id
        res.should_not be_nil
        res.should_not be_empty
        res.should be_a_kind_of(String)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#process_id=' do
    it 'Assigns the process_id and marks the object dirty' do
      test_process_id = '1-2-3-4'

      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        schedule.process_id = test_process_id
        expect(schedule.process_id).to eq(test_process_id)
        expect(schedule.dirty).to eq(true)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#save' do
    it 'Should save a schedule' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        expect(@project.schedules(schedule.uri)).to eq schedule
        expect(@project.schedules).to include(schedule)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#state' do
    it 'Should return execution state as string' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        res = schedule.state
        res.should_not be_nil
        res.should_not be_empty
        res.should be_a_kind_of(String)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#type' do
    it 'Should return execution type as string' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        res = schedule.type
        res.should_not be_nil
        res.should_not be_empty
        res.should be_a_kind_of(String)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#type=' do
    it 'Assigns the type the object dirty' do
      test_type = 'TEST'

      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        schedule.type = test_type
        expect(schedule.type).to eq(test_type)
        expect(schedule.dirty).to eq(true)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#timezone' do
    it 'Should return timezone as string' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        res = schedule.timezone
        res.should_not be_nil
        res.should_not be_empty
        res.should be_a_kind_of(String)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#timezone=' do
    it 'Assigns the timezone and marks the object dirty' do
      test_timezone = 'PST'

      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data)
        schedule.timezone = test_timezone
        expect(schedule.timezone).to eq(test_timezone)
        expect(schedule.dirty).to eq(true)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#reschedule' do
    it 'Should return reschedule as integer' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data_with_optional_param)
        res = schedule.reschedule
        res.should_not be_nil
        res.should be_a_kind_of(Integer)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#reschedule=' do
    it 'Assigns the reschedule and marks the object dirty' do
      test_reschedule = 45

      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data_with_optional_param)
        schedule.reschedule = test_reschedule
        expect(schedule.reschedule).to eq(test_reschedule)
        expect(schedule.dirty).to eq(true)
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#executions' do
    it 'Returns executions' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data_with_optional_param)
        expect(schedule.executions.to_a).to be_empty
        schedule.execute
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#name' do
    it 'should be able to get name of the schedule.' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data_with_optional_param)
        expect(schedule.name).to eq 'graph.grf'
      ensure
        schedule && schedule.delete
      end
    end

    it 'should be able to return your name if specified during creation.' do
      begin
        schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, ProcessHelper::DEPLOY_NAME, @test_data_with_optional_param.merge(name: 'My schedule name'))
        expect(schedule.name).to eq 'My schedule name'
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#trigger_id=' do
    it 'should be able to set trigger_id of the schedule.' do
      begin
        process = @project.processes(ProcessHelper::PROCESS_ID)
        schedule = process.create_schedule(@test_cron, ProcessHelper::DEPLOY_NAME, @test_data_with_optional_param)
        expect(schedule.dirty).to be_falsey
        schedule.trigger_id = 'some_other_id'
        expect(schedule.dirty).to be_truthy
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#trigger_id=' do
    it 'should be able to set trigger_id of the schedule.' do
      begin
        process = @project.processes(ProcessHelper::PROCESS_ID)
        schedule = process.create_schedule(@test_cron, ProcessHelper::DEPLOY_NAME, @test_data_with_optional_param)
        expect(schedule.dirty).to be_falsey
        schedule.trigger_id = 'some_other_id'
        expect(schedule.dirty).to be_truthy
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#name=' do
    it 'should be able to set name of the schedule.' do
      begin
        process = @project.processes(ProcessHelper::PROCESS_ID)
        schedule = process.create_schedule(@test_cron, ProcessHelper::DEPLOY_NAME, @test_data_with_optional_param)
        expect(schedule.name).to eq 'graph.grf'
        schedule.name = 'MY NAME'
        schedule.save
        schedule2 = process.schedules.find { |s| s.obj_id == schedule.obj_id }
        expect(schedule2.name).to eq 'MY NAME'
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe '#disable' do
    it 'should preserve the hidden parmeters.' do
      begin
        process = @project.processes(ProcessHelper::PROCESS_ID)
        schedule = process.create_schedule(@test_cron, ProcessHelper::DEPLOY_NAME, @test_data_with_optional_param.merge({hidden_params: {
          "a" => {
            "b" => "c"
          }
        }}))
        
        schedule.save
        expect(schedule.hidden_params).to eq({
          GoodData::Helpers::ENCODED_HIDDEN_PARAMS_KEY => nil
        })
        schedule2 = process.schedules.find { |s| s.uri == schedule.uri }
        expect(schedule2.to_update_payload['schedule']['hiddenParams']).to eq ({
          GoodData::Helpers::ENCODED_HIDDEN_PARAMS_KEY => nil
        })
      ensure
        schedule && schedule.delete
      end
    end
  end
end
