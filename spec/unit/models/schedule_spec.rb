# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/models/schedule'

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

    @project_executable = 'graph/graph.grf'
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

  describe '#create' do
    it 'Creates new schedule if mandatory params passed' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      expect(schedule).to be_truthy
    end

    it 'Creates new schedule if mandatory params passed and optional params are present' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data_with_optional_param)
      expect(schedule).to be_truthy
    end

    it 'Throws exception when no process ID specified' do
      schedule = nil
      expect {
        schedule = GoodData::Schedule.create(nil, @test_cron, @project_executable, @test_data)
      }.to raise_error 'Process ID has to be provided'
    end

    it 'Throws exception when no executable specified' do
      schedule = nil
      expect {
        schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, nil, @test_data)
      }.to raise_error 'Executable has to be provided'
    end

    it 'Throws exception when no cron is specified' do
      data = GoodData::Helpers.deep_dup(@test_data)
      data[:cron] = nil
      schedule = nil
      expect {
        schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, nil, @project_executable, data)
      }.to raise_error 'Trigger schedule has to be provided'
    end
  end

  describe '#cron' do
    it 'Should return cron as string' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      res = schedule.cron
      expect(res).not_to be_nil
      expect(res).not_to be_empty
      expect(res).to be_a_kind_of(String)
      expect(schedule.time_based?).to be_truthy
    end
  end

  describe '#cron=' do
    it 'Assigns the cron and marks the object dirty' do
      test_cron = '2 2 2 2 *'

      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      schedule.cron = test_cron
      expect(schedule.cron).to eq(test_cron)
      expect(schedule.dirty).to eq(true)
      expect(schedule.to_hash[:cron]).to eq test_cron
      expect(schedule.to_update_payload['schedule']['cron']).to eq test_cron
    end
  end

  describe '#executable' do
    it 'Should return executable as string' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      res = schedule.executable
      expect(res).not_to be_nil
      expect(res).not_to be_empty
      expect(res).to be_a_kind_of(String)
    end
  end

  describe '#executable=' do
    it 'Assigns the executable and marks the object dirty' do
      test_executable = 'this/is/test.grf'

      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      schedule.executable = test_executable
      expect(schedule.executable).to eq(test_executable)
      expect(schedule.dirty).to eq(true)
      expect(schedule.to_hash[:executable]).to eq test_executable
      expect(schedule.to_update_payload['schedule']['params']['EXECUTABLE']).to eq test_executable
    end
  end

  describe '#execute' do
    it 'Cannot be executed if not saved' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      expect(schedule.execute).to be_nil
    end
  end

  describe '#execution_url' do
    it 'Should return execution URL as string' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      expect(schedule.execution_url).to be_nil
    end
  end

  describe '#type' do
    it 'Should return execution type as string' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      expect(schedule.type).to eq 'MSETL'
      expect(schedule.to_hash[:type]).to eq 'MSETL'
      expect(schedule.to_update_payload['schedule']['type']).to eq 'MSETL'
    end
  end

  describe '#type=' do
    it 'Assigns the type the object dirty' do
      test_type = 'TEST'
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      schedule.type = test_type
      expect(schedule.type).to eq(test_type)
      expect(schedule.dirty).to eq(true)
      expect(schedule.to_hash[:type]).to eq test_type
      expect(schedule.to_update_payload['schedule']['type']).to eq test_type
    end
  end

  describe '#hidden_params' do
    it 'Should return hidden_params as hash. Empty by default.' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      res = schedule.hidden_params
      expect(res).not_to be_nil
      expect(res).to be_a_kind_of(Hash)
    end

    it 'Should return hidden_params as hash. Filled by default if provided.' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data.merge(hidden_params: {'a' => 'b'}))
      res = schedule.hidden_params
      expect(res).not_to be_nil
      expect(res).to be_a_kind_of(Hash)
      expect(res['a']).to eq 'b'
    end
  end

  describe '#hidden_params=' do
    it 'Assigns the hidden params and marks the object dirty' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      old_params = schedule.hidden_params

      test_params = {
        'PROCESS_ID' => '1-2-3-4'
      }

      schedule.hidden_params = test_params
      expect(schedule.hidden_params).to eq(old_params.merge(test_params))
      expect(schedule.dirty).to eq(true)
      expect(schedule.to_hash[:hidden_params]).to eq(test_params)
      expect(schedule.to_update_payload['schedule']['hiddenParams']).to eq(test_params)
    end
  end

  describe '#set_hidden_parameter' do
    it 'Assigns the hidden parameter and marks the object dirty' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      old_params = schedule.hidden_params

      test_parameter = {'test_parameter' => 'just_testing' }
      schedule.set_hidden_parameter(test_parameter.keys.first, test_parameter.values.first)
      expect(schedule.hidden_params).to eq(old_params.merge(test_parameter))
      expect(schedule.dirty).to eq(true)
      expect(schedule.to_hash[:hidden_params]).to eq(test_parameter)
      expect(schedule.to_update_payload['schedule']['hiddenParams']).to eq(test_parameter)
    end
  end

  describe '#set_parameter' do
    it 'Assigns the parameter and marks the object dirty' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      old_params = schedule.params

      test_parameter = {'test_parameter' => 'just_testing' }
      schedule.set_parameter(test_parameter.keys.first, test_parameter.values.first)
      expect(schedule.params).to eq(old_params.merge(test_parameter))
      expect(schedule.dirty).to eq(true)
      expect(schedule.to_hash[:params]).to eq(old_params.merge(test_parameter))
      expect(schedule.to_update_payload['schedule']['params']).to eq(old_params.merge(test_parameter))
    end
  end


  describe '#params' do
    it 'Should return execution params as hash' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      res = schedule.params
      expect(res).not_to be_nil
      expect(res).to be_a_kind_of(Hash)
    end
  end

  describe '#params=' do
    it 'Updates the params and marks the object dirty' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      old_params = schedule.params

      test_params = {
        'some_new_param' => '1-2-3-4'
      }

      schedule.params = test_params
      expect(schedule.params.keys).to eq(%w(PROCESS_ID EXECUTABLE some_new_param))
      expect(schedule.params['some_new_param']).to eq '1-2-3-4'
      expect(schedule.dirty).to eq(true)
    end
  end

  describe '#update_params' do
    it 'Updates the params and marks the object dirty' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data.merge({ params: { 'a' => 'b' } }))
      old_params = schedule.params

      test_params = {
        'some_new_param' => '1-2-3-4',
        'a' => 'c'
      }

      schedule.update_params(test_params)
      expect(schedule.params.keys).to eq(%w(PROCESS_ID EXECUTABLE a some_new_param))
      expect(schedule.params['some_new_param']).to eq '1-2-3-4'
      expect(schedule.params['a']).to eq 'c'
      expect(schedule.dirty).to eq(true)
    end
  end

  describe '#update_hidden_params' do
    it 'Updates the hidden params and marks the object dirty' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data.merge({ params: { 'a' => 'b' } }))
      old_params = schedule.hidden_params

      schedule.update_hidden_params({
        'some_new_param' => '1-2-3-4',
        'a' => 'c',
        'x' => ''
      })
      expect(schedule.hidden_params.keys.to_set).to eq(%w(x a some_new_param).to_set)
      expect(schedule.hidden_params['some_new_param']).to eq '1-2-3-4'
      expect(schedule.hidden_params['a']).to eq 'c'
      expect(schedule.dirty).to eq(true)

      schedule.update_hidden_params({
        'some_new_param' => '1-2-3-4',
        'a' => 'd'
      })
      expect(schedule.hidden_params.keys.to_set).to eq(%w(x a some_new_param).to_set)
      expect(schedule.hidden_params['some_new_param']).to eq '1-2-3-4'
      expect(schedule.hidden_params['a']).to eq 'd'
      expect(schedule.hidden_params['x']).to eq ''
      expect(schedule.dirty).to eq(true)
    end
  end

  describe '#process_id' do
    it 'Should return process id as string' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      res = schedule.process_id
      res.should_not be_nil
      res.should_not be_empty
      res.should be_a_kind_of(String)
    end
  end

  describe '#process_id=' do
    it 'Assigns the process_id and marks the object dirty' do
      test_process_id = '1-2-3-4'

      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      schedule.process_id = test_process_id
      expect(schedule.process_id).to eq(test_process_id)
      expect(schedule.dirty).to eq(true)
      expect(schedule.to_hash[:process_id]).to eq test_process_id
      expect(schedule.to_update_payload['schedule']['params']['PROCESS_ID']).to eq test_process_id
    end
  end


  describe '#state' do
    it 'Should return schedule state as string' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      res = schedule.state
      expect(res).not_to be_nil
      expect(res).to eq 'ENABLED'
      expect(schedule.to_hash[:state]).to eq  'ENABLED'
      expect(schedule.to_update_payload['schedule']['state']).to eq 'ENABLED'
    end

    it 'Should return schedule state as string as provided' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data.merge(:state => 'DISABLED'))
      res = schedule.state
      expect(res).not_to be_nil
      expect(res).to eq 'DISABLED'
      expect(schedule.to_hash[:state]).to eq 'DISABLED'
      expect(schedule.to_update_payload['schedule']['state']).to eq 'DISABLED'
    end
  end

  describe '#timezone' do
    it 'Should return timezone as string' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      res = schedule.timezone
      expect(res).not_to be_nil
      expect(res).to be_a_kind_of(String)
    end
  end

  describe '#timezone=' do
    it 'Assigns the timezone and marks the object dirty' do
      test_timezone = 'PST'

      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      schedule.timezone = test_timezone
      expect(schedule.timezone).to eq(test_timezone)
      expect(schedule.dirty).to eq(true)
    end
  end
 
  describe '#reschedule' do
    it 'Should return reschedule nil if not provided' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      expect(schedule.reschedule).to eq nil
    end

    it 'Should return reschedule as integer' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data_with_optional_param)
      expect(schedule.reschedule).to eq @test_data_with_optional_param[:reschedule]
      expect(schedule.reschedule).to be_a_kind_of(Integer)
    end
  end

  describe '#reschedule=' do
    it 'Assigns the reschedule and marks the object dirty' do
      test_reschedule = 45
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data_with_optional_param)
      expect(schedule.reschedule).to eq @test_data_with_optional_param[:reschedule]
      schedule.reschedule = test_reschedule
      expect(schedule.reschedule).to eq(test_reschedule)
      expect(schedule.dirty).to eq(true)
      expect(schedule.to_hash[:reschedule]).to eq test_reschedule
      expect(schedule.to_update_payload['schedule']['reschedule']).to eq test_reschedule
    end
  end

  describe '#name' do
    it 'Name is nil if not specified and not saved.' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data_with_optional_param)
      expect(schedule.name).to eq nil
      expect(schedule.saved?).to eq false
      schedule.name = 'MY NAME'
      expect(schedule.name).to eq 'MY NAME'
    end

    it 'should be able to return your name if specified during creation.' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data_with_optional_param.merge(name: 'My schedule name'))
      expect(schedule.name).to eq 'My schedule name'
    end
  end

  describe '#trigger_id=' do
    it 'should be able to set trigger_id of the schedule.' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data_with_optional_param)
      expect(schedule.dirty).to be_truthy
      schedule.trigger_id = 'some_other_id'
      expect(schedule.dirty).to be_truthy
      expect(schedule.trigger_id).to eq 'some_other_id'
    end
  end

  describe '#name=' do
    it 'should be able to set name of the schedule.' do
      schedule = GoodData::Schedule.create(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data_with_optional_param)
      schedule.name = 'MY NAME'
      expect(schedule.name).to eq 'MY NAME'
    end
  end
end
