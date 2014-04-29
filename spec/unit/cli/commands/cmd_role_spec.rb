# encoding: UTF-8

require 'gooddata/cli/cli'

describe GoodData::CLI do
  describe 'r' do
    it 'Complains when no parameters specified' do
      args = %w(role)

      out = run_cli(args)
      out.should include "Command 'role' requires a subcommand list"
    end
  end
end