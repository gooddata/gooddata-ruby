require 'spec_helper'
require 'gooddata/cloud_resources/mssql/mssql_client'
require 'rspec'

describe GoodData::CloudResources::MSSQLClient do
  before do
    @mssql_host = ENV['MSSQL_HOST'] || 'localhost'
    @mssql_port = ENV['MSSQL_PORT'] || 1433
    @mssql_database = ENV['MSSQL_DB'] || 'master'
    @mssql_user = ENV['MSSQL_USER'] || 'sa'
    @mssql_password = ENV['MSSQL_PASSWORD'] || 'Password123'
  end

  let(:valid_options) do
    {
      'mssql_client' => {
        'connection' => {
          'database' => @mssql_database,
          'schema' => 'dbo',
          'authentication' => {
            'basic' => {
              'userName' => @mssql_user,
              'password' => @mssql_password
            }
          },
          'sslMode' => 'prefer',
          'url' => "jdbc:sqlserver://#{@mssql_host}:#{@mssql_port}"
        }
      }
    }
  end

  describe '.accept?' do
    it 'returns true for mssql type' do
      expect(GoodData::CloudResources::MSSQLClient.accept?('mssql')).to be true
    end

    it 'returns false for other types' do
      expect(GoodData::CloudResources::MSSQLClient.accept?('mysql')). to be false
    end
  end

  describe '#build_connection_string' do
    it 'builds a valid connection string' do
      client = GoodData::CloudResources::MSSQLClient.new(valid_options)
      connection_string = client.send(:build_connection_string)
      expect(connection_string).to eq("jdbc:sqlserver://#{@mssql_host}:#{@mssql_port};database=#{@mssql_database};"\
                                      "encrypt=false;trustServerCertificate=false;loginTimeout=30;")
    end
  end

  describe '#initialize' do
    it 'raises an error if mssql_client is missing' do
      expect { GoodData::CloudResources::MSSQLClient.new({}) }.to raise_error(RuntimeError, "Data Source needs a client to MSSQL to be able to query the storage but 'mssql_client' is empty.")
    end

    it 'initializes with valid options' do
      client = GoodData::CloudResources::MSSQLClient.new(valid_options)
      expect(client).to be_an_instance_of(GoodData::CloudResources::MSSQLClient)
    end

    it 'connects to SQL Server and selects the version' do
      client = GoodData::CloudResources::MSSQLClient.new(valid_options)
      version_csv = client.realize_query('SELECT @@VERSION', nil)
      expect(File).to exist(version_csv)
      expect(File.read(version_csv)).to include('Microsoft SQL Server')
      File.delete(version_csv)
    end
  end
end
