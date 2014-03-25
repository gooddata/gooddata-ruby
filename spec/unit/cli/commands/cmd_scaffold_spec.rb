require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'scaffold' command" do
    args = %w(scaffold)

    run_cli(args)
  end

  it "Has working 'scaffold brick' command" do
    args = %w(scaffold brick)

    run_cli(args)
  end

  it "Has working 'scaffold project' command" do
    args = %w(scaffold project)

    run_cli(args)
  end
end