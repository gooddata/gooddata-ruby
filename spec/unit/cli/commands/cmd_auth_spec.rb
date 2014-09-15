# encoding: UTF-8

require 'gooddata/cli/cli'

describe 'GoodData::CLI - auth', :broken => true do
  describe 'auth' do
    it 'Can be called without arguments' do
      args = %w(auth)

      run_cli(args)
    end
  end
end