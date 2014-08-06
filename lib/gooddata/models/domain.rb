# encoding: UTF-8

require_relative 'profile'

require_relative '../rest/object'

module GoodData
  class Domain < GoodData::Rest::Object
    attr_reader :name

    USERS_OPTIONS = { :offset => 0, :limit => 1000 }

    class << self
      # Looks for domain
      #
      # @param domain_name [String] Domain name
      # @return [String] Domain object instance
      def [](domain_name, options = {})
        fail "Using pseudo-id 'all' is not supported by GoodData::Domain" if domain_name.to_s == 'all'
        GoodData::Domain.new(domain_name)
      end

      # Adds user to domain
      #
      # @param domain [String] Domain name
      # @param login [String] Login of user to be invited
      # @param password [String] Default preset password
      # @return [Object] Raw response
      def add_user(opts)
        generated_pass = rand(10E10).to_s
        data = {
          :login => opts[:login],
          :firstName => opts[:first_name] || 'FirstName',
          :lastName => opts[:last_name] || 'LastName',
          :password => opts[:password] || generated_pass,
          :verifyPassword => opts[:password] || generated_pass,
          :email => opts[:login]
        }

        # Optional authentication modes
        tmp = opts[:authentication_modes]
        if tmp
          if tmp.kind_of? Array
            data[:authenticationModes] = tmp
          elsif tmp.kind_of? String
            data[:authenticationModes] = [tmp]
          end
        end

        # Optional company
        tmp = opts[:company_name]
        tmp = opts[:company] if tmp.nil? || tmp.empty?
        data[:companyName] = tmp if tmp && !tmp.empty?

        # Optional country
        tmp = opts[:country]
        data[:country] = tmp if tmp && !tmp.empty?

        # Optional phone number
        tmp = opts[:phone]
        tmp = opts[:phone_number] if tmp.nil? || tmp.empty?
        data[:phoneNumber] = tmp if tmp && !tmp.empty?

        # Optional position
        tmp = opts[:position]
        data[:position] = tmp if tmp && !tmp.empty?

        # Optional sso provider
        tmp = opts[:sso_provider]
        data['ssoProvider'] = tmp if tmp && !tmp.empty?

        # Optional timezone
        tmp = opts[:timezone]
        data[:timezone] = tmp if tmp && !tmp.empty?

        # TODO: It will be nice if the API will return us user just newly created
        url = "/gdc/account/domains/#{opts[:domain]}/users"
        response = client(opts).post(url, :accountSetting => data)

        raw = client(opts).get response['uri']

        # TODO: Remove this hack when POST /gdc/account/domains/{domain-name}/users returns full profile
        raw['accountSetting']['links'] = {} unless raw['accountSetting']['links']
        raw['accountSetting']['links']['self'] = response['uri'] unless raw['accountSetting']['links']['self']

        client.create(GoodData::Profile, raw)
      end

      # Finds user in domain by login
      #
      # @param domain [String] Domain name
      # @param login [String] User login
      # @return [GoodData::Profile] User profile
      def find_user_by_login(domain, login, opts = {})
        url = "/gdc/account/domains/#{domain}/users?login=#{login}"
        tmp = client(opts).get url
        items = tmp['accountSettings']['items'] if tmp['accountSettings']
        items && items.length > 0 ? client.factory.create(GoodData::Profile, items.first) : nil
      end

      # Returns list of users for domain specified
      # @param [String] domain Domain to list the users for
      # @param [Hash] opts Options.
      # @option opts [Number] :offset The subject
      # @option opts [Number] :limit From address
      # TODO: Review opts[:limit] functionality
      def users(domain, opts = USERS_OPTIONS)
        result = []

        options = USERS_OPTIONS.merge(opts)
        offset = 0 || options[:offset]
        uri = "/gdc/account/domains/#{domain}/users?offset=#{offset}&limit=#{options[:limit]}"
        loop do
          break unless uri
          tmp = client(opts).get(uri)
          tmp['accountSettings']['items'].each do |account|
            result << client(opts).create(GoodData::Profile, account)
          end
          uri = tmp['accountSettings']['paging']['next']
        end

        result
      end

      # Create users specified in list
      # @param [Array<GoodData::Membership>] list List of users
      # @param [String] default_domain_name Default domain name used when no specified in user
      # @return [Array<GoodData::User>] List of users created
      def users_create(list, default_domain = nil)
        default_domain_name = default_domain.respond_to?(:name) ? default_domain.name : default_domain
        domains = {}
        list.map do |user|
          # TODO: Add user here
          domain_name = user.json['user']['content']['domain'] || default_domain_name

          # Lookup for domain in cache'
          domain = domains[domain_name]

          # Get domain info from REST, add to cache
          if domain.nil?
            domain = {
              :domain => GoodData::Domain[domain_name],
              :users => GoodData::Domain[domain_name].users
            }

            domain[:users_map] = Hash[domain[:users].map { |u| [u.email, u] }]
            domains[domain_name] = domain
          end

          # Check if user exists in domain
          domain_user = domain[:users_map][user.email]

          # Create domain user if needed
          unless domain_user
            password = user.json['user']['content']['password']

            # Fill necessary user data
            user_data = {
              :login => user.login,
              :firstName => user.first_name,
              :lastName => user.last_name,
              :password => password,
              :verifyPassword => password,
              :email => user.login
            }

            tmp = user.json['user']['content']['sso_provider']
            user_data[:sso_provider] = tmp if tmp && !tmp.empty?

            tmp = user.json['user']['content']['authentication_modes']
            user_data[:authentication_modes] = tmp && !tmp.empty?

            # Add created user to cache
            domain_user = domain[:domain].add_user(user_data)
            domain[:users] << domain_user
            domain[:users_map][user.email] = domain_user
          end
          domain_user
        end
      end
    end

    def initialize(domain_name)
      @name = domain_name
    end

    # Adds user to domain
    #
    # @param login [String] Login of user to be invited
    # @param password [String] Default preset password
    # @return [Object] Raw response
    #
    # Example
    #
    # GoodData.connect 'tomas.korcak@gooddata.com' 'your-password'
    # domain = GoodData::Domain['gooddata-tomas-korcak']
    # domain.add_user 'joe.doe@example', 'sup3rS3cr3tP4ssW0rtH'
    #
    def add_user(opts)
      opts[:domain] = name
      GoodData::Domain.add_user(opts)
    end

    # Finds user in domain by login
    #
    # @param login [String] User login
    # @return [GoodData::Profile] User account settings
    def find_user_by_login(login)
      GoodData::Domain.find_user_by_login(name, login)
    end

    # List users in domain
    #
    # @param [Hash] opts Additional user listing options.
    # @option opts [Number] :offset Offset to start listing from
    # @option opts [Number] :limit Limit of users to be listed
    # @return [Array<GoodData::Profile>] List of user account settings
    #
    # Example
    #
    # GoodData.connect 'tomas.korcak@gooddata.com' 'your-password'
    # domain = GoodData::Domain['gooddata-tomas-korcak']
    # pp domain.users
    #
    def users(opts = USERS_OPTIONS)
      GoodData::Domain.users(name, opts)
    end

    def users_create(list)
      GoodData::Domain.users_create(list, name)
    end

    private

    # Private setter of domain name. Used by constructor not available for external users.
    #
    # @param domain_name [String] Domain name to be set.
    def name=(domain_name) # rubocop:disable TrivialAccessors
      @name = domain_name
    end
  end
end
