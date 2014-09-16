# encoding: UTF-8

require 'gooddata/cli/cli'

describe 'GoodData::CLI - project', :broken => true do
  describe 'project' do
    it 'Complains when no subcommand specified' do
      args = %w(project)

      out = run_cli(args)
      out.should include "Command 'project' requires a subcommand jack_in,create,delete,clone,invite,users,show,build,update,roles,validate"
    end
  end

  describe 'project build' do
    it 'Can be called without arguments' do
      args = %w(project build)

      run_cli(args)
    end
  end

  describe 'project clone' do
    it 'Can be called without arguments' do
      args = %w(project clone)

      run_cli(args)
    end
  end

  describe 'project create' do
    it 'Can be called without arguments' do
      args = %w(project create)

      # TODO: Pass all required args to prevent interaction
      # TODO: Investigate, fix and enable execution
      # run_cli(args)
    end
  end

  describe 'project delete' do
    it 'Can be called without arguments' do
      args = %w(project delete)

      run_cli(args)
    end
  end

  describe 'project jack_in' do
    it 'Can be called without arguments' do
      args = %w(project jack_in)

      run_cli(args)
    end
  end

  describe 'project list' do
    it 'Can be called without arguments' do
      args = %w(project list)

      run_cli(args)
    end
  end

  describe 'project show' do
    it 'Can be called without arguments' do
      args = %w(project show)

      run_cli(args)
    end
  end

  describe 'project update' do
    it 'Can be called without arguments' do
      args = %w(project update)

      run_cli(args)
    end
  end

end