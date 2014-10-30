# encoding: UTF-8

require 'gooddata/cli/cli'

describe 'GoodData::CLI - run_ruby', :broken => true do
  describe 'run_ruby' do
    it 'Can be called without arguments' do
      args = %w(run_ruby)

      run_cli(args)
    end
  end
end