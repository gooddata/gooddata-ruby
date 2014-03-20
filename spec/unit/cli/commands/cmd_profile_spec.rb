require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'profile' command" do
    args = %w(profile)

    run_cli(args)
  end
end