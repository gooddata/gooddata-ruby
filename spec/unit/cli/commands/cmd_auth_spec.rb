# encoding: UTF-8

require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'auth' command" do
    args = %w(auth)

    run_cli(args)
  end
end