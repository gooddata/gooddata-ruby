# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'securerandom'
require 'pathname'
require "azure/storage/blob"

module GoodData
  class BlobStorageClient
    SAS_URL_PATTERN = %r{(^https?:\/\/[^\/]*)\/.*\?(.*)}
    INVALID_BLOB_GENERAL_MESSAGE = "The connection string is not valid."
    INVALID_BLOB_SIG_WELL_FORMED_MESSAGE = "The signature format is not valid."
    INVALID_BLOB_CONTAINER_MESSAGE = "ContainerNotFound"
    INVALID_BLOB_CONTAINER_FORMED_MESSAGE = "The container with the specified name is not found."
    INVALID_BLOB_EXPIRED_ORIGINAL_MESSAGE = "Signature not valid in the specified time frame"
    INVALID_BLOB_EXPIRED_MESSAGE = "The signature expired."
    INVALID_BLOB_INVALID_CONNECTION_STRING_MESSAGE = "The connection string is not valid."
    INVALID_BLOB_PATH_MESSAGE = "BlobNotFound"
    INVALID_BLOB_INVALID_PATH_MESSAGE = "The path to the data is not found."

    attr_reader :use_sas

    def initialize(options = {})
      raise("Data Source needs a client to Blob Storage to be able to get blob file but 'blobStorage_client' is empty.") unless options['blobStorage_client']

      if options['blobStorage_client']['connectionString'] && options['blobStorage_client']['container']
        @connection_string = options['blobStorage_client']['connectionString']
        @container = options['blobStorage_client']['container']
        @path = options['blobStorage_client']['path']
        @use_sas = false
        build_sas(@connection_string)
      else
        raise('Missing connection info for Blob Storage client')
      end
    end

    def realize_blob(file, _params)
      GoodData.gd_logger.info("Realizing download from Blob Storage. Container #{@container}.")
      filename = ''
      begin
        connect
        filename = "#{SecureRandom.urlsafe_base64(6)}_#{Time.now.to_i}.csv"
        blob_name = @path ? "#{@path.delete_suffix('/')}/#{file}" : "#{file}"

        measure = Benchmark.measure do
          _blob, content = @client.get_blob(@container, blob_name)
          File.open(filename, "wb") { |f| f.write(content) }
        end
      rescue  => e
        raise_error(e)
      end
      GoodData.gd_logger.info("Done downloading file type=blobStorage status=finished duration=#{measure.real}")
      filename
    end

    def connect
      GoodData.logger.info "Setting up connection to Blob Storage"
      if use_sas
        @client = Azure::Storage::Blob::BlobService.create(:storage_blob_host => @host, :storage_sas_token => @sas_token)
      else
        @client = Azure::Storage::Blob::BlobService.create_from_connection_string(@connection_string)
      end
    end

    def build_sas(url)
      matches = url.scan(SAS_URL_PATTERN)
      return unless matches && matches[0]

      @use_sas = true
      @host = matches[0][0]
      @sas_token = matches[0][1]
    end

    def raise_error(e)
      if e.message && e.message.include?(INVALID_BLOB_EXPIRED_ORIGINAL_MESSAGE)
        raise INVALID_BLOB_EXPIRED_MESSAGE
      elsif e.message && e.message.include?(INVALID_BLOB_SIG_WELL_FORMED_MESSAGE)
        raise INVALID_BLOB_SIG_WELL_FORMED_MESSAGE
      elsif e.message && e.message.include?(INVALID_BLOB_CONTAINER_MESSAGE)
        raise INVALID_BLOB_CONTAINER_FORMED_MESSAGE
      elsif e.message && e.message.include?(INVALID_BLOB_PATH_MESSAGE)
        raise INVALID_BLOB_INVALID_PATH_MESSAGE
      else
        raise INVALID_BLOB_GENERAL_MESSAGE
      end
    end
  end
end
