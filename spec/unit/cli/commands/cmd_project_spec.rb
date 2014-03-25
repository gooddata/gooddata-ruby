require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'project' command" do
    args = %w(project)

    run_cli(args)
  end

  it "Has working 'project build' command" do
    args = %w(project build)

    run_cli(args)
  end

  it "Has working 'project clone' command" do
    args = %w(project clone)

    run_cli(args)
  end

  it "Has working 'project create' command" do
    args = %w(project create)

    # TODO: Pass all required args to prevent interaction
    # TODO: Investigate, fix and enable execution
    # run_cli(args)
  end

  it "Has working 'project delete' command" do
    args = %w(project delete)

    run_cli(args)
  end

  it "Has working 'project jack_in' command" do
    args = %w(project jack_in)

    run_cli(args)
  end

  it "Has working 'project list' command" do
    args = %w(project list)

    run_cli(args)
  end

  it "Has working 'project show' command" do
    args = %w(project show)

    run_cli(args)
  end

  it "Has working 'project update' command" do
    args = %w(project update)

    run_cli(args)
  end

end