# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

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
    @process.delete
    @client.disconnect
  end

  describe 'params' do
    it 'Works with params' do
      params = {
        :test => '1234'
      }

      begin
        schedule = @process.create_schedule("0 12 * * *", @graph_path, params: params)
        expect(schedule).to be_truthy
      ensure
        schedule && schedule.delete
      end
    end

    it 'Works with nested params' do
      params = {
        :test => '1234',
        :nested => {
          :name => 'joe'
        }
      }

      begin
        schedule = @process.create_schedule("0 12 * * *", @graph_path, params: params)
        expect(schedule).to be_truthy
      ensure
        schedule && schedule.delete
      end
    end

    it 'Works with array in params' do
      params = {
        :test => '1234',
        :array => [1, 2, 3, 4, 5]
      }

      begin
        schedule = @process.create_schedule("0 12 * * *", @graph_path, params: params)
        expect(schedule).to be_truthy
      ensure
        schedule && schedule.delete
      end
    end
  end

  describe 'hiddenParams' do
    it 'Works with hiddenParams' do
      params = {
        :test => '1234'
      }

      begin
        schedule = @process.create_schedule("0 12 * * *", @graph_path, hiddenParams: params)
        expect(schedule).to be_truthy
      ensure
        schedule && schedule.delete
      end
    end

    it 'Works with nested hiddenParams' do
      params = {
        :test => '1234',
        :nested => {
          :name => 'joe'
        }
      }

      begin
        schedule = @process.create_schedule("0 12 * * *", @graph_path, hiddenParams: params)
        expect(schedule).to be_truthy
      ensure
        schedule && schedule.delete
      end
    end

    it 'Works with array in hiddenParams' do
      params = {
        :test => '1234',
        :array => [1, 2, 3, 4, 5]
      }

      begin
        schedule = @process.create_schedule("0 12 * * *", @graph_path, hiddenParams: params)
        expect(schedule).to be_truthy
      ensure
        schedule && schedule.delete
      end
    end
  end
end
