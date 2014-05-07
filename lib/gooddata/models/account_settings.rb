# encoding: UTF-8

require_relative 'project'

module GoodData
  # Account settings representation with some added sugar
  class AccountSettings
    attr_reader :json

    # Creates new instance
    #
    # @return [AccountSettings] New AccountSettings instance
    def initialize(json)
      @json = json
    end

    # Gets the company name
    #
    # @return [String] Company name
    def company
      @json['accountSetting']['companyName'] || ''
    end

    # Gets the country
    #
    # @return [String] Country
    def country
      @json['accountSetting']['country'] || ''
    end

    # Gets date when created
    #
    # @return [DateTime] Created date
    def created
      DateTime.parse(@json['accountSetting']['created'])
    end

    # Gets the email
    #
    # @return [String] Email address
    def email
      @json['accountSetting']['email'] || ''
    end

    # Gets the first name
    #
    # @return [String] First name
    def first_name
      @json['accountSetting']['firstName'] || ''
    end

    # Gets the last name
    #
    # @return [String] Last name
    def last_name
      @json['accountSetting']['lastName'] || ''
    end

    # Gets the login
    #
    # @return [String] Login
    def login
      @json['accountSetting']['login'] || ''
    end

    # Gets the resource identifier
    #
    # @return [String] Resource identifier
    def obj_id
      uri.split('/').last
    end

    alias_method :account_setting_id, :obj_id

    # Gets the phone
    #
    # @return [String] Phone
    def phone
      @json['accountSetting']['phone'] || ''
    end

    # Gets the position in company
    #
    # @return [String] Position in company
    def position
      @json['accountSetting']['position'] || ''
    end

    # Gets the array of projects
    #
    # @return [Array<GoodData::Project>] Array of project where account settings belongs to
    def projects
      res = []

      projects = GoodData.get @json['accountSetting']['links']['projects']
      projects['projects'].each do |project|
        res << GoodData::Project.new(project)
      end

      res
    end

    # Gets the preferred timezone
    #
    # @return [String] Preferred timezone
    def timezone
      @json['accountSetting']['timezone'] || ''
    end

    # Gets the date when updated
    #
    # @return [DateTime] Updated date
    def updated
      DateTime.parse(@json['accountSetting']['updated'])
    end

    # Gets the resource REST URI
    #
    # @return [String] Resource URI
    def uri
      DateTime.parse(@json['accountSetting']['links']['self'])
    end
  end
end
