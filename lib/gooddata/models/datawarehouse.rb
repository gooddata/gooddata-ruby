# encoding: UTF-8
require_relative '../rest/resource'

module GoodData
  class DataWarehouse < GoodData::Rest::Resource
    class << self
      CREATE_URL = '/gdc/datawarehouse/instances'

      # Create a data warehouse from given attributes
      # Expected keys:
      # - :title (mandatory)
      # - :auth_token (mandatory)
      # - :summary
      def create(opts)
        GoodData.logger.info "Creating warehouse #{opts[:title]}"

        c = client(opts)
        fail ArgumentError, 'No :client specified' if c.nil?

        opts = { :auth_token => Helpers::AuthHelper.read_token }.merge(opts)
        auth_token = opts[:auth_token] || opts[:token]
        fail ArgumentError, 'You have to provide your token for creating projects as :auth_token parameter' if auth_token.nil? || auth_token.empty?

        title = opts[:title]
        fail ArgumentError, 'You have to provide a title for creating warehouse as :title parameter' if title.nil? || title.empty?

        json = {
          'instance' => {
            'title' => title,
            'description' => opts[:description] || opts[:summary] || 'No summary',
            'authorizationToken' => auth_token
          }
        }
        # do the first post
        res = c.post(CREATE_URL, json)

        # wait until the instance is created
        final_res = c.poll_on_response(res['asyncTask']['links']['poll'], opts.merge(sleep_interval: 3)) do |r|
          r['asyncTask']['links']['instance'].nil?
        end

        # get the json of the created instance
        final_json = c.get(final_res['asyncTask']['links']['instance'])

        # create the public facing object
        c.create(DataWarehouse, final_json)
      end
    end
    attr_accessor :json

    alias_method :to_json, :json
    alias_method :raw_data, :json

    def initialize(json)
      super
      @json = json
    end

    def title
      json['instance']['title']
    end

    def summary
      json['instance']['description']
    end

    def status
      json['instance']['status']
    end

    def uri
      json['instance']['links']['self']
    end

    def id
      uri.split('/')[-1]
    end

    def delete
      if state == 'DELETED'
        fail "Warehouse '#{title}' with id #{uri} is already deleted"
      end
      client.delete(uri)
    end

    # alias methods to prevent confusion and support the same keys
    # project has.
    alias_method :state, :status
    alias_method :description, :summary
  end
end
