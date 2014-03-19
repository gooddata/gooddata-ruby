require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'api' command" do
    args = [
        'api'
    ]

    GoodData::CLI.main(args)
  end
end