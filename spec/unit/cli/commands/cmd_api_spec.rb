require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'api' command" do
    args = %w(api)

    out = run_cli(args)
    out.should include("Command 'api' requires a subcommand info, get")
  end

  it "Has working 'api info' command" do
    args = %w(api info)

    run_cli(args)
  end

  it "Has working 'api get /gdc' command" do
    args = %w(api get /gdc)

    run_cli(args)
  end
end