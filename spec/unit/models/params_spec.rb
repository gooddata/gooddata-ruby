# encoding: UTF-8

require 'gooddata/models/profile'
require 'gooddata/models/domain'
require 'gooddata/models/project'

describe 'GoodData::Schedule::Params' do
  before(:all) do
    @deploy_dir = File.join(File.dirname(__FILE__), '..', '..', 'data/cc')
    @graph_path = 'graph/graph.grf'

    @client = ConnectionHelper.create_default_connection
    @project = ProjectHelper.get_default_project
    @processes = @project.processes
  end

  after(:all) do
    @client.disconnect
  end

  describe 'params' do
    it 'Works with params' do
      params = {
        :test => '1234'
      }

      res = @processes[1].create_schedule("0 12 * * *", "./graph/graph.grf", params: params)
      expect(true).to be_true
    end
  end

  describe 'hiddenParams' do
    it 'Works with hiddenParams' do
      params = {
        :test => "1234"
      }

      res = @processes[1].create_schedule("0 12 * * *", "./graph/graph.grf", hiddenParams: params)
      expect(true).to be_true
    end
  end
end
