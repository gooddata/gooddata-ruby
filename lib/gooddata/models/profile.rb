# encoding: UTF-8

module GoodData
  class Profile
    private_class_method :new
    attr_reader :user

    class << self
      def load
        # GoodData.logger.info "Loading user profile..."
        Profile.send 'new'
      end
    end

    def projects
      @json['accountSetting']['links']['projects']
    end

    def to_json
      @json
    end

    def [](key)
      @json['accountSetting'][key]
    end

    private

    def initialize
      @json = GoodData.get GoodData.connection.user['profile']
      @user = @json['accountSetting']['firstName'] + ' ' + @json['accountSetting']['lastName']
    end
  end
end