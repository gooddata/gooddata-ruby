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

  describe '#execute' do
    it 'Executes ....' do
      # Create one
      sched = GoodData::Schedule.create(TEST_PROCESS_ID, TEST_CRON, @project_executable, TEST_DATA)

      execution_time = Time.new
      sched.execute

      # Call execute

      executed = false
      start_time = Time.new
      while(Time.new - start_time < 30)
        # TODO: Get updated execution

        # TODO: get last execution time of sched
        last_exec_time = 123

        # Check if the last execution time
        if(last_exec_time >= execution_time)
          executed = true
          break
        end

        sleep 1
      end

      executed.should equal(true)
    end
  end


end