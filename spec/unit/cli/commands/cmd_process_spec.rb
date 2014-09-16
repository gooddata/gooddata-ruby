# encoding: UTF-8

require 'gooddata/cli/cli'

describe 'GoodData::CLI - process', :broken => true do
  describe 'process' do
    it 'Complains when no subcommand specified' do
      args = %w(process)

      out = run_cli(args)
      out.should include "Command 'process' requires a subcommand list,show,deploy,delete,execute"
    end
  end

  describe 'process deploy' do
    it 'Can be called without arguments' do
      args = %w(process deploy)

      run_cli(args)
    end
  end

  describe 'process get' do
    it 'Can be called without arguments' do
      args = %w(process get)

      run_cli(args)
    end
  end

  describe 'process list' do
    it 'Lists processes when project ID specified' do
      args = [
        'process',
        'list',
        ProjectHelper::PROJECT_ID
      ]

      run_cli(args)
    end
  end

end