# encoding: UTF-8

require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'process' command" do
    args = %w(process)

    run_cli(args)
  end

  it "Has working 'process deploy' command" do
    args = %w(process deploy)

    run_cli(args)
  end

  it "Has working 'process get' command" do
    args = %w(process get)

    run_cli(args)
  end

  it "Has working 'process list' command" do
    args = %w(process list)

    run_cli(args)
  end
end