# encoding: UTF-8

module GoodData
  class Profile
    private_class_method :new
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

    private

    def initialize
      @json = GoodData.get GoodData.connection.user['profile']
      @user = @json['accountSetting']['firstName'] + ' ' + @json['accountSetting']['lastName']
    end
  end
end
