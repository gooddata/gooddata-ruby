require 'gooddata/models/schedule'

describe GoodData::Schedule do
  SCHEDULE_ID = ScheduleHelper::SCHEDULE_ID
  SCHEDULE_URL = "/gdc/projects/#{ProjectHelper::PROJECT_ID}/schedules/#{SCHEDULE_ID}"

  @test_cron = '0 15 27 7 *'

  before(:all) do
    @client = ConnectionHelper.create_default_connection

    @project = ProjectHelper.get_default_project(:client => @client)

    # ScheduleHelper.remove_old_schedules(@project)
    # ProcessHelper.remove_old_processes(@project)
  end

  before(:each) do
    @client = ConnectionHelper.create_default_connection

    @project = ProjectHelper.get_default_project(:client => @client)

    @project_executable = './graph/graph.grf'

    @test_data = {
      :timezone => 'UTC',
      :cron => '2 2 2 2 *',
      :client => @client,
      :project => @project
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
      sched = nil
      expect {
        sched = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
      }.not_to raise_error

      sched.should_not be_nil
      sched.delete
    end

    it 'Creates new schedule if mandatory params passed and optional params are present' do
      sched = nil
      expect {
        sched = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data_with_optional_param)
      }.not_to raise_error

      sched.should_not be_nil
      sched.delete
    end

    it 'Throws exception when no process ID specified' do
      expect {
        sched = @project.create_schedule(nil, @test_cron, @project_executable, @test_data)
      }.to raise_error 'Process ID has to be provided'
    end

    it 'Throws exception when no executable specified' do
      expect {
        sched = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, nil, @test_data)
      }.to raise_error 'Executable has to be provided'
    end

    it 'Throws exception when no cron is specified' do
      data = @test_data.deep_dup
      data[:cron] = nil
      expect {
        sched = @project.create_schedule(ProcessHelper::PROCESS_ID, nil, @project_executable, data)
      }.to raise_error 'trigger schedule has to be provided'
    end

    it 'Throws exception when no timezone specified' do
      data = @test_data.deep_dup
      data[:timezone] = nil
      expect {
        sched = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, data)
      }.to raise_error 'A timezone has to be provided'
    end

    it 'Throws exception when no timezone specified' do
      data = @test_data.deep_dup
      data[:type] = nil
      expect {
        sched = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, data)
      }.to raise_error 'Schedule type has to be provided'
    end
  end

  describe '#cron' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Should return cron as string' do
      res = @schedule.cron
      res.should_not be_nil
      res.should_not be_empty
      res.should be_a_kind_of(String)
    end
  end

  describe '#cron=' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Assigns the cron and marks the object dirty' do
      test_cron = '2 2 2 2 *'

      @schedule.cron = test_cron
      expect(@schedule.cron).to eq(test_cron)
      expect(@schedule.dirty).to eq(true)
    end
  end

  describe '#executable' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Should return executable as string' do
      res = @schedule.executable
      res.should_not be_nil
      res.should_not be_empty
      res.should be_a_kind_of(String)
    end
  end

  describe '#executable=' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Assigns the executable and marks the object dirty' do
      test_executable = 'this/is/test.gr'

      @schedule.executable = test_executable
      expect(@schedule.executable).to eq(test_executable)
      expect(@schedule.dirty).to eq(true)
    end
  end

  describe '#execution_url' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Should return execution URL as string' do
      res = @schedule.execution_url
      res.should_not be_nil
      res.should_not be_empty
      res.should be_a_kind_of(String)
    end
  end

  describe '#type' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Should return execution type as string' do
      res = @schedule.type
      res.should_not be_nil
      res.should be_a_kind_of(String)
    end
  end

  describe '#hidden_params' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Should return execution hidden_params as hash' do
      res = @schedule.hidden_params
      res.should_not be_nil
      res.should be_a_kind_of(Hash)
    end
  end

  describe '#hidden_params=' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Assigns the hidden params and marks the object dirty' do
      @old_params = @schedule.hidden_params

      test_params = {
        'PROCESS_ID' => '1-2-3-4'
      }

      @schedule.hidden_params = test_params
      expect(@schedule.hidden_params).to eq(@old_params.merge(test_params))
      expect(@schedule.dirty).to eq(true)
    end
  end

  describe '#params' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Should return execution params as hash' do
      res = @schedule.params
      res.should_not be_nil
      res.should_not be_empty
      res.should be_a_kind_of(Hash)
    end
  end

  describe '#params=' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Assigns the params and marks the object dirty' do
      @old_params = @schedule.params

      test_params = {
        'PROCESS_ID' => '1-2-3-4'
      }

      @schedule.params = test_params
      expect(@schedule.params).to eq(@old_params.merge(test_params))
      expect(@schedule.dirty).to eq(true)
    end
  end

  describe '#process_id' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Should return process id as string' do
      res = @schedule.process_id
      res.should_not be_nil
      res.should_not be_empty
      res.should be_a_kind_of(String)
    end
  end

  describe '#process_id=' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Assigns the process_id and marks the object dirty' do
      test_process_id = '1-2-3-4'

      @schedule.process_id = test_process_id
      expect(@schedule.process_id).to eq(test_process_id)
      expect(@schedule.dirty).to eq(true)
    end
  end

  describe '#save' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    it 'Should save a schedule' do
      expect(@project.schedules(@schedule.uri)).to eq @schedule
      expect(@client.projects(ProjectHelper::PROJECT_ID).schedules).to include(@schedule)
    end
  end

  describe '#state' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Should return execution state as string' do
      res = @schedule.state
      res.should_not be_nil
      res.should_not be_empty
      res.should be_a_kind_of(String)
    end
  end

  describe '#type' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Should return execution type as string' do
      res = @schedule.type
      res.should_not be_nil
      res.should_not be_empty
      res.should be_a_kind_of(String)
    end
  end

  describe '#type=' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Assigns the type the object dirty' do
      test_type = 'TEST'

      @schedule.type = test_type
      expect(@schedule.type).to eq(test_type)
      expect(@schedule.dirty).to eq(true)
    end
  end

  describe '#timezone' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Should return timezone as string' do
      res = @schedule.timezone
      res.should_not be_nil
      res.should_not be_empty
      res.should be_a_kind_of(String)
    end
  end

  describe '#timezone=' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Assigns the timezone and marks the object dirty' do
      test_timezone = 'PST'

      @schedule.timezone = test_timezone
      expect(@schedule.timezone).to eq(test_timezone)
      expect(@schedule.dirty).to eq(true)
    end
  end

  describe '#reschedule' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data_with_optional_param)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Should return reschedule as integer' do
      res = @schedule.reschedule
      res.should_not be_nil
      res.should be_a_kind_of(Integer)
    end
  end

  describe '#reschedule=' do
    before(:each) do
      @schedule = @project.create_schedule(ProcessHelper::PROCESS_ID, @test_cron, @project_executable, @test_data_with_optional_param)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Assigns the reschedule and marks the object dirty' do
      test_reschedule = 45

      @schedule.reschedule = test_reschedule
      expect(@schedule.reschedule).to eq(test_reschedule)
      expect(@schedule.dirty).to eq(true)
    end
  end
end