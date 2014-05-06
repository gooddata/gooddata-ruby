# encoding: UTF-8

require_relative 'account_settings'

module GoodData
  class Domain
    attr_reader :name

    USERS_OPTIONS = { :offset => 0, :limit => 1000 }

    class << self
      def add_user(domain, login, password)
        data = {
          :accountSetting => {
            :login => login,
            :firstName => 'FirstName',
            :lastName => 'LastName',
            :password => password,
            :verifyPassword => password,
            :email => login
          }
        }

        url = "/gdc/account/domains/#{domain}/users"
        GoodData.post(url, data)
      end

      # Returns list of users for domain specified
      # @param [String] domain Domain to list the users for
      # @param [Hash] opts Options.
      # @option opts [Number] :offset The subject
      # @option opts [Number] :limit From address
      def users(domain, opts = USERS_OPTIONS)
        result = []

        options = USERS_OPTIONS.merge(opts)

        tmp = GoodData.get("/gdc/account/domains/#{domain}/users?offset=#{options[:offset]}&limit=#{options[:limit]}")
        tmp['accountSettings']['items'].each do |account|
          result << GoodData::AccountSettings.new(account)
        end

        result
      end

      def [](domain_name)
        fail "Using pseudo-id 'all' is not supported by GoodData::Domain" if domain_name.to_s == 'all'
        GoodData::Domain.new(domain_name)
      end
    end

    def initialize(domain_name)
      @name = domain_name
    end

    # Add user to login
    #
    # Example
    #
    # GoodData.connect 'tomas.korcak@gooddata.com' 'your-password'
    # domain = GoodData::Domain['gooddata-tomas-korcak']
    # domain.add_user 'joe.doe@example', 'sup3rS3cr3tP4ssW0rtH'
    #
    def add_user(login, password)
      GoodData::Domain.add_user(name, login, password)
    end

    # List users in domain
    #
    # Example
    #
    # GoodData.connect 'tomas.korcak@gooddata.com' 'your-password'
    # domain = GoodData::Domain['gooddata-tomas-korcak']
    # pp domain.list_users
    #
    def users(opts = USERS_OPTIONS)
      GoodData::Domain.users(name, opts)
    end

    private

    # Private setter of domain name
    def name=(domain_name) # rubocop:disable TrivialAccessors
      @name = domain_name
    end
  end
end
