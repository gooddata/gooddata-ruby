require 'gooddata/cli/cli'

describe 'GoodData::CLI - user', :broken => true do
  describe 'user' do
    it 'Complains when no subcommand specified' do
      args = %w(user)

      out = run_cli(args)
      out.should include "Command 'user' requires a subcommand show"
    end
  end

  describe 'user list' do
    it "Has working 'user list' command" do
      args = %w(user list)

      run_cli(args)
    end
  end

  describe 'user show' do
    it "Has working 'user show' command" do
      args = %w(user show)

      run_cli(args)
    end
  end

end
