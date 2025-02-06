# /Users/milandufek/dev/gooddata/gooddata-ruby/spec/integration/drivers/mysql_client_test.rb

require 'spec_helper'
require 'gooddata/cloud_resources/mysql/mysql_client'
require 'rspec'
require 'csv'
require 'benchmark'

describe GoodData::CloudResources::MysqlClient do
  before do
    @mysql_host = ENV['MYSQL_HOST'] || 'localhost'
    @mysql_port = ENV['MYSQL_PORT'] || 3306
    @mysql_database = ENV['MYSQL_DB'] || 'mysql'
    @mysql_user = ENV['MYSQL_USER'] || 'root'
    @mysql_password = ENV['MYSQL_SECRET'] || 'root'
  end

  let(:valid_options) do
    {
      'mysql_client' => {
        'connection' => {
          'database' => @mysql_database,
          'schema' => 'public',
          'authentication' => {
            'basic' => {
              'userName' => @mysql_user,
              'password' => @mysql_password
            }
          },
          'sslMode' => 'prefer',
          'url' => "jdbc:mysql://#{@mysql_host}:#{@mysql_port}/#{@mysql_database}"
        }
      }
    }
  end

  describe '.accept?' do
    it 'returns true for mysql type' do
      expect(GoodData::CloudResources::MysqlClient.accept?('mysql')).to be true
    end

    it 'returns false for other types' do
      expect(GoodData::CloudResources::MysqlClient.accept?('postgresql')).to be false
    end
  end

  describe '#initialize' do
    it 'raises an error if mysql_client is missing' do
      options = {}
      expect { GoodData::CloudResources::MysqlClient.new(options) }.to raise_error(RuntimeError, "Data Source needs a client to Mysql to be able to query the storage but 'mysql_client' is empty.")
    end

    it 'raises an error if connection info is missing' do
      options = { 'mysql_client' => {} }
      expect { GoodData::CloudResources::MysqlClient.new(options) }.to raise_error(RuntimeError, 'Missing connection info for Mysql client')
    end

    it 'raises an error if sslMode is invalid' do
      invalid_options = valid_options.dup
      invalid_options['mysql_client']['connection']['sslMode'] = 'invalid'
      expect { GoodData::CloudResources::MysqlClient.new(invalid_options) }.to raise_error(RuntimeError, 'SSL Mode should be prefer, require and verify-full')
    end

    it 'initializes with valid options' do
      client = GoodData::CloudResources::MysqlClient.new(valid_options)
      expect(client).not_to be_nil
    end
  end

  describe '#build_url' do
    it 'builds the correct URL' do
      client = GoodData::CloudResources::MysqlClient.new(valid_options)
      expected_url = "jdbc:mysql://#{@mysql_host}:#{@mysql_port}/#{@mysql_database}?&useSSL=true&requireSSL=false&verifyServerCertificate=false&useCursorFetch=true&enabledTLSProtocols=TLSv1.2"
      expect(client.send(:build_url, "jdbc:mysql://#{@mysql_host}:#{@mysql_port}")).to eq(expected_url)
    end
  end

  describe '#connect' do
    it 'sets up the connection' do
      client = GoodData::CloudResources::MysqlClient.new(valid_options)
      client.connect
      expect(client.instance_variable_get(:@connection)).not_to be_nil
    end
  end

  describe '#realize_query' do
    it 'executes the query and writes results to a CSV file' do
      client = GoodData::CloudResources::MysqlClient.new(valid_options)
      client.connect
      output_file = client.realize_query('SELECT 123;', {})
      expect(File).to exist(output_file)
      expect(File.read(output_file)).to include('123')
      File.delete(output_file)
    end
  end

  describe '#fetch_size' do
    it 'returns the correct fetch size for MySQL' do
      client = GoodData::CloudResources::MysqlClient.new(valid_options)
      expect(client.fetch_size).to eq(GoodData::CloudResources::MysqlClient::MYSQL_FETCH_SIZE)
    end

    it 'returns the correct fetch size for MongoDB BI Connector' do
      mongo_options = valid_options.dup
      mongo_options['mysql_client']['connection']['databaseType'] = GoodData::CloudResources::MysqlClient::MONGO_BI_TYPE
      client = GoodData::CloudResources::MysqlClient.new(mongo_options)
      expect(client.fetch_size).to eq(GoodData::CloudResources::MysqlClient::MONGO_BI_FETCH_SIZE)
    end
  end

  describe '#get_ssl_mode' do
    it 'returns the correct SSL mode for prefer' do
      client = GoodData::CloudResources::MysqlClient.new(valid_options)
      expect(client.send(:get_ssl_mode, 'prefer')).to eq(GoodData::CloudResources::MysqlClient::PREFER)
    end

    it 'returns the correct SSL mode for require' do
      client = GoodData::CloudResources::MysqlClient.new(valid_options)
      expect(client.send(:get_ssl_mode, 'require')).to eq(GoodData::CloudResources::MysqlClient::REQUIRE)
    end

    it 'returns the correct SSL mode for verify-full' do
      client = GoodData::CloudResources::MysqlClient.new(valid_options)
      expect(client.send(:get_ssl_mode, 'verify-full')).to eq(GoodData::CloudResources::MysqlClient::VERIFY_FULL)
    end
  end

  describe '#add_extended' do
    it 'returns the correct extended parameters for MongoDB BI Connector' do
      mongo_options = valid_options.dup
      mongo_options['mysql_client']['connection']['databaseType'] = GoodData::CloudResources::MysqlClient::MONGO_BI_TYPE
      client = GoodData::CloudResources::MysqlClient.new(mongo_options)
      expect(client.send(:add_extended)).to eq('&authenticationPlugins=org.mongodb.mongosql.auth.plugin.MongoSqlAuthenticationPlugin&useLocalTransactionState=true')
    end

    it 'returns an empty string for MySQL' do
      client = GoodData::CloudResources::MysqlClient.new(valid_options)
      expect(client.send(:add_extended)).to eq('')
    end
  end
end
