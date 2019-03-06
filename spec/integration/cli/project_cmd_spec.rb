require 'gooddata'
require_relative '../../lcm/integration/support/connection_helper'

describe 'GoodData::CLI - project commands', :vcr do
  describe '#create' do
    before(:all) do
      env = LcmConnectionHelper.environment
      @credential_params = [
        "-U #{env[:username]}",
        "-P #{env[:password]}",
        "-t #{env[:gd_project_token]}",
        "-s https://#{env[:prod_server]}",
        '-l --no-verify-ssl'
      ].join(' ')
    end

    it 'creates a project on platform' do
      cmd = "#{@credential_params} project create"
      expect { GoodData::CLI.main(cmd.split) }.to output(%r{gdc/projects}).to_stdout
    end
  end
end
