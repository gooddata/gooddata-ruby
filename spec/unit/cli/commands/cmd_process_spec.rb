require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'process' command" do
    args = %w(process)

    run_cli(args)
  end
end