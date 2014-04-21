require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'user' command" do
    args = %w(user)

    run_cli(args)
  end

  it "Has working 'user list' command" do
    args = %w(user list)

    run_cli(args)
  end

  it "Has working 'user show' command" do
    args = %w(user show)

    run_cli(args)
  end
end
