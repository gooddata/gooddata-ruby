require 'gooddata/models/schedule'

describe GoodData::Schedule do
  before(:each) do
    ConnectionHelper.create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  it 'Will get schedules for process' do
    GoodData.project = 'tk6192gsnav58crp6o1ahsmtuniq8khb'

    proj = GoodData.project
    proc = proj.processes.first

    sched = proc.schedules.first
    sched.execute
  end
end