require 'gooddata'

describe 'HelloWorldBrick' do
  ['ahoj', '', nil].each do |message|
    it "message is #{message}" do
      params = message.nil? ? {} : { "message" => message }
      @brick_result = GoodData::Bricks::Pipeline.hello_world_brick_pipeline.call(params)
      expect(@brick_result[:results]["HelloWorld"][0][:message]).to eq(message)
    end
  end
end
