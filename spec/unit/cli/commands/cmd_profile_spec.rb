require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'profile' command" do
    args = [
        'profile'
    ]

    GoodData::CLI.main(args)
  end
end