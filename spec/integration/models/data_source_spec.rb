# encoding: UTF-8
#
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/models/data_source'

describe GoodData::DataSource, :vcr do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
  end

  after(:all) do
    @client.disconnect
  end

  describe '#snowflake_data_source' do
    before(:each) do
      @model = {
          'dataSource' => {
              'name' => 'SnowflakeDS',
              'alias' => 'SnowflakeDS_alias',
              'prefix' => 'prefix_',
              'connectionInfo' => {
                  'snowflake' => {
                      'url' => 'jdbc:snowflake://test',
                      'authentication' => {
                          'basic' => {
                              'userName' => 'test',
                              'password' => 'abc123'
                          }
                      },
                      'database' => 'database_test',
                      'schema' => 'schema_test',
                      'warehouse' => 'warehouse_test'
                  }
              }
          }
      }
    end

    it 'should create snowflake data source success' do
      snowflake_ds = @client.create(GoodData::DataSource, @model)
      connection_info = snowflake_ds.connection_info

      expect(snowflake_ds.name).to eq('SnowflakeDS')
      expect(snowflake_ds.alias).to eq('SnowflakeDS_alias')
      expect(snowflake_ds.prefix).to eq('prefix_')
      expect(snowflake_ds.saved?).to eq false
      expect(connection_info.url).to eq('jdbc:snowflake://test')
      expect(connection_info.user_name).to eq('test')
      expect(connection_info.password).to eq('abc123')
      expect(connection_info.database).to eq('database_test')
      expect(connection_info.schema).to eq('schema_test')
      expect(connection_info.warehouse).to eq('warehouse_test')
    end

    it 'should update snowflake data source success' do
      snowflake_ds = @client.create(GoodData::DataSource, @model)
      connection_info = snowflake_ds.connection_info

      snowflake_ds.name = 'SnowflakeDS_new'
      snowflake_ds.alias = 'SnowflakeDS_new_alias'
      snowflake_ds.prefix = 'prefix_new_'
      connection_info.url = 'jdbc:snowflake://test_new'
      connection_info.user_name = 'test_new'
      connection_info.password = 'abc_new'
      connection_info.database = 'database_new'
      connection_info.schema = 'schema_new'
      connection_info.warehouse = 'warehouse_new'

      expect(snowflake_ds.name).to eq('SnowflakeDS_new')
      expect(snowflake_ds.alias).to eq('SnowflakeDS_new_alias')
      expect(snowflake_ds.prefix).to eq('prefix_new_')
      expect(snowflake_ds.saved?).to eq false
      expect(connection_info.url).to eq('jdbc:snowflake://test_new')
      expect(connection_info.user_name).to eq('test_new')
      expect(connection_info.password).to eq('abc_new')
      expect(connection_info.database).to eq('database_new')
      expect(connection_info.schema).to eq('schema_new')
      expect(connection_info.warehouse).to eq('warehouse_new')
    end

    it 'save should be failed with empty data source name' do
      snowflake_ds = @client.create(GoodData::DataSource, @model)
      snowflake_ds.name = ''
      expect { snowflake_ds.save }.to raise_error do |e|
        expect(e.message).to eq('Data source name has to be provided')
      end
    end

    it 'save should be failed with empty data source url' do
      snowflake_ds = @client.create(GoodData::DataSource, @model)
      connection_info = snowflake_ds.connection_info
      connection_info.url = ''
      expect { snowflake_ds.save }.to raise_error do |e|
        expect(e.message).to eq('Data source url has to be provided')
      end
    end

    it 'save should be failed with empty data source database' do
      snowflake_ds = @client.create(GoodData::DataSource, @model)
      connection_info = snowflake_ds.connection_info
      connection_info.database = ''
      expect { snowflake_ds.save }.to raise_error do |e|
        expect(e.message).to eq('Data source database has to be provided')
      end
    end

    it 'save should be failed with empty data source schema' do
      snowflake_ds = @client.create(GoodData::DataSource, @model)
      connection_info = snowflake_ds.connection_info
      connection_info.schema = ''
      expect { snowflake_ds.save }.to raise_error do |e|
        expect(e.message).to eq('Data source schema has to be provided')
      end
    end

    it 'save should be failed with empty data source warehouse' do
      snowflake_ds = @client.create(GoodData::DataSource, @model)
      connection_info = snowflake_ds.connection_info
      connection_info.warehouse = ''
      expect { snowflake_ds.save }.to raise_error do |e|
        expect(e.message).to eq('Data source warehouse has to be provided')
      end
    end

    it 'save should be failed with empty data source username' do
      snowflake_ds = @client.create(GoodData::DataSource, @model)
      connection_info = snowflake_ds.connection_info
      connection_info.user_name = ''
      expect { snowflake_ds.save }.to raise_error do |e|
        expect(e.message).to eq('Data source username has to be provided')
      end
    end

    it 'create should success' do
      begin
        ds_alias = GoodData::Rest::Connection.generate_string
        opts = {
            :name => @model['dataSource']['name'],
            :alias => ds_alias,
            :prefix => @model['dataSource']['prefix'],
            :connectionInfo => @model['dataSource']['connectionInfo'],
            :client => @client
        }
        snowflake_ds = GoodData::DataSource.create(opts)

        connection_info = snowflake_ds.connection_info
        expect(snowflake_ds.name).to eq('SnowflakeDS')
        expect(snowflake_ds.prefix).to eq('prefix_')
        expect(connection_info.url).to eq('jdbc:snowflake://test')
        expect(connection_info.user_name).to eq('test')
        expect(connection_info.password).to eq('')
        expect(connection_info.database).to eq('database_test')
        expect(connection_info.schema).to eq('schema_test')
        expect(connection_info.warehouse).to eq('warehouse_test')
      ensure
        snowflake_ds.delete if snowflake_ds
      end
    end

    it 'update should success' do
      begin
        ds_alias = GoodData::Rest::Connection.generate_string
        opts = {
            :name => @model['dataSource']['name'],
            :alias => ds_alias,
            :prefix => @model['dataSource']['prefix'],
            :connectionInfo => @model['dataSource']['connectionInfo'],
            :client => @client
        }
        snowflake_ds = GoodData::DataSource.create(opts)
        snowflake_ds.name = 'SnowflakeDS_new'
        updatedDS = snowflake_ds.save

        connection_info = updatedDS.connection_info
        expect(updatedDS.name).to eq('SnowflakeDS_new')
        expect(updatedDS.prefix).to eq('prefix_')
        expect(connection_info.url).to eq('jdbc:snowflake://test')
        expect(connection_info.user_name).to eq('test')
        expect(connection_info.password).to eq('')
        expect(connection_info.database).to eq('database_test')
        expect(connection_info.schema).to eq('schema_test')
        expect(connection_info.warehouse).to eq('warehouse_test')
      ensure
        snowflake_ds.delete if snowflake_ds
      end
    end

    it 'delete should success' do
      ds_alias = GoodData::Rest::Connection.generate_string
      opts = {
          :name => @model['dataSource']['name'],
          :alias => ds_alias,
          :prefix => @model['dataSource']['prefix'],
          :connectionInfo => @model['dataSource']['connectionInfo'],
          :client => @client
      }
      snowflake_ds = GoodData::DataSource.create(opts)
      snowflake_ds.delete

      expect { GoodData::DataSource.from_id(snowflake_ds.id) }.to raise_error do |e|
        expect(e.message.include? '404 Not Found').to eq true
      end
    end

    it 'get from id should success' do
      begin
        ds_alias = GoodData::Rest::Connection.generate_string
        opts = {
            :name => @model['dataSource']['name'],
            :alias => ds_alias,
            :prefix => @model['dataSource']['prefix'],
            :connectionInfo => @model['dataSource']['connectionInfo'],
            :client => @client
        }
        snowflake_ds = GoodData::DataSource.create(opts)
        snowflake_ds = GoodData::DataSource.from_id(snowflake_ds.id)

        connection_info = snowflake_ds.connection_info
        expect(snowflake_ds.name).to eq('SnowflakeDS')
        expect(snowflake_ds.prefix).to eq('prefix_')
        expect(connection_info.url).to eq('jdbc:snowflake://test')
        expect(connection_info.user_name).to eq('test')
        expect(connection_info.password).to eq('')
        expect(connection_info.database).to eq('database_test')
        expect(connection_info.schema).to eq('schema_test')
        expect(connection_info.warehouse).to eq('warehouse_test')
      ensure
        snowflake_ds.delete if snowflake_ds
      end
    end

    it 'get from alias should success' do
      begin
        ds_alias = GoodData::Rest::Connection.generate_string
        opts = {
            :name => @model['dataSource']['name'],
            :alias => ds_alias,
            :prefix => @model['dataSource']['prefix'],
            :connectionInfo => @model['dataSource']['connectionInfo'],
            :client => @client
        }
        snowflake_ds = GoodData::DataSource.create(opts)
        snowflake_ds = GoodData::DataSource.from_alias(snowflake_ds.alias)

        connection_info = snowflake_ds.connection_info
        expect(snowflake_ds.name).to eq('SnowflakeDS')
        expect(snowflake_ds.prefix).to eq('prefix_')
        expect(connection_info.url).to eq('jdbc:snowflake://test')
        expect(connection_info.user_name).to eq('test')
        expect(connection_info.password).to eq('')
        expect(connection_info.database).to eq('database_test')
        expect(connection_info.schema).to eq('schema_test')
        expect(connection_info.warehouse).to eq('warehouse_test')
      ensure
        snowflake_ds.delete if snowflake_ds
      end
    end

    it 'get all should success' do
      begin
        ds_alias = GoodData::Rest::Connection.generate_string
        opts = {
            :name => @model['dataSource']['name'],
            :alias => ds_alias,
            :prefix => @model['dataSource']['prefix'],
            :connectionInfo => @model['dataSource']['connectionInfo'],
            :client => @client
        }
        snowflake_ds = GoodData::DataSource.create(opts)
        all_ds = GoodData::DataSource.all
        expect(all_ds.length > 0).to eq true
      ensure
        snowflake_ds.delete if snowflake_ds
      end
    end
  end

  describe '#redshift_data_source' do
    describe '#basic_authentication' do
      before(:each) do
        @model = {
            'dataSource' => {
                'name' => 'RedshiftDS',
                'alias' => GoodData::Rest::Connection.generate_string,
                'prefix' => 'prefix_',
                'connectionInfo' => {
                    'redshift' => {
                        'url' => 'jdbc:redshift://test',
                        'authentication' => {
                            'basic' => {
                                'userName' => 'test',
                                'password' => 'abc123'
                            }
                        },
                        'database' => 'database_test',
                        'schema' => 'schema_test'
                    }
                }
            }
        }
      end

      it 'should create redshift data source success' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        connection_info = redshift_ds.connection_info

        expect(redshift_ds.name).to eq('RedshiftDS')
        expect(redshift_ds.alias).to eq(@model['dataSource']['alias'])
        expect(redshift_ds.prefix).to eq('prefix_')
        expect(redshift_ds.saved?).to eq false
        expect(connection_info.url).to eq('jdbc:redshift://test')
        expect(connection_info.user_name).to eq('test')
        expect(connection_info.password).to eq('abc123')
        expect(connection_info.database).to eq('database_test')
        expect(connection_info.schema).to eq('schema_test')
      end

      it 'should update redshift data source success' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        connection_info = redshift_ds.connection_info

        redshift_ds.name = 'RedshiftDS_new'
        redshift_ds.alias = 'RedshiftDS_new_alias'
        redshift_ds.prefix = 'prefix_new_'
        connection_info.url = 'jdbc:redshift://test_new'
        connection_info.user_name = 'test_new'
        connection_info.password = 'abc_new'
        connection_info.database = 'database_new'
        connection_info.schema = 'schema_new'

        expect(redshift_ds.name).to eq('RedshiftDS_new')
        expect(redshift_ds.alias).to eq('RedshiftDS_new_alias')
        expect(redshift_ds.prefix).to eq('prefix_new_')
        expect(redshift_ds.saved?).to eq false
        expect(connection_info.url).to eq('jdbc:redshift://test_new')
        expect(connection_info.user_name).to eq('test_new')
        expect(connection_info.password).to eq('abc_new')
        expect(connection_info.database).to eq('database_new')
        expect(connection_info.schema).to eq('schema_new')
      end

      it 'save should be failed with empty data source name' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        redshift_ds.name = ''
        expect { redshift_ds.save }.to raise_error do |e|
          expect(e.message).to eq('Data source name has to be provided')
        end
      end

      it 'save should be failed with empty data source url' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        connection_info = redshift_ds.connection_info
        connection_info.url = ''
        expect { redshift_ds.save }.to raise_error do |e|
          expect(e.message).to eq('Data source url has to be provided')
        end
      end

      it 'save should be failed with empty data source database' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        connection_info = redshift_ds.connection_info
        connection_info.database = ''
        expect { redshift_ds.save }.to raise_error do |e|
          expect(e.message).to eq('Data source database has to be provided')
        end
      end

      it 'save should be failed with empty data source schema' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        connection_info = redshift_ds.connection_info
        connection_info.schema = ''
        expect { redshift_ds.save }.to raise_error do |e|
          expect(e.message).to eq('Data source schema has to be provided')
        end
      end

      it 'save should be failed with empty data source username' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        connection_info = redshift_ds.connection_info
        connection_info.user_name = ''
        expect { redshift_ds.save }.to raise_error do |e|
          expect(e.message).to eq('Data source username has to be provided')
        end
      end

      it 'create should success' do
        begin
          redshift_ds = @client.create(GoodData::DataSource, @model)
          redshift_ds.save

          connection_info = redshift_ds.connection_info
          expect(redshift_ds.name).to eq('RedshiftDS')
          expect(redshift_ds.prefix).to eq('prefix_')
          expect(redshift_ds.saved?).to eq true
          expect(connection_info.url).to eq('jdbc:redshift://test')
          expect(connection_info.user_name).to eq('test')
          expect(connection_info.password).to eq('')
          expect(connection_info.database).to eq('database_test')
          expect(connection_info.schema).to eq('schema_test')
        ensure
          redshift_ds.delete if redshift_ds
        end
      end

      it 'update should success' do
        begin
          redshift_ds = @client.create(GoodData::DataSource, @model)
          redshift_ds.save
          redshift_ds.name = 'RedshiftDS_update'
          updated_ds = redshift_ds.save

          connection_info = updated_ds.connection_info
          expect(updated_ds.name).to eq('RedshiftDS_update')
          expect(updated_ds.prefix).to eq('prefix_')
          expect(updated_ds.saved?).to eq true
          expect(connection_info.url).to eq('jdbc:redshift://test')
          expect(connection_info.user_name).to eq('test')
          expect(connection_info.password).to eq('')
          expect(connection_info.database).to eq('database_test')
          expect(connection_info.schema).to eq('schema_test')
        ensure
          redshift_ds.delete if redshift_ds
        end
      end

      it 'delete should success' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        redshift_ds.save
        redshift_ds.delete

        expect { GoodData::DataSource.from_id(redshift_ds.id) }.to raise_error do |e|
          expect(e.message.include? '404 Not Found').to eq true
        end
      end
    end

    describe '#iam_authentication' do
      before(:each) do
        @model = {
            'dataSource' => {
                'name' => 'RedshiftDS_IAM',
                'alias' => GoodData::Rest::Connection.generate_string,
                'prefix' => 'prefix_',
                'connectionInfo' => {
                    'redshift' => {
                        'url' => 'jdbc:redshift://test',
                        'authentication' => {
                            'iam' => {
                                'dbUser' => 'user_iam_test',
                                'accessKeyId' => 'OWIUEWQIO723628',
                                'secretAccessKey' => 'abc123'
                            }
                        },
                        'database' => 'database_test',
                        'schema' => 'schema_test'
                    }
                }
            }
        }
      end

      it 'should create redshift data source success' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        connection_info = redshift_ds.connection_info

        expect(redshift_ds.name).to eq('RedshiftDS_IAM')
        expect(redshift_ds.alias).to eq(@model['dataSource']['alias'])
        expect(redshift_ds.prefix).to eq('prefix_')
        expect(redshift_ds.saved?).to eq false
        expect(connection_info.url).to eq('jdbc:redshift://test')
        expect(connection_info.db_user).to eq('user_iam_test')
        expect(connection_info.access_key_id).to eq('OWIUEWQIO723628')
        expect(connection_info.secret_access_key).to eq('abc123')
        expect(connection_info.database).to eq('database_test')
        expect(connection_info.schema).to eq('schema_test')
      end

      it 'should update redshift data source success' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        connection_info = redshift_ds.connection_info

        redshift_ds.name = 'RedshiftDS_IAM_new'
        redshift_ds.alias = 'RedshiftDS_IAM_new_alias'
        redshift_ds.prefix = 'prefix_new_'
        connection_info.url = 'jdbc:redshift://test_new'
        connection_info.db_user = 'user_iam_test_new'
        connection_info.access_key_id = 'OWIUEWQIO723628_new'
        connection_info.secret_access_key = 'abc123_new'
        connection_info.database = 'database_new'
        connection_info.schema = 'schema_new'

        expect(redshift_ds.name).to eq('RedshiftDS_IAM_new')
        expect(redshift_ds.alias).to eq('RedshiftDS_IAM_new_alias')
        expect(redshift_ds.prefix).to eq('prefix_new_')
        expect(redshift_ds.saved?).to eq false
        expect(connection_info.url).to eq('jdbc:redshift://test_new')
        expect(connection_info.db_user).to eq('user_iam_test_new')
        expect(connection_info.access_key_id).to eq('OWIUEWQIO723628_new')
        expect(connection_info.secret_access_key).to eq('abc123_new')
        expect(connection_info.database).to eq('database_new')
        expect(connection_info.schema).to eq('schema_new')
      end

      it 'save should be failed with empty data source name' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        redshift_ds.name = ''
        expect { redshift_ds.save }.to raise_error do |e|
          expect(e.message).to eq('Data source name has to be provided')
        end
      end

      it 'save should be failed with empty data source url' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        connection_info = redshift_ds.connection_info
        connection_info.url = ''
        expect { redshift_ds.save }.to raise_error do |e|
          expect(e.message).to eq('Data source url has to be provided')
        end
      end

      it 'save should be failed with empty data source database' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        connection_info = redshift_ds.connection_info
        connection_info.database = ''
        expect { redshift_ds.save }.to raise_error do |e|
          expect(e.message).to eq('Data source database has to be provided')
        end
      end

      it 'save should be failed with empty data source schema' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        connection_info = redshift_ds.connection_info
        connection_info.schema = ''
        expect { redshift_ds.save }.to raise_error do |e|
          expect(e.message).to eq('Data source schema has to be provided')
        end
      end

      it 'save should be failed with empty data source db_user' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        connection_info = redshift_ds.connection_info
        connection_info.db_user = ''
        expect { redshift_ds.save }.to raise_error do |e|
          expect(e.message).to eq('Data source db_user has to be provided')
        end
      end

      it 'create should success' do
        begin
          redshift_ds = @client.create(GoodData::DataSource, @model)
          redshift_ds.save

          connection_info = redshift_ds.connection_info
          expect(redshift_ds.name).to eq('RedshiftDS_IAM')
          expect(redshift_ds.prefix).to eq('prefix_')
          expect(redshift_ds.saved?).to eq true
          expect(connection_info.url).to eq('jdbc:redshift://test')
          expect(connection_info.db_user).to eq('user_iam_test')
          expect(connection_info.access_key_id).to eq('OWIUEWQIO723628')
          expect(connection_info.secret_access_key).to eq('')
          expect(connection_info.database).to eq('database_test')
          expect(connection_info.schema).to eq('schema_test')
        ensure
          redshift_ds.delete if redshift_ds
        end
      end

      it 'update should success' do
        begin
          redshift_ds = @client.create(GoodData::DataSource, @model)
          redshift_ds.save
          redshift_ds.name='RedshiftDS_IAM_New'
          updated_ds = redshift_ds.save

          connection_info = updated_ds.connection_info
          expect(updated_ds.name).to eq('RedshiftDS_IAM_New')
          expect(updated_ds.prefix).to eq('prefix_')
          expect(updated_ds.saved?).to eq true
          expect(connection_info.url).to eq('jdbc:redshift://test')
          expect(connection_info.db_user).to eq('user_iam_test')
          expect(connection_info.access_key_id).to eq('OWIUEWQIO723628')
          expect(connection_info.secret_access_key).to eq('')
          expect(connection_info.database).to eq('database_test')
          expect(connection_info.schema).to eq('schema_test')
        ensure
          redshift_ds.delete if redshift_ds
        end
      end

      it 'delete should success' do
        redshift_ds = @client.create(GoodData::DataSource, @model)
        redshift_ds.save
        redshift_ds.delete

        expect { GoodData::DataSource.from_id(redshift_ds.id) }.to raise_error do |e|
          expect(e.message.include? '404 Not Found').to eq true
        end
      end
    end
  end

  describe '#bigQuery_data_source' do
    before(:each) do
      @model = {
          'dataSource' => {
              'name' => 'BigQueryDS',
              'alias' => GoodData::Rest::Connection.generate_string,
              'prefix' => 'prefix_',
              'connectionInfo' => {
                  'bigQuery' => {
                      'authentication' => {
                          'serviceAccount' => {
                              'clientEmail' => 'test@client.com',
                              'privateKey' => 'abc123'
                          }
                      },
                      'project' => 'project_test',
                      'schema' => 'schema_test'
                  }
              }
          }
      }
    end

    it 'should create bigquery data source success' do
      bigquery_ds = @client.create(GoodData::DataSource, @model)
      connection_info = bigquery_ds.connection_info

      expect(bigquery_ds.name).to eq('BigQueryDS')
      expect(bigquery_ds.alias).to eq(@model['dataSource']['alias'])
      expect(bigquery_ds.prefix).to eq('prefix_')
      expect(bigquery_ds.saved?).to eq false
      expect(connection_info.client_email).to eq('test@client.com')
      expect(connection_info.private_key).to eq('abc123')
      expect(connection_info.project).to eq('project_test')
      expect(connection_info.schema).to eq('schema_test')
    end

    it 'should update bigquery data source success' do
      bigquery_ds = @client.create(GoodData::DataSource, @model)
      connection_info = bigquery_ds.connection_info

      bigquery_ds.name = 'BigQueryDS_new'
      bigquery_ds.alias = 'BigQueryDS_new_alias'
      bigquery_ds.prefix = 'prefix_new_'
      connection_info.client_email = 'test_new@client.com'
      connection_info.private_key = 'abc_new'
      connection_info.project = 'project_new'
      connection_info.schema = 'schema_new'

      expect(bigquery_ds.name).to eq('BigQueryDS_new')
      expect(bigquery_ds.alias).to eq('BigQueryDS_new_alias')
      expect(bigquery_ds.prefix).to eq('prefix_new_')
      expect(bigquery_ds.saved?).to eq false
      expect(connection_info.client_email).to eq('test_new@client.com')
      expect(connection_info.private_key).to eq('abc_new')
      expect(connection_info.project).to eq('project_new')
      expect(connection_info.schema).to eq('schema_new')
    end

    it 'save should be failed with empty data source name' do
      bigquery_ds = @client.create(GoodData::DataSource, @model)
      bigquery_ds.name = ''
      expect { bigquery_ds.save }.to raise_error do |e|
        expect(e.message).to eq('Data source name has to be provided')
      end
    end

    it 'save should be failed with empty data source project' do
      bigquery_ds = @client.create(GoodData::DataSource, @model)
      connection_info = bigquery_ds.connection_info
      connection_info.project = ''
      expect { bigquery_ds.save }.to raise_error do |e|
        expect(e.message).to eq('Data source project has to be provided')
      end
    end

    it 'save should be failed with empty data source schema' do
      bigquery_ds = @client.create(GoodData::DataSource, @model)
      connection_info = bigquery_ds.connection_info
      connection_info.schema = ''
      expect { bigquery_ds.save }.to raise_error do |e|
        expect(e.message).to eq('Data source schema has to be provided')
      end
    end

    it 'save should be failed with empty data source client email' do
      bigquery_ds = @client.create(GoodData::DataSource, @model)
      connection_info = bigquery_ds.connection_info
      connection_info.client_email = ''
      expect { bigquery_ds.save }.to raise_error do |e|
        expect(e.message).to eq('Data source client email has to be provided')
      end
    end

    it 'create should success' do
      begin
        bigquery_ds = @client.create(GoodData::DataSource, @model)
        bigquery_ds.save

        connection_info = bigquery_ds.connection_info
        expect(bigquery_ds.name).to eq('BigQueryDS')
        expect(bigquery_ds.prefix).to eq('prefix_')
        expect(bigquery_ds.saved?).to eq true
        expect(connection_info.client_email).to eq('test@client.com')
        expect(connection_info.private_key).to eq('')
        expect(connection_info.project).to eq('project_test')
        expect(connection_info.schema).to eq('schema_test')
      ensure
        bigquery_ds.delete if bigquery_ds
      end
    end

    it 'update should success' do
      begin
        bigquery_ds = @client.create(GoodData::DataSource, @model)
        bigquery_ds.save
        bigquery_ds.name='BigQueryDS_New'
        updated_ds = bigquery_ds.save

        connection_info = updated_ds.connection_info
        expect(updated_ds.name).to eq('BigQueryDS_New')
        expect(updated_ds.prefix).to eq('prefix_')
        expect(updated_ds.saved?).to eq true
        expect(connection_info.client_email).to eq('test@client.com')
        expect(connection_info.private_key).to eq('')
        expect(connection_info.project).to eq('project_test')
        expect(connection_info.schema).to eq('schema_test')
      ensure
        bigquery_ds.delete if bigquery_ds
      end
    end

    it 'delete should success' do
      bigquery_ds = @client.create(GoodData::DataSource, @model)
      bigquery_ds.save
      bigquery_ds.delete

      expect { GoodData::DataSource.from_id(bigquery_ds.id) }.to raise_error do |e|
        expect(e.message.include? '404 Not Found').to eq true
      end
    end
  end

  describe '#generic_data_source' do
    before(:each) do
      @model = {
          'dataSource' => {
              'name' => 'GenericDS',
              'alias' => GoodData::Rest::Connection.generate_string,
              'connectionInfo' => {
                  'generic' => {
                      'params' => {
                          'param01' => 'value01',
                          'param02' => 'value02'
                      },
                      'secureParams' => {
                          'secureParam01' => 'secure_value01',
                          'secureParam02' => 'secure_value02'
                      }
                  }
              }
          }
      }
    end

    it 'should create generic data source success' do
      generic_ds = @client.create(GoodData::DataSource, @model)
      connection_info = generic_ds.connection_info
      params = connection_info.params
      secure_params = connection_info.secure_params

      expect(generic_ds.name).to eq('GenericDS')
      expect(generic_ds.alias).to eq(@model['dataSource']['alias'])
      expect(generic_ds.saved?).to eq false
      expect(params['param01']).to eq('value01')
      expect(params['param02']).to eq('value02')
      expect(secure_params['secureParam01']).to eq('secure_value01')
      expect(secure_params['secureParam02']).to eq('secure_value02')
    end

    it 'should update bigquery data source success' do
      generic_ds = @client.create(GoodData::DataSource, @model)
      connection_info = generic_ds.connection_info
      params = connection_info.params
      secure_params = connection_info.secure_params
      params['param03'] = 'value03'
      secure_params['secureParam03'] = 'secure_value03'
      generic_ds.name = 'GenericDS_new'
      generic_ds.alias = 'GenericDS_new_alias'
      connection_info.params = params
      connection_info.secure_params = secure_params

      new_params = connection_info.params
      new_secure_params = connection_info.secure_params

      expect(generic_ds.name).to eq('GenericDS_new')
      expect(generic_ds.alias).to eq('GenericDS_new_alias')
      expect(generic_ds.saved?).to eq false
      expect(new_params['param01']).to eq('value01')
      expect(new_params['param02']).to eq('value02')
      expect(new_params['param03']).to eq('value03')
      expect(new_secure_params['secureParam01']).to eq('secure_value01')
      expect(new_secure_params['secureParam02']).to eq('secure_value02')
      expect(new_secure_params['secureParam03']).to eq('secure_value03')
    end

    it 'save should be failed with empty data source name' do
      generic_ds = @client.create(GoodData::DataSource, @model)
      generic_ds.name = ''
      expect { generic_ds.save }.to raise_error do |e|
        expect(e.message).to eq('Data source name has to be provided')
      end
    end

    it 'create should success' do
      begin
        generic_ds = @client.create(GoodData::DataSource, @model)
        generic_ds.save

        connection_info = generic_ds.connection_info
        params = connection_info.params
        secure_params = connection_info.secure_params

        expect(generic_ds.name).to eq('GenericDS')
        expect(generic_ds.saved?).to eq true
        expect(params['param01']).to eq('value01')
        expect(params['param02']).to eq('value02')
        expect(secure_params['secureParam01']).to eq('')
        expect(secure_params['secureParam02']).to eq('')
      ensure
        generic_ds.delete if generic_ds
      end
    end

    it 'update should success' do
      begin
        generic_ds = @client.create(GoodData::DataSource, @model)
        generic_ds.save
        generic_ds.name='BigQueryDS_New'
        updated_ds = generic_ds.save

        connection_info = updated_ds.connection_info
        params = connection_info.params
        secure_params = connection_info.secure_params

        expect(updated_ds.name).to eq('BigQueryDS_New')
        expect(updated_ds.saved?).to eq true
        expect(params['param01']).to eq('value01')
        expect(params['param02']).to eq('value02')
        expect(secure_params['secureParam01']).to eq('')
        expect(secure_params['secureParam02']).to eq('')
      ensure
        generic_ds.delete if generic_ds
      end
    end

    it 'delete should success' do
      generic_ds = @client.create(GoodData::DataSource, @model)
      generic_ds.save
      generic_ds.delete

      expect { GoodData::DataSource.from_id(generic_ds.id) }.to raise_error do |e|
        expect(e.message.include? '404 Not Found').to eq true
      end
    end
  end

  describe '#s3_data_source' do
    before(:each) do
      @model = {
          'dataSource' => {
              'name' => 'S3DS',
              'alias' => GoodData::Rest::Connection.generate_string,
              'connectionInfo' => {
                  's3' => {
                      'bucket' => 's3://test',
                      'accessKey' => 'testkey',
                      'secretKey' => 'abc123',
                      'serverSideEncryption' => true
                  }
              }
          }
      }
    end

    it 'should create s3 data source success' do
      s3_ds = @client.create(GoodData::DataSource, @model)
      connection_info = s3_ds.connection_info

      expect(s3_ds.name).to eq('S3DS')
      expect(s3_ds.alias).to eq(@model['dataSource']['alias'])
      expect(s3_ds.saved?).to eq false
      expect(connection_info.bucket).to eq('s3://test')
      expect(connection_info.access_key).to eq('testkey')
      expect(connection_info.secret_key).to eq('abc123')
      expect(connection_info.server_side_encryption).to eq true
    end

    it 'should update s3 data source success' do
      s3_ds = @client.create(GoodData::DataSource, @model)
      connection_info = s3_ds.connection_info
      s3_ds.name = 'S3DS_new'
      s3_ds.alias = 'S3DS_new_alias'
      connection_info.access_key = 'new_accesskey'
      connection_info.secret_key = 'new_secretkey'
      new_connection_info = s3_ds.connection_info

      expect(s3_ds.name).to eq('S3DS_new')
      expect(s3_ds.alias).to eq('S3DS_new_alias')
      expect(s3_ds.saved?).to eq false
      expect(new_connection_info.bucket).to eq('s3://test')
      expect(new_connection_info.access_key).to eq('new_accesskey')
      expect(new_connection_info.secret_key).to eq('new_secretkey')
      expect(new_connection_info.server_side_encryption).to eq true
    end

    it 'save should be failed with empty data source name' do
      s3_ds = @client.create(GoodData::DataSource, @model)
      s3_ds.name = ''
      expect { s3_ds.save }.to raise_error do |e|
        expect(e.message).to eq('Data source name has to be provided')
      end
    end

    it 'save should be failed with empty s3 bucket' do
      s3_ds = @client.create(GoodData::DataSource, @model)
      connection_info = s3_ds.connection_info
      connection_info.bucket = ''
      expect { s3_ds.save }.to raise_error do |e|
        expect(e.message).to eq('S3 bucket has to be provided')
      end
    end

    it 'save should be failed with empty s3 access key' do
      s3_ds = @client.create(GoodData::DataSource, @model)
      connection_info = s3_ds.connection_info
      connection_info.access_key = ''
      expect { s3_ds.save }.to raise_error do |e|
        expect(e.message).to eq('S3 access key has to be provided')
      end
    end

    it 'create should success' do
      begin
        s3_ds = @client.create(GoodData::DataSource, @model)
        s3_ds.save

        connection_info = s3_ds.connection_info
        expect(s3_ds.name).to eq('S3DS')
        expect(s3_ds.saved?).to eq true
        expect(connection_info.bucket).to eq('s3://test')
        expect(connection_info.access_key).to eq('testkey')
        expect(connection_info.secret_key).to eq('')
        expect(connection_info.server_side_encryption).to eq true
      ensure
        s3_ds.delete if s3_ds
      end
    end

    it 'update should success' do
      begin
        s3_ds = @client.create(GoodData::DataSource, @model)
        s3_ds.save
        s3_ds.name='S3_New'
        updated_ds = s3_ds.save

        connection_info = updated_ds.connection_info
        expect(updated_ds.name).to eq('S3_New')
        expect(updated_ds.saved?).to eq true
        expect(connection_info.bucket).to eq('s3://test')
        expect(connection_info.access_key).to eq('testkey')
        expect(connection_info.secret_key).to eq('')
        expect(connection_info.server_side_encryption).to eq true
      ensure
        s3_ds.delete if s3_ds
      end
    end

    it 'delete should success' do
      s3_ds = @client.create(GoodData::DataSource, @model)
      s3_ds.save
      s3_ds.delete

      expect { GoodData::DataSource.from_id(s3_ds.id) }.to raise_error do |e|
        expect(e.message.include? '404 Not Found').to eq true
      end
    end
  end

  describe '#ads_data_source' do
    before(:each) do
      @model = {
          'dataSource' => {
              'name' => 'AdsDS',
              'alias' => GoodData::Rest::Connection.generate_string,
              'connectionInfo' => {
                  'ads' => {
                      'instance' => 'a007e53c139273463247c8f3cd76c6444a',
                      'exportable' => true
                  }
              }
          }
      }
    end

    it 'should create ADS data source success' do
      ads_ds = @client.create(GoodData::DataSource, @model)
      connection_info = ads_ds.connection_info

      expect(ads_ds.name).to eq('AdsDS')
      expect(ads_ds.alias).to eq(@model['dataSource']['alias'])
      expect(ads_ds.saved?).to eq false
      expect(connection_info.instance).to eq('a007e53c139273463247c8f3cd76c6444a')
      expect(connection_info.exportable).to eq true
    end

    it 'should update ADS data source success' do
      ads_ds = @client.create(GoodData::DataSource, @model)
      connection_info = ads_ds.connection_info
      ads_ds.name = 'AdsDS_new'
      ads_ds.alias = 'AdsDS_new_alias'
      connection_info.instance = 'oiwfsoudfyuds9823742834923479823489'
      new_connection_info = ads_ds.connection_info

      expect(ads_ds.name).to eq('AdsDS_new')
      expect(ads_ds.alias).to eq('AdsDS_new_alias')
      expect(ads_ds.saved?).to eq false
      expect(new_connection_info.instance).to eq('oiwfsoudfyuds9823742834923479823489')
      expect(new_connection_info.exportable).to eq true
    end

    it 'save should be failed with empty data source name' do
      ads_ds = @client.create(GoodData::DataSource, @model)
      ads_ds.name = ''
      expect { ads_ds.save }.to raise_error do |e|
        expect(e.message).to eq('Data source name has to be provided')
      end
    end

    it 'save should be failed with empty instance' do
      ads_ds = @client.create(GoodData::DataSource, @model)
      connection_info = ads_ds.connection_info
      connection_info.instance = ''
      expect { ads_ds.save }.to raise_error do |e|
        expect(e.message).to eq('Data source instance has to be provided')
      end
    end
  end
end
