require 'gooddata/models/schedule'

describe GoodData::Execution do

  before(:each) do
    @data = {"execution"=>
      {"startTime"=>"2015-02-27T15:44:21.759Z",
       "endTime"=>"2015-02-27T15:47:49.383Z",
       "log"=>
        "/gdc/projects/tk3b994vmdpcb0xjwexc9moen8t5bpiw/dataload/processes/2b031451-b1a2-4039-8e36-0672542a0e60/executions/54f090d5e4b0c9cbdcb0f45b/log",
       "status"=>"OK",
       "trigger"=>"MANUAL",
       "links"=>
        {"self"=>
          "/gdc/projects/tk3b994vmdpcb0xjwexc9moen8t5bpiw/schedules/54f08d1de4b0c9cbdcb0f323/executions/54f090d5e4b0c9cbdcb0f45b"},
       "createdTime"=>"2015-02-27T15:44:21.361Z"}}
    @execution = GoodData::Execution.new(@data)
  end

  describe '#created' do
    it 'returns created as a Time instance' do
      expect(@execution.created.class).to eq Time
      expect(@execution.created.to_s).to eq '2015-02-27 15:44:21 UTC'
    end
  end

  describe '#error?' do
    it 'returns true if executione errored out' do
      expect(@execution.error?).to be_falsy
    end
  end

  describe '#ok?' do
    it 'returns true if executione finished ok' do
      expect(@execution.ok?).to be_truthy
    end
  end

  describe '#finished' do
    it 'returns time when execution finished' do
      expect(@execution.finished.class).to eq Time
      expect(@execution.finished.to_s).to eq '2015-02-27 15:47:49 UTC'
    end

    it 'returns nil if it is not finished' do
      @data['execution']['status'] = 'RUNNING'
      @data['execution']['endTime'] = nil
      running_execution = GoodData::Execution.new(@data)
      expect(running_execution.finished).to be_nil
    end
  end

  describe '#schedule_uri' do
    it 'returns uri of schedule that was executed' do
      expect(@execution.schedule_uri).to eq '/gdc/projects/tk3b994vmdpcb0xjwexc9moen8t5bpiw/schedules/54f08d1de4b0c9cbdcb0f323'
    end
  end

  describe '#running?' do
    it 'returns false if executione is already finished' do
      expect(@execution.running?).to be_falsy
    end

    it 'returns true if executione is currently finished' do
      @data['execution']['status'] = 'RUNNING'
      running_execution = GoodData::Execution.new(@data)
      expect(running_execution.running?).to be_truthy
    end
  end

  describe '#started' do
    it 'returns time when execution started' do
      expect(@execution.started.class).to eq Time
      expect(@execution.started.to_s).to eq '2015-02-27 15:44:21 UTC'
    end
  end

  describe '#status' do
    it 'returns :ok for finished execution' do
      expect(@execution.status).to eq :ok
    end
  end

  describe '#uri' do
    it 'returns time when execution started' do
      expect(@execution.uri).to eq '/gdc/projects/tk3b994vmdpcb0xjwexc9moen8t5bpiw/schedules/54f08d1de4b0c9cbdcb0f323/executions/54f090d5e4b0c9cbdcb0f45b'
    end
  end

  describe '#duration' do
    it 'returns time it took to run execution' do
      expect(@execution.duration).to eq 207.624
    end

    it 'returns nil if it is not finished' do
      @data['execution']['status'] = 'RUNNING'
      @data['execution']['endTime'] = nil
      running_execution = GoodData::Execution.new(@data)
      expect(running_execution.duration.class).to eq Float
    end
  end
end
