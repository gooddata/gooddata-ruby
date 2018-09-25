# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'cgi'
require 'active_support/core_ext/hash/compact'

require_relative 'profile'
require_relative '../extensions/enumerable'
require_relative '../rest/object'

module GoodData
  class Domain < Rest::Resource
    attr_reader :name

    USER_LANGUAGES = {
      'en-US' => 'English',
      'nl-NL' => 'Dutch',
      'es-ES' => 'Spanish',
      'pt-BR' => 'Portuguese/Brazil',
      'pt-PT' => 'Portuguese/Portugal',
      'fr-FR' => 'French',
      'de-DE' => 'German',
      'ja-JP' => 'Japanese'
    }

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
          :email => user_data[:email] || user_data[:login],
          :language => ensure_user_language(user_data)
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

        # Optional ip whitelist
        tmp = user_data[:ip_whitelist]
        data[:ipWhitelist] = tmp if tmp

        c = client(opts)

        # TODO: It will be nice if the API will return us user just newly created
        begin
          url = "/gdc/account/domains/#{domain_name}/users"
          response = c.post(url, :accountSetting => data)
        rescue RestClient::BadRequest => e
          error = MultiJson.load(e.response)
          error_type = GoodData::Helpers.get_path(error, %w(error errorClass))
          case error_type
          when 'com.gooddata.webapp.service.userprovisioning.LoginNameAlreadyRegisteredException'
            u = Domain.find_user_by_login(domain_name, data[:login])
            if u
              response = { 'uri' => u.uri }
            else
              raise GoodData::UserInDifferentDomainError, "User #{data[:login]} is already in different domain"
            end
          when 'com.gooddata.json.validator.exception.MalformedMessageException'
            raise GoodData::MalformedUserError, "User #{data[:login]} is malformed. The message from API is #{GoodData::Helpers.interpolate_error_message(error)}"
          else
            raise GoodData::Helpers.interpolate_error_message(error)
          end
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
          :email => user_data[:email],
          :language => ensure_user_language(user_data)
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
        items && !items.empty? ? c.factory.create(GoodData::Profile, items.first) : nil
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
              begin
                tmp = client(opts).get("#{domain.uri}/users", params: { offset: offset, limit: page_limit })
              end

              tmp['accountSettings']['items'].each do |user_data|
                user = client.create(GoodData::Profile, user_data)
                y << user if user
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

        # Prepare cache for domain users
        domain_users_cache = Hash[domain.users.map { |u| [u.login.downcase, u] }]

        list.pmapcat do |user|
          begin
            user_data = user.to_hash.tap { |uh| uh[:login].downcase! }
            domain_user = domain_users_cache[user_data[:login]]
            user_login = user_data[:login]
            if !domain_user
              added_user = domain.add_user(user_data, opts)
              GoodData.logger.info("Added new user=#{user_login} to domain=#{default_domain_name}.")
              [{ type: :successful, :action => :user_added_to_domain, user: added_user }]
            else
              domain_user_data = domain_user.to_hash
              fields_to_check = opts[:fields_to_check] || user_data.keys
              diff = GoodData::Helpers.diff([domain_user.to_hash], [user_data], key: :login, fields: fields_to_check)
              next [] if diff[:changed].empty?
              updated_user = domain.update_user(domain_user.to_hash.merge(user_data.compact), opts)
              GoodData.logger.debug "Updated user=#{user_login} from old properties \
(email=#{domain_user_data[:email]}, sso_provider=#{domain_user_data[:sso_provider]}) \
to new properties (email=#{user_data[:email]}, sso_provider=#{user_data[:sso_provider]}) in domain=#{default_domain_name}."
              [{ type: :successful, :action => :user_changed_in_domain, user: updated_user }]
            end
          rescue RuntimeError => e
            if !domain_user
              GoodData.logger.error("Failed to add user=#{user_login} to domain=#{default_domain_name}. Error: #{e.message}")
            else
              GoodData.logger.error("Failed to update user=#{user_login} in domain=#{default_domain_name}. Error: #{e.message}")
            end
            [{ type: :failed, :user => user, message: e }]
          end
        end
      end

      private

      def ensure_user_language(user_data)
        language = user_data[:language] || 'en-US'
        unless USER_LANGUAGES.keys.include?(language)
          available_languages = USER_LANGUAGES.map { |k, v| "#{k} (#{v})" }.join(', ')
          GoodData.logger.warn "The language for user '#{user_data[:login]}' will be English because '#{language}' is an invalid value. \
Available values for setting language are: #{available_languages}."
          language = 'en-US'
        end
        language
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

    # Returns all the clients defined in all segments defined in domain. Alternatively
    # id of a client can be provided in which case it returns just that client
    # if it exists.
    #
    # @param id [String] Id of client that you are looking for
    # @param data_product [DataProduct] data product object in which the clients are located
    # @return [Object] Raw response
    #
    def clients(id = :all, data_product = nil)
      GoodData::Client[id, data_product: data_product, domain: self]
    end

    alias_method :create_user, :add_user

    def create_users(list, options = {})
      GoodData::Domain.create_users(list, name, { client: client }.merge(options))
    end

    def data_products(id = :all)
      GoodData::DataProduct[id, domain: self]
    end

    def create_data_product(data)
      data_product = GoodData::DataProduct.create(data, domain: self, client: client)
      data_product.save
    end

    def segments(id = :all, data_product = nil)
      GoodData::Segment[id, data_product: data_product, domain: self]
    end

    # Creates new segment in current domain from parameters passed
    #
    # @param data [Hash] Data for segment namely :segment_id and :master_project is accepted. Master_project can be given as either a PID or a Project instance
    # @return [GoodData::Segment] New Segment instance
    def create_segment(data)
      segment = GoodData::Segment.create(data, domain: self, client: client)
      segment.save
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

    # Returns uri for segments on the domain. This will be removed soon. It is here that for segments the "account" portion of the URI was removed. And not for the rest
    #
    # @return [String] Uri of the segments
    def segments_uri
      "/gdc/domains/#{name}"
    end

    # Calls Segment#synchronize_clients on all segments and concatenates the results
    #
    # @return [Array] Returns array of results
    def synchronize_clients
      segments.flat_map(&:synchronize_clients)
    end

    # Runs async process that walks through segments and provisions projects if necessary.
    #
    # @return [Enumerator] Returns Enumerator of results
    def provision_client_projects(segments = nil)
      segments = segments.is_a?(Array) ? segments : [segments]
      segments.each do |segment_id|
        segment = segments(segment_id)
        segment.provision_client_projects
      end
    end

    def update_clients_settings(data)
      data.each do |datum|
        client_id = datum[:id]
        settings = datum[:settings]
        settings.each do |setting|
          GoodData::Client.update_setting(setting[:name], setting[:value], domain: self, client_id: client_id, data_product_id: datum[:data_product_id])
        end
      end
      nil
    end
    alias_method :add_clients_settings, :update_clients_settings

    def update_clients(data, options = {})
      data.group_by(&:data_product_id).each do |data_product_id, client_update_data|
        data_product = data_products(data_product_id)
        data_product.update_clients(client_update_data, options)
      end
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

    # Returns uri for the domain.
    #
    # @return [String] Uri of the segments
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
