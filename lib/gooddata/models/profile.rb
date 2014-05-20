# encoding: UTF-8

require_relative '../rest/object'

module GoodData
  class Profile < GoodData::Rest::Object
    attr_reader :user, :json

    class << self
      def load
        # GoodData.logger.info "Loading user profile..."
        Profile.send 'new'
      end
    end

    def projects
      @json['accountSetting']['links']['projects']
    end

    alias_method :to_json, :json

    def [](key, options = {})
      @json['accountSetting'][key]
    end

    def initialize(opts = {})
      # @json = GoodData.get GoodData.connection.user['profile']
      @json = opts
      @user = @json['accountSetting']['firstName'] + ' ' + @json['accountSetting']['lastName']
    end

    def projects(opts = {})
      res = client.get @json['accountSetting']['links']['projects']
      pp res
    end

  end
end
