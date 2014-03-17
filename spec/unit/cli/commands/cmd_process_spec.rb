require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'process' command" do
    args = [
        'process'
    ]

    GoodData::CLI.main(args)
  end
end