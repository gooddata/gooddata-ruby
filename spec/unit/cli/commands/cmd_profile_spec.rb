require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'profile' command" do
    args = %w(profile)

    out = run_cli(args)
    out.should include("Command 'profile' requires a subcommand show")
  end

  it "Has working 'profile show' command" do
    args = %w(profile show)

    run_cli(args)
  end
end