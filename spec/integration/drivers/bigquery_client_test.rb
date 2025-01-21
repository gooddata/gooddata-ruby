require 'spec_helper'
require 'gooddata/cloud_resources/bigquery/bigquery_client'
require 'rspec'
require 'csv'
require 'benchmark'

describe GoodData::CloudResources::BigQueryClient do
  before do
    @project = ENV['BIGQUERY_PROJECT_ID'] || 'test-project'
    @schema = ENV['BIGQUERY_SCHEMA'] || 'public'
    @client_email = ENV['BIGQUERY_CLIENT_EMAIL'] || 'test-client-email'
    @private_key = ENV['BIGQUERY_PRIVATE_KEY'] || 'test-private-key'
  end

  let(:valid_options) do
    {
      'bigquery_client' => {
        'connection' => {
          'project' => @project,
          'schema' => @schema,
          'authentication' => {
            'serviceAccount' => {
              'clientEmail' => @client_email,
              'privateKey' => @private_key
            }
          }
        }
      }
    }
  end

  describe '.accept?' do
    it 'returns true for bigquery type' do
      expect(GoodData::CloudResources::BigQueryClient.accept?('bigquery')).to be true
    end

    it 'returns false for other types' do
      expect(GoodData::CloudResources::BigQueryClient.accept?('mysql')).to be false
    end
  end

  describe '#initialize' do
    it 'raises an error if bigquery_client is missing' do
      expect { GoodData::CloudResources::BigQueryClient.new({}) }.to raise_error(RuntimeError, "Data Source needs a client to BigQuery to be able to query the storage but 'bigquery_client' is empty.")
    end

    it 'initializes with valid options' do
      client = GoodData::CloudResources::BigQueryClient.new(valid_options)
      expect(client).to be_an_instance_of(GoodData::CloudResources::BigQueryClient)
    end
  end

  describe '#create_client' do
    it 'creates a BigQuery client' do
      client = GoodData::CloudResources::BigQueryClient.new(valid_options)
      bigquery_client = client.send(:create_client)
      expect(bigquery_client).to be_a(Java::ComGoogleCloudBigquery::BigQuery)
    end
  end

  describe '#realize_query' do
    it 'executes a query and returns a CSV filename' do
      client = GoodData::CloudResources::BigQueryClient.new(valid_options)
      output_file = client.realize_query('select 50 + 50 as SUM', nil)
      expect(File.read(output_file)).to include('100')
      File.delete(output_file)
    end
  end
end
