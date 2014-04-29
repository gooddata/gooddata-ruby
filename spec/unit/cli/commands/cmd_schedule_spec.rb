# encoding: UTF-8

require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'schedule' command" do
    args = %w(schedule)

    out = run_cli(args)
    out.should include "Command 'schedule' requires a subcommand list,show,delete,state,create"
  end

  describe "schedule list" do
    it 'Should complain when no project specified' do
      args = %w(schedule list)

      out = run_cli(args)
      out.should include 'Project ID must be provided.'
    end
  end

  describe "schedule show" do
    it 'Should complain when no project specified' do
      args = %w(schedule show)

      out = run_cli(args)
      out.should include 'Project ID must be provided.'
    end
  end

  describe "-p 32302903429 schedule delete" do
    it 'Should break without a Schedule ID' do
      args = %w(-p 32302903429 schedule delete)

      out = run_cli(args)
      out.should include 'Schedule ID must be provided.'
    end
  end

  describe "schedule show {process-id}" do
    it 'Should fail when a no Project ID is provided.' do
      args = %w(schedule show 432909234)

      out = run_cli(args)
      out.should include 'Project ID must be provided.'

    end
  end

  describe "-p {project-id} schedule delete {process-id}" do
    it 'Should throw error' do
      args = %w(-p 23293490 schedule delete 432909234)

      out = run_cli(args)
      out.should include 'Project ID must be provided.'

    end
  end

  describe "-p {project-id} schedule create {file.json}" do
    it 'Should fail if no file is present to import.' do
      args = %w(-p 23293490 schedule create)

      out = run_cli(args)
      out.should include 'can\'t convert nil into String'

    end
  end

end