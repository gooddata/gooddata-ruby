# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../rest/resource'
require_relative '../extensions/hash'

module GoodData
  class ExecutionDetail < Rest::Resource
    attr_reader :dirty, :json

    alias_method :data, :json
    alias_method :raw_data, :json
    alias_method :to_hash, :json

    # Initializes object instance from raw wire JSON
    #
    # @param json Json used for initialization
    def initialize(json)
      super
      @json = json
    end

    # Timestamp when execution was created
    def created
      Time.parse(json['executionDetail']['created'])
    end

    # Has execution failed?
    def error?
      status == :error
    end

    # Timestamp when execution was finished
    def finished
      Time.parse(json['executionDetail']['finished'])
    end

    # Log for execution
    def log
      @client.get(json['executionDetail']['links']['log'])
    end

    # Filename of log
    def log_filename
      @client.get(json['executionDetail']['logFileName'])
    end

    # Is execution ok?
    def ok?
      status == :ok
    end

    # Timestamp when execution was started
    def started
      Time.parse(json['executionDetail']['started'])
    end

    # Status of execution
    def status
      json['executionDetail']['status'].downcase.to_sym
    end

    # Timestamp when execution was updated
    def updated
      Time.parse(json['executionDetail']['updated'])
    end

    # Returns URL
    #
    # @return [String] Schedule URL
    def uri
      @json['executionDetail']['links']['self'] if @json && @json['executionDetail'] && @json['executionDetail']['links']
    end

    # Compares two executions - based on their URI
    def ==(other)
      other.respond_to?(:uri) && other.uri == uri && other.respond_to?(:to_hash) && other.to_hash == to_hash
    end
  end
end
