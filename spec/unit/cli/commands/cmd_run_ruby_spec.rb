# encoding: UTF-8

require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'run_ruby' command" do
    args = %w(run_ruby)

    run_cli(args)
  end
end