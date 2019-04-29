require 'gooddata'
require_relative '../../lcm/integration/support/connection_helper'

describe 'GoodData::CLI - process commands', :vcr do
  describe '#create' do
    before(:all) do
      env = LcmConnectionHelper.environment
      @client = LcmConnectionHelper.production_server_connection
      @credential_params = [
        "-U #{env[:username]}",
        "-P #{env[:password]}",
        "-t #{env[:gd_project_token]}",
        "-s https://#{env[:prod_server]}",
        "-p #{ProjectHelper.project_id(@client)}",
        '-l --no-verify-ssl'
      ].join(' ')
    end

    after(:all) do
      @client.delete(@new_process_uri) if @new_process_uri
    end

    describe '#from_path' do
      it 'deploys a process' do
        cmd = "#{@credential_params} process create from_path ./spec/data/cc"
        expect { GoodData::CLI.main(cmd.split) }.to output(%r{gdc/projects/.*/dataload/processes/}).to_stdout
      end
    end

    describe '#as_component' do
      it 'deploys a process' do
        json_data = '{"name": "gd_ruby_cmd_test_xx", "type" : "etl","component": {"name": "gdc-etl-sql-executor", "version":"1"}}'
        File.write('json.json', json_data)
        cmd = "#{@credential_params} process create as_component json.json"
        expect { GoodData::CLI.main(cmd.split) }.to output(%r{gdc/projects/.*/dataload/processes/}).to_stdout
        File.delete('json.json')
      end
    end
  end
end
