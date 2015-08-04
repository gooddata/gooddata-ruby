# encoding: UTF-8

require 'pmap'

require_relative '../rest/object'

require_relative 'project'

module GoodData
  class Profile < GoodData::Rest::Object
    attr_reader :user, :json

    EMPTY_OBJECT = {
      'accountSetting' => {
        'companyName' => nil,
        'country' => nil,
        'created' => nil,
        'firstName' => nil,
        'lastName' => nil,
        'login' => nil,
        'phoneNumber' => nil,
        'position' => nil,
        'timezone' => nil,
        'updated' => nil,
        'links' => {
          'projects' => nil,
          'self' => nil
        },
        'email' => nil,
        'authenticationModes' => []
      }
    }

    ASSIGNABLE_MEMBERS = [
      :company,
      :country,
      :email,
      :login,
      :first_name,
      :last_name,
      :phone,
      :position,
      :timezone
    ]

    PROFILE_PATH = '/gdc/account/profile/%s'

    class << self
      # Get profile by ID or URI
      #
      # @param id ID or URI of user to be found
      # @param [Hash] opts Additional optional options
      # @option opts [GoodData::Rest::Client] :client Client used for communication with server
      # @return GoodData::Profile User Profile
      def [](id, opts = { client: GoodData.connection })
        return id if id.instance_of?(GoodData::Profile) || id.respond_to?(:profile?) && id.profile?

        if id.to_s !~ %r{^(\/gdc\/account\/profile\/)?[a-zA-Z\d]+$}
          fail(ArgumentError, 'wrong type of argument. Should be either project ID or path')
        end

        id = id.match(/[a-zA-Z\d]+$/)[0] if id =~ %r{/}

        c = client(opts)
        fail ArgumentError, 'No :client specified' if c.nil?

        response = c.get(PROFILE_PATH % id)
        c.factory.create(Profile, response)
      end

      # Creates new instance from hash with attributes
      #
      # @param attributes [Hash] Hash with initial attributes
      # @return [GoodData::Profile] New profile instance
      def create(attributes)
        res = create_object(attributes)
        res.save!
        res
      end

      def create_object(attributes)
        json = GoodData::Helpers.deep_dup(EMPTY_OBJECT)
        json['accountSetting']['links']['self'] = attributes[:uri] if attributes[:uri]
        res = client.create(GoodData::Profile, json)

        attributes.each do |k, v|
          res.send("#{k}=", v) if ASSIGNABLE_MEMBERS.include? k
        end
        res
      end

      def diff(item_1, item_2)
        x = diff_list([item_1], [item_2])
        return {} if x[:changed].empty?
        x[:changed].first[:diff]
      end

      def diff_list(list_1, list_2)
        GoodData::Helpers.diff(list_1, list_2, key: :login)
      end

      # Gets user currently logged in
      # @return [GoodData::Profile] User currently logged-in
      def current
        client.user
      end
    end

    # Creates new instance
    #
    # @return [Profile] New Profile instance
    def initialize(json)
      @json = json
      @dirty = false
    end

    # Checks objects for equality
    #
    # @param right [GoodData::Profile] Project to compare with
    # @return [Boolean] True if same else false
    def ==(other)
      return false unless other.respond_to?(:to_hash)
      to_hash == other.to_hash
    end

    # Checks objects for non-equality
    #
    # @param right [GoodData::Profile] Project to compare with
    # @return [Boolean] True if different else false
    def !=(other)
      !(self == other)
    end

    # Apply changes to object.
    #
    # @param changes [Hash] Hash with modifications
    # @return [GoodData::Profile] Modified object
    # def apply(changes)
    #   GoodData::Profile.apply(self, changes)
    # end

    # Gets the company name
    #
    # @return [String] Company name
    def company
      @json['accountSetting']['companyName'] || ''
    end

    # Set the company name
    #
    # @param val [String] Company name to be set
    def company=(val)
      @dirty ||= company != val
      @json['accountSetting']['companyName'] = val
    end

    # Gets the country
    #
    # @return [String] Country
    def country
      @json['accountSetting']['country'] || ''
    end

    # Set the country
    #
    # @param val [String] Country to be set
    def country=(val)
      @dirty ||= country != val
      @json['accountSetting']['country'] = val
    end

    # Gets date when created
    #
    # @return [DateTime] Created date
    def created
      DateTime.parse(@json['accountSetting']['created'])
    end

    # Deletes this account settings
    def delete
      client.delete uri
    end

    # Gets hash representing diff of profiles
    #
    # @param user [GoodData::Profile] Another profile to compare with
    # @return [Hash] Hash representing diff
    def diff(user)
      GoodData::Profile.diff(self, user)
    end

    # Gets the email
    #
    # @return [String] Email address
    def email
      @json['accountSetting']['email'] || ''
    end

    # Set the email
    #
    # @param val [String] Email to be set
    def email=(val)
      @dirty ||= email != val
      @json['accountSetting']['email'] = val
    end

    # Gets the first name
    #
    # @return [String] First name
    def first_name
      @json['accountSetting']['firstName'] || ''
    end

    # Set the first name
    #
    # @param val [String] First name to be set
    def first_name=(val)
      @dirty ||= first_name != val
      @json['accountSetting']['firstName'] = val
    end

    # Get full name
    #
    # @return String Full Name
    def full_name
      "#{first_name} #{last_name}"
    end

    alias_method :title, :full_name

    # Gets the last name
    #
    # @return [String] Last name
    def last_name
      @json['accountSetting']['lastName'] || ''
    end

    # Set the last name
    #
    # @param val [String] Last name to be set
    def last_name=(val)
      @dirty ||= last_name != val
      @json['accountSetting']['lastName'] = val
    end

    # Gets the login
    #
    # @return [String] Login
    def login
      @json['accountSetting']['login'] || ''
    end

    # Set the login
    #
    # @param val [String] Login to be set
    def login=(val)
      @dirty ||= login != val
      @json['accountSetting']['login'] = val
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
      @json['accountSetting']['phoneNumber'] || ''
    end

    alias_method :phone_number, :phone

    # Set the phone
    #
    # @param val [String] Phone to be set
    def phone=(val)
      @dirty ||= phone != val
      @json['accountSetting']['phoneNumber'] = val
    end

    alias_method :phone_number=, :phone=

    # Gets the position in company
    #
    # @return [String] Position in company
    def position
      @json['accountSetting']['position'] || ''
    end

    # Set the position
    #
    # @param val [String] Position to be set
    def position=(val)
      @dirty ||= position != val
      @json['accountSetting']['position'] = val
    end

    # Gets the array of projects
    #
    # @return [Array<GoodData::Project>] Array of project where account settings belongs to
    def projects
      projects = client.get @json['accountSetting']['links']['projects']
      projects['projects'].map do |project|
        client.create(GoodData::Project, project)
      end
    end

    # Saves object if dirty, clears dirty flag
    def save!
      if @dirty
        raw = @json.dup
        raw['accountSetting'].delete('login')

        if uri && !uri.empty?
          url = "/gdc/account/profile/#{obj_id}"
          @json = client.put url, raw
          @dirty = false
        end
      end
      self
    end

    # Gets the preferred timezone
    #
    # @return [String] Preferred timezone
    def timezone
      @json['accountSetting']['timezone'] || ''
    end

    # Set the timezone
    #
    # @param val [String] Timezone to be set
    def timezone=(val)
      @dirty ||= timezone != val
      @json['accountSetting']['timezone'] = val
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
      GoodData::Helpers.get_path(@json, %w(accountSetting links self))
    end

    def data
      data = @json || {}
      data['accountSetting'] || {}
    end

    def links
      data['links'] || {}
    end

    def content
      keys = (data.keys - ['links'])
      data.slice(*keys)
    end

    def name
      (first_name || '') + (last_name || '')
    end

    def sso_provider
      @json['accountSetting']['ssoProvider']
    end

    def sso_provider=(an_sso_provider)
      @dirty = true
      @json['accountSetting']['ssoProvider'] = an_sso_provider
    end

    def authentication_modes
      @json['accountSetting']['authenticationModes'].map { |x| x.downcase.to_sym }
    end

    def authentication_modes=(modes)
      modes = Array(modes)
      @dirty = true
      @json['accountSetting']['authenticationModes'] = modes.map { |x| x.to_s.upcase }
    end

    def to_hash
      tmp = GoodData::Helpers.symbolize_keys(content.merge(uri: uri))
      [
        [:companyName, :company],
        [:phoneNumber, :phone],
        [:firstName, :first_name],
        [:lastName, :last_name],
        [:authenticationModes, :authentication_modes],
        [:ssoProvider, :sso_provider]
      ].each do |vals|
        wire, rb = vals
        tmp[rb] = tmp[wire]
        tmp.delete(wire)
      end
      tmp
    end
  end
end
