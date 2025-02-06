# spec/lib/gooddata/cloud_resources/postgresql/postgresql_client_spec.rb

require 'spec_helper'
require 'gooddata/cloud_resources/postgresql/postgresql_client'
require 'rspec'
require 'csv'
require 'benchmark'

describe GoodData::CloudResources::PostgresClient do
  before do
    @postresql_host = ENV['POSTGRES_HOST'] || 'localhost'
    @postresql_port = ENV['POSTGRES_PORT'] || 5432
    @postresql_database = ENV['POSTGRES_DB'] || 'postgres'
    @postgres_schema = ENV['POSTGRES_SCHEMA'] || 'public'
    @postresql_user = ENV['POSTGRES_USER'] || 'postgres'
    @postresql_password = ENV['POSTGRES_SECRET'] || 'postgres'
  end

  let(:valid_options) do
    {
      'postgresql_client' => {
        'connection' => {
          'database' => @postresql_database,
          'schema' => @postgres_schema,
          'authentication' => {
            'basic' => {
              'userName' => @postresql_user,
              'password' => @postresql_password
            }
          },
          'sslMode' => 'prefer',
          'url' => "jdbc:postgresql://#{@postresql_host}:#{@postresql_port}/#{@postresql_database}"
        }
      }
    }
  end

  describe '.accept?' do
    it 'returns true for postgresql type' do
      expect(GoodData::CloudResources::PostgresClient.accept?('postgresql')).to be true
    end

    it 'returns false for other types' do
      expect(GoodData::CloudResources::PostgresClient.accept?('mysql')).to be false
    end
  end

  describe '#initialize' do
    it 'raises an error if postgresql_client is missing' do
      options = {}
      expect { GoodData::CloudResources::PostgresClient.new(options) }.to raise_error(RuntimeError, "Data Source needs a client to Postgres to be able to query the storage but 'postgresql_client' is empty.")
    end

    it 'raises an error if connection info is missing' do
      options = { 'postgresql_client' => {} }
      expect { GoodData::CloudResources::PostgresClient.new(options) }.to raise_error(RuntimeError, 'Missing connection info for Postgres client')
    end

    it 'raises an error if sslMode is invalid' do
      invalid_options = valid_options.dup
      invalid_options['postgresql_client']['connection']['sslMode'] = 'invalid'
      expect { GoodData::CloudResources::PostgresClient.new(invalid_options) }.to raise_error(RuntimeError, 'SSL Mode should be prefer, require and verify-full')
    end

    it 'initializes with valid options' do
      client = GoodData::CloudResources::PostgresClient.new(valid_options)
      expect(client).not_to be_nil
    end
  end

  describe '#build_url' do
    it 'builds the correct URL' do
      client = GoodData::CloudResources::PostgresClient.new(valid_options)
      expected_url = "jdbc:postgresql://#{@postresql_host}:#{@postresql_port}/#{@postresql_database}?sslmode=prefer"
      expect(client.send(:build_url, "jdbc:postgresql://#{@postresql_host}:#{@postresql_port}")).to eq(expected_url)
    end
  end

  describe '#connect' do
    it 'sets up the connection' do
      client = GoodData::CloudResources::PostgresClient.new(valid_options)
      client.connect
      expect(client.instance_variable_get(:@connection)).not_to be_nil
    end
  end

  describe '#realize_query_version' do
    it 'executes the query with postgres version and writes results to a CSV file' do
      client = GoodData::CloudResources::PostgresClient.new(valid_options)
      client.connect
      output_file = client.realize_query('SELECT version();', {})
      expect(File).to exist(output_file)
      expect(File.read(output_file)).to include('PostgreSQL')
      File.delete(output_file)
    end
  end
end
