# encoding: UTF-8

require 'gooddata/models/profile'
require 'gooddata/models/domain'
require 'gooddata/models/project'

describe 'GoodData::Schedule::Params' do
  before(:all) do
    @deploy_dir = File.join(File.dirname(__FILE__), '..', '..', 'data/cc')
    @graph_path = 'graph.grf'

    @client = ConnectionHelper.create_default_connection
    @project = ProjectHelper.get_default_project

    @process = @project.deploy_process('./spec/data/cc/graph/graph.grf',
                                       type: 'GRAPH',
                                       name: 'Test ETL Process')
  end

  after(:all) do
    @client.disconnect
  end

  describe 'params' do
    it 'Works with params' do
      params = {
        :test => '1234'
      }

      res = @process.create_schedule("0 12 * * *", @graph_path, params: params)
      expect(res).to be_true
    end

    it 'Works with nested params' do
      params = {
        :test => '1234',
        :nested => {
          :name => 'joe'
        }
      }

      res = @process.create_schedule("0 12 * * *", @graph_path, params: params)
      expect(res).to be_true
    end

    it 'Works with array in params' do
      params = {
        :test => '1234',
        :array => [1, 2, 3, 4, 5]
      }

      res = @process.create_schedule("0 12 * * *", @graph_path, params: params)
      expect(res).to be_true
    end
  end

  describe 'hiddenParams' do
    it 'Works with hiddenParams' do
      params = {
        :test => '1234'
      }

      res = @process.create_schedule("0 12 * * *", @graph_path, hiddenParams: params)
      expect(res).to be_true
    end

    it 'Works with nested hiddenParams' do
      params = {
        :test => '1234',
        :nested => {
          :name => 'joe'
        }
      }

      res = @process.create_schedule("0 12 * * *", @graph_path, hiddenParams: params)
      expect(res).to be_true
    end

    it 'Works with array in hiddenParams' do
      params = {
        :test => '1234',
        :array => [1, 2, 3, 4, 5]
      }

      res = @process.create_schedule("0 12 * * *", @graph_path, hiddenParams: params)
      expect(res).to be_true
    end
  end
end
