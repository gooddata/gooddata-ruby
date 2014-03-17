require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'run_ruby' command" do
    args = [
        'run_ruby'
    ]

    GoodData::CLI.main(args)
  end
end