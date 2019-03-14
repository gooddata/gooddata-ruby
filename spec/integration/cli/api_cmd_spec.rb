require 'gooddata'
require_relative '../../lcm/integration/support/connection_helper'

describe 'GoodData::CLI - api commands', :vcr do
  before(:all) do
    env = LcmConnectionHelper.environment
    @credential_params = [
      "-U #{env[:username]}",
      "-P #{env[:password]}",
      "-s https://#{env[:prod_server]}",
      '-l --no-verify-ssl'
    ].join(' ')
  end

  after(:all) do
    if @new_project_uri
      client = LcmConnectionHelper.production_server_connection
      client.delete @new_project_uri
    end
  end

  describe '#get' do
    it 'makes a request' do
      expect(`gooddata #{@credential_params} api get /releaseInfo`)
    end
  end

  describe '#post' do
    it 'makes a request' do
      data = '{"name": "gd_ruby_cmd_test", "type" : "etl","component": {"name": "gdc-etl-sql-executor", "version":"1"}}'
      File.write('json.json', data)
      uri = "/gdc/projects/#{ProjectHelper.project_id(@client)}/dataload/processes"
      result = `gooddata #{@credential_params} api post #{uri} json.json`
      expect(result)
    end
  end
end
