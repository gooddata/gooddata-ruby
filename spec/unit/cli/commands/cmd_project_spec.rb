require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'project' command" do
    args = [
        'project'
    ]

    GoodData::CLI.main(args)
  end
end