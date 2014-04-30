require 'gooddata/models/schedule'

describe GoodData::Schedule do
  PROJECT_ID = 'tk6192gsnav58crp6o1ahsmtuniq8khb'

  before(:each) do
    ConnectionHelper.create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  it 'Can delete created schedule' do
    GoodData.project = PROJECT_ID

    proj = GoodData.project

    data = {
      'timezone' => 'UTC',
      'cron' => '2 2 2 2 *'
    }

    sched = GoodData::Schedule.create('f12975d2-5958-4248-9c3d-4c8f2e1f067d', '0 15 27 7 *', "#{proj.title}/graph/graph.grf", data)
    pp sched

    sched.delete
  end
end