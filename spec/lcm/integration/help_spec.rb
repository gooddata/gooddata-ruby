require 'gooddata'

describe 'HelpBrick' do
  it "print help" do
    @brick_result = GoodData::Bricks::Pipeline.help_brick_pipeline.call({})
    expect(@brick_result[:results]["Help"].map { |brick| brick[:available_brick] }).to eq(
      %w[release users rollout provisioning user_filters help hello_world]
    )
  end
end
