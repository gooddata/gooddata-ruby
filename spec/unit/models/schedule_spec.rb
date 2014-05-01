require 'gooddata/models/schedule'

describe GoodData::Schedule do
  PROJECT_ID = 'tk6192gsnav58crp6o1ahsmtuniq8khb'

  TEST_CRON = '0 15 27 7 *'

  TEST_DATA = {
    'timezone' => 'UTC',
    'cron' => '2 2 2 2 *'
  }

  TEST_PROCESS_ID = 'f12975d2-5958-4248-9c3d-4c8f2e1f067d'

  before(:each) do
    ConnectionHelper.create_default_connection

    GoodData.project = PROJECT_ID

    @project = GoodData.project
    @project_executable = "#{@project.title}/graph/graph.grf"
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#create' do
    it 'Creates new schedule if mandatory params passed' do
      sched = nil
      expect {
        sched = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
      }.not_to raise_error

      sched.should_not be_nil
      sched.delete
    end

    it 'Throws exception when no process ID specified' do
      expect {
        sched = GoodData::Schedule.create(nil, TEST_CRON, @project_executable, TEST_DATA)
      }.to raise_error 'Process ID has to be provided'
    end

    it 'Throws exception when no executable specified' do
      expect {
        sched = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, nil, TEST_DATA)
      }.to raise_error 'Executable has to be provided'
    end

    it 'Throws exception when no cron is specified' do
      data = TEST_DATA.deep_dup
      data['cron'] = nil
      expect {
        sched = GoodData::Schedule.create(TEST_PROCESS_ID, nil, @project_executable, data)
      }.to raise_error 'Cron schedule has to be provided'
    end

    it 'Throws exception when no timezone specified' do
      data = TEST_DATA.deep_dup
      data['timezone'] = nil
      expect {
        sched = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, data)
      }.to raise_error 'A timezone has to be provided'
    end

    it 'Throws exception when no timezone specified' do
      data = TEST_DATA.deep_dup
      data['type'] = nil
      expect {
        sched = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, data)
      }.to raise_error 'Schedule type has to be provided'
    end
  end

  describe '#delete' do
    it 'Should delete schedule' do
      sched = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
      proc = GoodData::Process[TEST_PROCESS_ID]

      # Delete created schedule
      sched.delete

      proc.schedules.each do |tmp_sched|
        tmp_sched.uri.should_not equal(sched.uri)
      end
    end
  end

  describe '#execution_url' do
    before(:each) do
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
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
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
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

  describe '#state' do
    before(:each) do
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
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

  describe '#params' do
    before(:each) do
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
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

  describe '#execute' do
    it 'Executes schedule on process' do
      # Create one a schedule
      sched = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)

      execution_time = Time.new
      execution_request = sched.execute

      # Call execute
      executed = false
      start_time = Time.new
      while(Time.new - start_time < 30)
        # Check if the last execution time
        sched.executions.each do |execution|
          next if execution['execution'].nil? || execution['execution']['startTime'].nil?
          parsed_time = Time.parse(execution['execution']['startTime'])
          executed_schedule = execution_request['execution']['links']['self'] == execution['execution']['links']['self']
          if(execution_time <= parsed_time && executed_schedule)
            executed = true
            break
          end
        end
        break if executed
        sleep 1
      end

      expect(executed).to be(true)
    end
  end

  describe '#timezone' do
    before(:each) do
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
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

end