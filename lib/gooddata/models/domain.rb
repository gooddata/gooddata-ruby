# encoding: UTF-8

require 'cgi'

require_relative 'profile'
require_relative '../extensions/enumerable'
require_relative '../rest/object'

module GoodData
  class Domain < GoodData::Rest::Object
    attr_reader :name

    class << self
      # Looks for domain
      #
      # @param domain_name [String] Domain name
      # @return [String] Domain object instance
      def [](domain_name, options = { :client => GoodData.connection })
        return domain_name if domain_name.is_a?(Domain)
        c = client(options)
        fail "Using pseudo-id 'all' is not supported by GoodData::Domain" if domain_name.to_s == 'all'
        c.create(GoodData::Domain, domain_name)
      end

      # Adds user to domain
      #
      # @param domain [String] Domain name
      # @param login [String] Login of user to be invited
      # @param password [String] Default preset password
      # @return [Object] Raw response
      def add_user(user_data, name = nil, opts = { :client => GoodData.connection })
        generated_pass = rand(10E10).to_s
        domain_name = name || user_data[:domain]
        user_data = user_data.to_hash
        data = {
          :login => user_data[:login] || user_data[:email],
          :firstName => user_data[:first_name] || 'FirstName',
          :lastName => user_data[:last_name] || 'LastName',
          :password => user_data[:password] || generated_pass,
          :verifyPassword => user_data[:password] || generated_pass,
          :email => user_data[:email] || user_data[:login]
        }

        # Optional authentication modes
        tmp = user_data[:authentication_modes]
        if tmp
          if tmp.is_a? Array
            data[:authenticationModes] = tmp
          elsif tmp.is_a? String
            data[:authenticationModes] = [tmp]
          end
        end

        # Optional company
        tmp = user_data[:company_name]
        tmp = user_data[:company] if tmp.nil? || tmp.empty?
        data[:companyName] = tmp if tmp && !tmp.empty?

        # Optional country
        tmp = user_data[:country]
        data[:country] = tmp if tmp && !tmp.empty?

        # Optional phone number
        tmp = user_data[:phone]
        tmp = user_data[:phone_number] if tmp.nil? || tmp.empty?
        data[:phoneNumber] = tmp if tmp && !tmp.empty?

        # Optional position
        tmp = user_data[:position]
        data[:position] = tmp if tmp && !tmp.empty?

        # Optional sso provider
        tmp = user_data[:sso_provider]
        data['ssoProvider'] = tmp if tmp && !tmp.empty?

        # Optional timezone
        tmp = user_data[:timezone]
        data[:timezone] = tmp if tmp && !tmp.empty?

        c = client(opts)

        # TODO: It will be nice if the API will return us user just newly created
        begin
          url = "/gdc/account/domains/#{domain_name}/users"
          response = c.post(url, :accountSetting => data)
        rescue RestClient::BadRequest
          raise GoodData::UserInDifferentDomainError, "User #{data[:login]} is already in different domain"
        end

        url = response['uri']
        raw = c.get url

        # TODO: Remove this hack when POST /gdc/account/domains/{domain-name}/users returns full profile
        raw['accountSetting']['links'] = {} unless raw['accountSetting']['links']
        raw['accountSetting']['links']['self'] = response['uri'] unless raw['accountSetting']['links']['self']
        c.create(GoodData::Profile, raw)
      end

      def update_user(user_data, options = { client: GoodData.connection })
        user_data = user_data.to_hash if user_data.is_a?(GoodData::Profile)
        client = client(options)
        user_data = user_data.to_hash
        # generated_pass = rand(10E10).to_s
        data = {
          :firstName => user_data[:first_name] || 'FirstName',
          :lastName => user_data[:last_name] || 'LastName',
          :email => user_data[:email]
        }

        # Optional authentication modes
        tmp = user_data[:authentication_modes]
        if tmp
          if tmp.is_a? Array
            data[:authenticationModes] = tmp
          elsif tmp.is_a? String
            data[:authenticationModes] = [tmp]
          end
        end

        # Optional company
        tmp = user_data[:company_name]
        tmp = user_data[:company] if tmp.nil? || tmp.empty?
        data[:companyName] = tmp if tmp && !tmp.empty?

        # Optional pass
        tmp = user_data[:password]
        tmp = user_data[:password] if tmp.nil? || tmp.empty?
        data[:password] = tmp if tmp && !tmp.empty?
        data[:verifyPassword] = tmp if tmp && !tmp.empty?

        # Optional country
        tmp = user_data[:country]
        data[:country] = tmp if tmp && !tmp.empty?

        # Optional phone number
        tmp = user_data[:phone]
        tmp = user_data[:phone_number] if tmp.nil? || tmp.empty?
        data[:phoneNumber] = tmp if tmp && !tmp.empty?

        # Optional position
        tmp = user_data[:position]
        data[:position] = tmp if tmp && !tmp.empty?

        # Optional sso provider
        tmp = user_data[:sso_provider]
        data['ssoProvider'] = tmp if tmp

        # Optional timezone
        tmp = user_data[:timezone]
        data[:timezone] = tmp if tmp && !tmp.empty?

        # TODO: It will be nice if the API will return us user just newly created
        url = user_data.delete(:uri)
        data.delete(:password) if client.user.uri == url
        response = client.put(url, :accountSetting => data)

        # TODO: Remove this hack when POST /gdc/account/domains/{domain-name}/users returns full profile
        response['accountSetting']['links'] = {} unless response['accountSetting']['links']
        response['accountSetting']['links']['self'] = url unless response['accountSetting']['links']['self']
        client.create(GoodData::Profile, response)
      end

      # Finds user in domain by login
      #
      # @param domain [String] Domain name
      # @param login [String] User login
      # @return [GoodData::Profile] User profile
      def find_user_by_login(domain, login, opts = { :client => GoodData.connection, :project => GoodData.project })
        c = client(opts)
        escaped_login = CGI.escape(login)
        domain = c.domain(domain)
        GoodData.logger.warn("Retrieving particular user \"#{login.inspect}\" from domain #{domain.name}")
        url = "#{domain.uri}/users?login=#{escaped_login}"
        tmp = c.get url
        items = tmp['accountSettings']['items'] if tmp['accountSettings']
        items && items.length > 0 ? c.factory.create(GoodData::Profile, items.first) : nil
      end

      # Returns list of users for domain specified
      # @param [String] domain Domain to list the users for
      # @param [Hash] opts Options.
      # @option opts [Number] :offset The subject
      # @option opts [Number] :limit From address
      # TODO: Review opts[:limit] functionality
      def users(domain, id = :all, opts = {})
        client = client(opts)
        domain = client.domain(domain)
        if id == :all
          GoodData.logger.warn("Retrieving all users from domain #{domain.name}")
          Enumerator.new do |y|
            page_limit = opts[:page_limit] || 1000
            offset = opts[:offset] || 0
            loop do
              tmp = client(opts).get("#{domain.uri}/users", params: { offset: offset, limit: page_limit })
              tmp['accountSettings']['items'].each do |user_data|
                user = client.create(GoodData::Profile, user_data)
                y << user
              end
              break if tmp['accountSettings']['items'].count < page_limit
              offset += page_limit
            end
          end
        else
          find_user_by_login(domain, id)
        end
      end

      # Create users specified in list
      # @param [Array<GoodData::Membership>] list List of users
      # @param [String] default_domain_name Default domain name used when no specified in user
      # @return [Array<GoodData::User>] List of users created
      def create_users(list, default_domain = nil, opts = { :client => GoodData.connection, :project => GoodData.project })
        default_domain_name = default_domain.respond_to?(:name) ? default_domain.name : default_domain
        domain = client.domain(default_domain_name)

        domain_users_cache = Hash[domain.users.map { |u| [u.login, u] }]
        list.pmapcat do |user|
          begin
            user_data = user.to_hash
            domain_user = domain_users_cache[user_data[:login]]
            if !domain_user
              added_user = domain.add_user(user_data, opts)
              [{ type: :user_added_to_domain, user: added_user }]
            else
              fields_to_check = opts[:fields_to_check] || user_data.keys
              diff = GoodData::Helpers.diff([domain_user.to_hash], [user_data], key: :login, fields: fields_to_check)
              next [] if diff[:changed].empty?
              updated_user = domain.update_user(domain_user.to_hash.merge(user_data.compact), opts)
              [{ type: :user_changed_in_domain, user: updated_user }]
            end
          rescue RuntimeError => e
            [{ type: :error, reason: e }]
          end
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
    # domain = project.domain('domain-name')
    # domain.add_user 'joe.doe@example', 'sup3rS3cr3tP4ssW0rtH'
    #
    def add_user(data, opts = {})
      # data[:domain] = name
      GoodData::Domain.add_user(data, name, { client: client }.merge(opts))
    end

    alias_method :create_user, :add_user

    def create_users(list, options = {})
      GoodData::Domain.create_users(list, name, { client: client }.merge(options))
    end

    # Gets user by its login or uri in various shapes
    # It does not find by other information because that is not unique. If you want to search by name or email please
    # use fuzzy_get_user.
    #
    # @param [String] name Name to look for
    # @param [Array<GoodData::User>]user_list Optional cached list of users used for look-ups
    # @return [GoodDta::Membership] User
    def get_user(name, user_list = users)
      return member(name, user_list) if name.instance_of?(GoodData::Membership)
      return member(name, user_list) if name.instance_of?(GoodData::Profile)
      name = name.is_a?(Hash) ? name[:login] || name[:uri] : name
      return nil unless name
      name.downcase!
      user_list.find do |user|
        user.uri && user.uri.downcase == name ||
          user.login && user.login.downcase == name
      end
    end

    # Finds user in domain by login
    #
    # @param login [String] User login
    # @return [GoodData::Profile] User account settings
    def find_user_by_login(login)
      GoodData::Domain.find_user_by_login(self, login, client: client)
    end

    # Gets membership for profile specified
    #
    # @param [GoodData::Profile] profile - Profile to be checked
    # @param [Array<GoodData::Profile>] list Optional list of members to check against
    # @return [GoodData::Profile] Profile if found
    def member(profile, list = members)
      if profile.is_a? String
        return list.find do |m|
          m.uri == profile || m.login == profile
        end
      end
      list.find { |m| m.login == profile.login }
    end

    # Checks if the profile is member of project
    #
    # @param [GoodData::Profile] profile - Profile to be checked
    # @param [Array<GoodData::Membership>] list Optional list of members to check against
    # @return [Boolean] true if is member else false
    def member?(profile, list = members)
      !member(profile, list).nil?
    end

    def members?(profiles, list = members)
      profiles.map { |p| member?(p, list) }
    end

    # Update user in domain
    #
    # @param opts [Hash] Data of the user to be updated
    # @return [Object] Raw response
    #
    def update_user(data, options = {})
      GoodData::Domain.update_user(data, { client: client }.merge(options))
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
    def users(id = :all, opts = {})
      GoodData::Domain.users(name, id, opts.merge(client: client))
    end

    alias_method :members, :users

    def uri
      "/gdc/account/domains/#{name}"
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
