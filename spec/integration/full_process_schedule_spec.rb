require 'gooddata'

describe "Full process and schedule exercise", :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper::create_default_connection
    @project = GoodData::Project.create(title: 'Project for schedule testing', auth_token: ConnectionHelper::GD_PROJECT_TOKEN, :client => @client)
    @process = GoodData::Process.with_deploy('./spec/data/ruby_process',
                                  type: 'RUBY',
                                  project: @project,
                                  name: 'Test ETL Process',
                                  client: @client)
  end

  after(:all) do
    @process.delete if @process
    @project.delete if @project
    @client.disconnect
  end

  it "should be able to execute a process" do
    pending('Account cannot execute Ruby')

    result = @process.execute(@process.executables.first)
    log = @client.get(result['executionDetail']['links']['log'])
    expect(log.index('Hello Ruby executors')).not_to eq nil
    expect(log.index('Hello Ruby from the deep')).not_to eq nil
  end

  it "should be able to grab executables" do 
    pending('Account cannot execute Ruby')

    expect(@process.executables).to eq ['./process.rb']
  end

  it "should have empty schedules on deploy" do 
    pending('Account cannot execute Ruby')

    expect(@process.schedules).to eq []
  end

  it "should be able to schedule" do
    pending('Account cannot execute Ruby')

    schedule = @process.create_schedule('0 15 27 7 *', @process.executables.first)
    expect(@process.schedules.count).to eq 1
    expect(@process.schedules).to eq [schedule]
    schedule.delete
  end

  it "should be possible to read status of schedule" do
    pending('Account cannot execute Ruby')

    schedule = @process.create_schedule('0 15 27 7 *', @process.executables.first)
    expect(schedule.state).to eq 'ENABLED'
    schedule.delete
  end

  it "should be possible to execute schedule" do
    pending('Account cannot execute Ruby')

    schedule = @process.create_schedule('0 15 27 7 *', @process.executables.first)
    result = schedule.execute
    log = GoodData.get(result['execution']['log'])
    expect(log.index('Hello Ruby executors')).not_to eq nil
    expect(log.index('Hello Ruby from the deep')).not_to eq nil
  end
end
