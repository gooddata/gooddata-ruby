# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

shared_examples 'a component process' do
  let(:name) { 'test component' }
  it 'can be deployed' do
    @component = GoodData::Process.deploy_component component_data, client: @rest_client, project: @project
    expect(@component.name).to eq name
    expect(@component.type).to eq :etl
  end
end

describe GoodData::Process, :vcr do
  before(:all) do
    @rest_client = ConnectionHelper.create_default_connection
    @project = ProjectHelper.get_default_project client: @rest_client
    @archive_location = './spec/data/cc'
    @options = { project: @project, client: @rest_client }
  end

  after(:all) do
    @rest_client.disconnect
  end

  def create_process
    GoodData::Process.deploy(@archive_location, @options.merge(name: 'Test process GRAPH'))
  end

  def destroy_process(process)
    process.delete if process
  end

  describe '.deploy_component' do
    it_behaves_like 'a component process' do
      let(:component_data) do
        {
          name: name,
          type: :etl,
          component: {
            name: 'gdc-etl-sql-executor',
            version: '1'
          }
        }
      end
    end

    it_behaves_like 'a component process' do
      let(:component_data) do
        {
          name: name,
          type: :etl,
          component: {
            name: 'gdc-etl-csv-downloader',
            version: '1',
            configLocation: {
              s3: {
                path: 's3://s3_bucket/s3_folder/',
                accessKey: 's3_access_key',
                secretKey: 's3_secret_key',
                serverSideEncryption: true
              }
            }
          }
        }
      end
    end

    context 'when component type is add-v2' do
      before do
        @data_source_id = GoodData::Helpers::DataSourceHelper.create_snowflake_data_source(@rest_client)
      end

      after do
        @component.delete if @component
        GoodData::Helpers::DataSourceHelper.delete(@data_source_id) if @data_source_id
      end

      it_behaves_like 'a component process' do
        let(:component_data) do
          {
            name: name,
            type: :etl,
            component: {
              name: 'gdc-data-distribution',
              version: '1',
              config: {
                dataDistribution: {
                  dataSource: @data_source_id
                }
              }
            }
          }
        end
      end
    end
  end

  describe '#deploy' do
    context 'as class method, deploying a GRAPH' do
      it 'should return a new process' do
        @new_process = create_process
        expect(@new_process).to be_an_instance_of(GoodData::Process)
      end
    end
  end

  describe '.deploy' do
    context 'as instance method, deploying a GRAPH' do
      it 'should redeploy the process and the object_id of returned object should stay the same' do
        new_process = create_process
        @redeployed_process = new_process.deploy(@archive_location)
        expect(@redeployed_process).to be_instance_of(GoodData::Process)
        expect(@redeployed_process.process_id).to eql(new_process.process_id)
        destroy_process(@redeployed_process)
      end
    end
  end

  describe '#[] method' do
    context 'with :all an without :project' do
      it 'should return list all processes within projects accessible to user' do
        expect(GoodData::Process[:all, { client: @rest_client }]).to be_an_instance_of(Array)
      end
    end
  end

  after(:all) do
    destroy_process(@redeployed_process)
    destroy_process(@new_process)
  end
end
