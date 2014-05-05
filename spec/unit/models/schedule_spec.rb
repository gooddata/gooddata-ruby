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

  describe '#cron' do
    before(:each) do
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
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
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Assigns the cron and marks the object dirty' do
      test_cron = '2 2 2 2 *'

      @schedule.cron = test_cron
      expect(@schedule.cron).to eq(test_cron)
      expect(@schedule.dirty).to be_true
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

  describe '#executable' do
    before(:each) do
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
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
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Assigns the executable and marks the object dirty' do
      test_executable = 'this/is/test.gr'

      @schedule.executable = test_executable
      expect(@schedule.executable).to eq(test_executable)
      expect(@schedule.dirty).to be_true
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
      while (Time.new - start_time < 30)
        # Check if the last execution time
        sched.executions.each do |execution|
          next if execution['execution'].nil? || execution['execution']['startTime'].nil?
          parsed_time = Time.parse(execution['execution']['startTime'])
          executed_schedule = execution_request['execution']['links']['self'] == execution['execution']['links']['self']
          if (execution_time <= parsed_time && executed_schedule)
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
      res.should be_a_kind_of(String)
    end
  end

  describe '#hidden_params' do
    before(:each) do
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
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
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
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
      expect(@schedule.dirty).to be_true
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

  describe '#params=' do
    before(:each) do
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
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
      expect(@schedule.dirty).to be_true
    end
  end

  describe '#process_id' do
    before(:each) do
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
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
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Assigns the process_id and marks the object dirty' do
      test_process_id = '1-2-3-4'

      @schedule.process_id = test_process_id
      expect(@schedule.process_id).to eq(test_process_id)
      expect(@schedule.dirty).to be_true
    end
  end

  describe '#save' do
    before(:each) do
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
    end

    after(:each) do
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
    end

    it 'Should save a schedule' do
      saved = false
      url = "/gdc/projects/#{PROJECT_ID}/schedules"
      req = GoodData.get url
      schedules = req['schedules']['items']
      schedules.each do |schedule|
        schedule_self = schedule['schedule']['links']['self']
        if schedule_self == @schedule.uri
          saved = true
        end
      end

      @schedule.timezone = 'UTC'

      @schedule.save

      expect(saved).to be(true)

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

  describe '#type=' do
    before(:each) do
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Assigns the type the object dirty' do
      test_type = 'TEST'

      @schedule.type = test_type
      expect(@schedule.type).to eq(test_type)
      expect(@schedule.dirty).to be_true
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

  describe '#timezone=' do
    before(:each) do
      @schedule = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)
    end

    after(:each) do
      @schedule.delete
    end

    it 'Assigns the timezone and marks the object dirty' do
      test_timezone = 'PST'

      @schedule.timezone = test_timezone
      expect(@schedule.timezone).to eq(test_timezone)
      expect(@schedule.dirty).to be_true
    end
  end
end