require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'project' command" do
    args = %w(project)

    GoodData::CLI.main(args)
  end

  it "Has working 'project build' command" do
    args = %w(project build)

    GoodData::CLI.main(args)
  end

  it "Has working 'project clone' command" do
    args = %w(project clone)

    GoodData::CLI.main(args)
  end

  it "Has working 'project create' command" do
    args = %w(project create)

    # TODO: Pass all required args to prevent interaction
    # TODO: Investigate, fix and enable execution
    # GoodData::CLI.main(args)
  end

  it "Has working 'project delete' command" do
    args = %w(project delete)

    GoodData::CLI.main(args)
  end

  it "Has working 'project jack_in' command" do
    args = %w(project jack_in)

    GoodData::CLI.main(args)
  end

  it "Has working 'project list' command" do
    args = %w(project list)

    GoodData::CLI.main(args)
  end

  it "Has working 'project show' command" do
    args = %w(project show)

    GoodData::CLI.main(args)
  end

  it "Has working 'project update' command" do
    args = %w(project update)

    GoodData::CLI.main(args)
  end

end