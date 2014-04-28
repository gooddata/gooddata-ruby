# encoding: UTF-8

require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'schedule' command" do
    args = %w(schedule)

    out = run_cli(args)
    out.should include "Command 'schedule' requires a subcommand list,show"
  end

  describe "schedule list" do
    it 'Should complain when no project specified' do
      args = %w(schedule list)

      out = run_cli(args)
      out.should include 'Project ID has to be provided'
    end
  end

  describe "schedule show" do
    it 'Should complain when no project specified' do
      args = %w(schedule show)

      out = run_cli(args)
      out.should include 'Project ID has to be provided'
    end
  end
end