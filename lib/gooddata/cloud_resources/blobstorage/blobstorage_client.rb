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
      connect
      filename = "#{SecureRandom.urlsafe_base64(6)}_#{Time.now.to_i}.csv"
      blob_name = @path ? "#{file}" : "#{@path.delete_suffix('/')}/#{file}"

      measure = Benchmark.measure do
        _blob, content = @client.get_blob(@container, blob_name)
        File.open(filename, "wb") { |f| f.write(content) }
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
  end
end
