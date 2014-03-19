require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'auth' command" do
    args = [
        'auth'
    ]

    GoodData::CLI.main(args)
  end
end