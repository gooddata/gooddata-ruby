# encoding: UTF-8

module GoodData
  class AccountSettings
    attr_reader :json

    def initialize(json)
      @json = json
    end

    def company
      @json['accountSetting']['companyName'] || ''
    end

    def country
      @json['accountSetting']['country'] || ''
    end

    def created
      DateTime.parse(@json['accountSetting']['created'])
    end

    def email
      @json['accountSetting']['email'] || ''
    end

    def first_name
      @json['accountSetting']['firstName'] || ''
    end

    def last_name
      @json['accountSetting']['lastName'] || ''
    end

    def login
      @json['accountSetting']['login'] || ''
    end

    def obj_id
      uri.split('/').last
    end

    alias_method :account_setting_id, :obj_id

    def phone
      @json['accountSetting']['phone'] || ''
    end

    def position
      @json['accountSetting']['position'] || ''
    end

    def timezone
      @json['accountSetting']['timezone'] || ''
    end

    def updated
      DateTime.parse(@json['accountSetting']['updated'])
    end

    def uri
      DateTime.parse(@json['accountSetting']['links']['self'])
    end
  end
end
