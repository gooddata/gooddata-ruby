# encoding: UTF-8

module GoodData
  class Domain
    attr_reader :name

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

      def list_users(domain)
        result = []

        tmp = GoodData.get("/gdc/account/domains/#{domain}/users")
        tmp['accountSettings']['items'].each do |account|
          result << account['accountSetting']
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
    def list_users
      GoodData::Domain.list_users(name)
    end

    private

    # Private setter of domain name
    def name=(domain_name) # rubocop:disable TrivialAccessors
      @name = domain_name
    end
  end
end
