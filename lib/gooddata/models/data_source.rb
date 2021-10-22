# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../rest/resource'

module GoodData
  class DataSource < Rest::Resource
    attr_accessor :connection_info

    DATA_SOURCES_URL = '/gdc/dataload/dataSources'
    SNOWFLAKE = 'snowflake'
    REDSHIFT = 'redshift'
    BIGQUERY = 'bigQuery'
    GENERIC = 'generic'
    S3 = 's3'
    ADS = 'ads'
    ERROR_MESSAGE_NO_SCHEMA = 'Data source schema has to be provided'

    class << self
      # Get all data sources or get a specify data source from data source identify
      # Expected parameter value:
      # - :all return all data sources
      # - :data_source_id return a data source with the specify data source identify
      def [](id = :all, options = { client: GoodData.client })
        c = GoodData.get_client(options)

        if id == :all
          data = c.get(DATA_SOURCES_URL)
          data['dataSources']['items'].map do |ds_data|
            c.create(DataSource, ds_data)
          end
        else
          c.create(DataSource, c.get(DATA_SOURCES_URL + '/' + id))
        end
      end

      # Get a specify data source from data source identify
      #
      # @param [String] id Data source identify
      # @return [DataSource] Data source corresponding in backend or throw exception if the data source identify doesn't exist
      def from_id(id, options = { client: GoodData.client })
        DataSource[id, options]
      end

      # Get a specify data source from data source alias
      #
      # @param [String] data_source_alias Data source alias
      # @return [DataSource] Data source corresponding in backend or throw exception if the data source alias doesn't exist
      def from_alias(data_source_alias, options = { client: GoodData.client })
        data_sources = all(options)
        result = data_sources.find do |data_source|
          data_source.alias == data_source_alias
        end
        fail "Data source alias '#{data_source_alias}' has not found" unless result

        result
      end

      # Get all data sources
      def all(options = { client: GoodData.client })
        DataSource[:all, options]
      end

      # Create data source from json
      # Expected keys:
      # - :name (mandatory)
      # - :alias (optional)
      # - :prefix (optional)
      # - :connectionInfo (mandatory)
      # - :client (mandatory)
      def create(opts)
        ds_name = opts[:name]
        ds_alias = opts[:alias]
        ds_prefix = opts[:prefix]
        ds_connection_info = opts[:connectionInfo]

        GoodData.logger.info "Creating data source '#{ds_name}'"
        fail ArgumentError, 'Data source name has to be provided' if ds_name.nil? || ds_name.blank?
        fail ArgumentError, 'Data source connection info has to be provided' if ds_connection_info.nil?

        json = {
          'dataSource' => {
            'name' => ds_name,
            'connectionInfo' => ds_connection_info
          }
        }
        json['dataSource']['alias'] = ds_alias if ds_alias
        json['dataSource']['prefix'] = ds_prefix if ds_prefix

        # Create data source
        c = GoodData.get_client(opts)
        res = c.post(DATA_SOURCES_URL, json)

        # create the public facing object
        c.create(DataSource, res)
      end
    end

    # Save data source to backend. The saving will validate existing data source name and connection info. So need set
    # values for them.
    #
    # Input info:
    # - :name (mandatory)
    # - :alias (optional)
    # - :prefix (optional)
    # - :connectionInfo (mandatory)
    #
    # Return: create data source in backend and return data source object corresponding with data source in backend.
    def save
      validate
      validate_connection_info
      if saved?
        update_obj_json = client.put(uri, to_update_payload)
        @json = update_obj_json
      else
        res = client.post(DATA_SOURCES_URL, to_update_payload)
        fail 'Unable to create new Data Source' if res.nil?

        @json = res
      end
      @connection_info = build_connection_info
      self
    end

    def delete
      saved? ? client.delete(uri) : nil
    end

    def initialize(json)
      super
      @json = json
      validate
      @connection_info = build_connection_info
    end

    def saved?
      !uri.blank?
    end

    def name
      @json['dataSource']['name']
    end

    def name=(new_name)
      @json['dataSource']['name'] = new_name
    end

    def alias
      @json['dataSource']['alias']
    end

    def alias=(new_alias)
      @json['dataSource']['alias'] = new_alias
    end

    def prefix
      @json['dataSource']['prefix']
    end

    def prefix=(new_prefix)
      @json['dataSource']['prefix'] = new_prefix
    end

    def uri
      @json['dataSource']['links']['self'] if @json && @json['dataSource'] && @json['dataSource']['links']
    end

    def id
      uri.split('/')[-1]
    end

    def is(type)
      @json['dataSource']['connectionInfo'][type]
    end

    def type
      @json['dataSource']['connectionInfo'].first[0].upcase
    end

    private

    def build_connection_info
      return snowflake_connection_info if is(SNOWFLAKE)
      return redshift_connection_info if is(REDSHIFT)
      return bigquery_connection_info if is(BIGQUERY)
      return generic_connection_info if is(GENERIC)
      return s3_connection_info if is(S3)
      return ads_connection_info if is(ADS)

      # In case don't know data source type then support get or set directly json data for connection info
      ConnectionInfo.new(@json['dataSource']['connectionInfo'])
    end

    def support_connection_info(connection_info)
      [SnowflakeConnectionInfo, RedshiftConnectionInfo, BigQueryConnectionInfo,
       GenericConnectionInfo, S3ConnectionInfo, AdsConnectionInfo].include? connection_info.class
    end

    def snowflake_connection_info
      return nil unless is(SNOWFLAKE)

      SnowflakeConnectionInfo.new(@json['dataSource']['connectionInfo'])
    end

    def redshift_connection_info
      return nil unless is(REDSHIFT)

      RedshiftConnectionInfo.new(@json['dataSource']['connectionInfo'])
    end

    def bigquery_connection_info
      return nil unless is(BIGQUERY)

      BigQueryConnectionInfo.new(@json['dataSource']['connectionInfo'])
    end

    def generic_connection_info
      return nil unless is(GENERIC)

      GenericConnectionInfo.new(@json['dataSource']['connectionInfo'])
    end

    def s3_connection_info
      return nil unless is(S3)

      S3ConnectionInfo.new(@json['dataSource']['connectionInfo'])
    end

    def ads_connection_info
      return nil unless is(ADS)

      AdsConnectionInfo.new(@json['dataSource']['connectionInfo'])
    end

    def to_update_payload
      json_data = {
        'dataSource' => {
          'name' => name,
          'connectionInfo' => @connection_info.to_update_payload
        }
      }
      json_data['dataSource']['alias'] = self.alias if self.alias
      json_data['dataSource']['prefix'] = prefix if prefix
      json_data
    end

    def validate
      fail 'Invalid data source json data' unless @json['dataSource']
      fail 'Data source connection info has to be provided' unless @json['dataSource']['connectionInfo']
      fail 'Data source name has to be provided' if name.nil? || name.blank?
    end

    def validate_connection_info
      @connection_info.validate
    end

    class ConnectionInfo < Rest::Resource
      def initialize(connection_info_json)
        @json = connection_info_json
      end

      def connection_info
        @json
      end

      def connection_info=(connection_info_json)
        @json = connection_info_json
      end

      def to_update_payload
        @json
      end

      # Abstract function
      def validate
      end
    end

    class SnowflakeConnectionInfo < ConnectionInfo
      def initialize(connection_info_json)
        @json = connection_info_json[GoodData::DataSource::SNOWFLAKE]
      end

      def url
        @json['url']
      end

      def url=(new_url)
        @json['url'] = new_url
      end

      def user_name
        @json['authentication']['basic']['userName'] if @json && @json['authentication'] && @json['authentication']['basic']
      end

      def user_name=(new_user_name)
        @json['authentication']['basic']['userName'] = new_user_name
      end

      def password
        @json['authentication']['basic']['password'] if @json && @json['authentication'] && @json['authentication']['basic']
      end

      def password=(new_password)
        @json['authentication']['basic']['password'] = new_password
      end

      def database
        @json['database']
      end

      def database=(new_database)
        @json['database'] = new_database
      end

      def schema
        @json['schema']
      end

      def schema=(new_schema)
        @json['schema'] = new_schema
      end

      def warehouse
        @json['warehouse']
      end

      def warehouse=(new_warehouse)
        @json['warehouse'] = new_warehouse
      end

      def to_update_payload
        {
          'snowflake' => {
            'url' => url,
            'authentication' => {
              'basic' => {
                'userName' => user_name,
                'password' => password
              }
            },
            'database' => database,
            'schema' => schema,
            'warehouse' => warehouse
          }
        }
      end

      def validate
        fail 'Data source url has to be provided' if url.nil? || url.blank?
        fail 'Data source database has to be provided' if database.nil? || database.blank?
        fail ERROR_MESSAGE_NO_SCHEMA if schema.nil? || schema.blank?
        fail 'Data source warehouse has to be provided' if warehouse.nil? || warehouse.blank?
        fail 'Data source username has to be provided' if user_name.nil? || user_name.blank?
      end
    end

    class RedshiftConnectionInfo < ConnectionInfo
      def initialize(connection_info_json)
        @json = connection_info_json[GoodData::DataSource::REDSHIFT]
      end

      def url
        @json['url']
      end

      def url=(new_url)
        @json['url'] = new_url
      end

      def user_name
        @json['authentication']['basic']['userName'] if basic_authentication
      end

      def user_name=(new_user_name)
        @json['authentication']['basic']['userName'] = new_user_name
      end

      def password
        @json['authentication']['basic']['password'] if basic_authentication
      end

      def password=(new_password)
        @json['authentication']['basic']['password'] = new_password
      end

      def db_user
        @json['authentication']['iam']['dbUser'] if iam_authentication
      end

      def db_user=(new_db_user)
        @json['authentication']['iam']['dbUser'] = new_db_user
      end

      def access_key_id
        @json['authentication']['iam']['accessKeyId'] if iam_authentication
      end

      def access_key_id=(new_access_key_id)
        @json['authentication']['iam']['accessKeyId'] = new_access_key_id
      end

      def secret_access_key
        @json['authentication']['iam']['secretAccessKey'] if iam_authentication
      end

      def secret_access_key=(new_secret_access_key)
        @json['authentication']['iam']['secretAccessKey'] = new_secret_access_key
      end

      def basic_authentication
        @json && @json['authentication'] && @json['authentication']['basic']
      end

      def iam_authentication
        @json && @json['authentication'] && @json['authentication']['iam']
      end

      def database
        @json['database']
      end

      def database=(new_database)
        @json['database'] = new_database
      end

      def schema
        @json['schema']
      end

      def schema=(new_schema)
        @json['schema'] = new_schema
      end

      def to_update_payload
        if basic_authentication
          {
            'redshift' => {
              'url' => url,
              'authentication' => {
                'basic' => {
                  'userName' => user_name,
                  'password' => password
                }
              },
              'database' => database,
              'schema' => schema
            }
          }
        else
          {
            'redshift' => {
              'url' => url,
              'authentication' => {
                'iam' => {
                  'dbUser' => db_user,
                  'accessKeyId' => access_key_id,
                  'secretAccessKey' => secret_access_key
                }
              },
              'database' => database,
              'schema' => schema
            }
          }
        end
      end

      def validate
        fail 'Data source url has to be provided' if url.nil? || url.blank?
        fail 'Data source database has to be provided' if database.nil? || database.blank?
        fail ERROR_MESSAGE_NO_SCHEMA if schema.nil? || schema.blank?

        if basic_authentication
          fail 'Data source username has to be provided' if user_name.nil? || user_name.blank?
        elsif iam_authentication
          fail 'Data source db_user has to be provided' if db_user.nil? || db_user.blank?
          fail 'Data source access key has to be provided' if access_key_id.nil? || access_key_id.blank?
        end
      end
    end

    class BigQueryConnectionInfo < ConnectionInfo
      def initialize(connection_info_json)
        @json = connection_info_json[GoodData::DataSource::BIGQUERY]
      end

      def client_email
        @json['authentication']['serviceAccount']['clientEmail'] if @json && @json['authentication'] && @json['authentication']['serviceAccount']
      end

      def client_email=(new_client_email)
        @json['authentication']['serviceAccount']['clientEmail'] = new_client_email
      end

      def private_key
        @json['authentication']['serviceAccount']['privateKey'] if @json && @json['authentication'] && @json['authentication']['serviceAccount']
      end

      def private_key=(new_private_key)
        @json['authentication']['serviceAccount']['privateKey'] = new_private_key
      end

      def project
        @json['project']
      end

      def project=(new_project)
        @json['project'] = new_project
      end

      def schema
        @json['schema']
      end

      def schema=(new_schema)
        @json['schema'] = new_schema
      end

      def to_update_payload
        {
          'bigQuery' => {
            'authentication' => {
              'serviceAccount' => {
                'clientEmail' => client_email,
                'privateKey' => private_key
              }
            },
            'project' => project,
            'schema' => schema
          }
        }
      end

      def validate
        fail 'Data source client email has to be provided' if client_email.nil? || client_email.blank?
        fail 'Data source project has to be provided' if project.nil? || project.blank?
        fail ERROR_MESSAGE_NO_SCHEMA if schema.nil? || schema.blank?
      end
    end

    class GenericConnectionInfo < ConnectionInfo
      def initialize(connection_info_json)
        @json = connection_info_json[GoodData::DataSource::GENERIC]
      end

      def params
        @json['params']
      end

      def params=(new_params)
        @json['params'] = new_params
      end

      def secure_params
        @json['secureParams']
      end

      def secure_params=(new_secure_params)
        @json['secureParams'] = new_secure_params
      end

      def to_update_payload
        {
          'generic' => {
            'params' => params,
            'secureParams' => secure_params
          }
        }
      end

      def validate
      end
    end

    class S3ConnectionInfo < ConnectionInfo
      def initialize(connection_info_json)
        @json = connection_info_json[GoodData::DataSource::S3]
      end

      def bucket
        @json['bucket']
      end

      def bucket=(new_bucket)
        @json['bucket'] = new_bucket
      end

      def access_key
        @json['accessKey']
      end

      def access_key=(new_access_key)
        @json['accessKey'] = new_access_key
      end

      def secret_key
        @json['secretKey']
      end

      def secret_key=(new_secret_key)
        @json['secretKey'] = new_secret_key
      end

      def server_side_encryption
        @json['serverSideEncryption']
      end

      def server_side_encryption=(new_server_side_encryption)
        @json['serverSideEncryption'] = new_server_side_encryption
      end

      def to_update_payload
        {
          's3' => {
            'bucket' => bucket,
            'accessKey' => access_key,
            'secretKey' => secret_key,
            'serverSideEncryption' => server_side_encryption
          }
        }
      end

      def validate
        fail 'S3 bucket has to be provided' if bucket.nil? || bucket.blank?
        fail 'S3 access key has to be provided' if access_key.nil? || access_key.blank?
      end
    end

    class AdsConnectionInfo < ConnectionInfo
      def initialize(connection_info_json)
        @json = connection_info_json[GoodData::DataSource::ADS]
      end

      def instance
        @json['instance']
      end

      def instance=(new_instance)
        @json['instance'] = new_instance
      end

      def exportable
        @json['exportable']
      end

      def exportable=(new_exportable)
        @json['exportable'] = new_exportable
      end

      def to_update_payload
        {
          'ads' => {
            'instance' => instance,
            'exportable' => exportable
          }
        }
      end

      def validate
        fail 'Data source instance has to be provided' if instance.nil? || instance.blank?
      end
    end
  end
end
