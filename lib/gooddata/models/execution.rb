# encoding: UTF-8

require_relative '../rest/resource'
require_relative '../extensions/hash'

module GoodData
  class Execution < Rest::Resource
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
      Time.parse(json['execution']['createdTime'])
    end

    # Data for execution
    def data
      @client.get(json['execution']['data'])
    end

    # Has execution failed?
    def error?
      status == :error
    end

    # Timestamp when execution was finished
    def finished
      Time.parse(json['execution']['endTime'])
    end

    # Log for execution
    def log
      @client.get(json['execution']['log'])
    end

    # Is execution ok?
    def ok?
      status == :ok
    end

    # Timestamp when execution was started
    def started
      Time.parse(json['execution']['startTime'])
    end

    # Status of execution
    def status
      json['execution']['status'].downcase.to_sym
    end

    # Returns URL
    #
    # @return [String] Schedule URL
    def uri
      @json['execution']['links']['self'] if @json && @json['execution'] && @json['execution']['links']
    end

    # Compares two executions - based on their URI
    def ==(other)
      other.respond_to?(:uri) && other.uri == uri && other.respond_to?(:to_hash) && other.to_hash == to_hash
    end
  end
end
