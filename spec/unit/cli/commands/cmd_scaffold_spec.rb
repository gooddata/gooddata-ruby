require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'scaffold' command" do
    args = [
        'scaffold'
    ]

    GoodData::CLI.main(args)
  end
end