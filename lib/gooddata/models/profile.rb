# encoding: UTF-8

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

    class << self
      # Apply changes to object.
      #
      # @param obj [GoodData::Profile] Object to be modified
      # @param changes [Hash] Hash with modifications
      # @return [GoodData::Profile] Modified object
      def apply(obj, changes)
        changes.each do |param, val|
          next unless ASSIGNABLE_MEMBERS.include? param
          obj.send("#{param}=", val)
        end
        obj
      end

      # Creates new instance from hash with attributes
      #
      # @param attributes [Hash] Hash with initial attributes
      # @return [GoodData::Profile] New profile instance
      def create(attributes)
        json = EMPTY_OBJECT.dup
        res = GoodData::Profile.new(json)

        attributes.each do |k, v|
          res.send("#{k}=", v) if ASSIGNABLE_MEMBERS.include? k
        end

        res.save!
        res
      end

      # Gets user currently logged in
      # @return [GoodData::Profile] User currently logged-in
      def current
        GoodData.connection.user
      end

      # Gets hash representing diff of profiles
      #
      # @param user1 [GoodData::Profile] Original user
      # @param user2 [GoodData::Profile] User to compare with
      # @return [Hash] Hash representing diff
      def diff(user1, user2)
        res = {}
        ASSIGNABLE_MEMBERS.each do |k|
          l_value = user1.send("#{k}")
          r_value = user2.send("#{k}")
          res[k] = r_value if l_value != r_value
        end
        res
      end

      def diff_list(list1, list2)
        tmp = Hash[list1.map { |v| [v.email, v] }]

        res = {
          :added => [],
          :removed => [],
          :changed => []
        }

        list2.each do |user_new|
          user_existing = tmp[user_new.email]
          if user_existing.nil?
            res[:added] << user_new
            next
          end

          if user_existing != user_new
            diff = self.diff(user_existing, user_new)
            res[:changed] << {
              :user => user_existing,
              :diff => diff
            }
          end
        end

        tmp = Hash[list2.map { |v| [v.email, v] }]
        list1.each do |user_existing|
          user_new = tmp[user_existing.email]
          if user_new.nil?
            res[:removed] << user_existing
            next
          end
        end

        res
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
      res = true
      ASSIGNABLE_MEMBERS.each do |k|
        l_val = send("#{k}")
        r_val = other.send("#{k}")
        res = false if l_val != r_val
      end
      res
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
    def apply(changes)
      GoodData::Profile.apply(self, changes)
    end

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
      GoodData.delete uri
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
      @json['accountSetting']['phone'] || ''
    end

    # Set the phone
    #
    # @param val [String] Phone to be set
    def phone=(val)
      @dirty ||= phone != val
      @json['accountSetting']['phone'] = val
    end

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
      res = []

      # TODO: Strip this out after transition
      client = GoodData.client

      projects = client.get @json['accountSetting']['links']['projects']
      projects['projects'].each do |project|
        res << client.create(GoodData::Project, project)
      end

      res
    end

    # Saves object if dirty, clears dirty flag
    def save!
      if @dirty
        raw = @json.dup
        raw['accountSetting'].delete('login')

        if uri && !uri.empty?
          url = "/gdc/account/profile/#{obj_id}"
          @json = GoodData.put url, raw
          @dirty = false
        end
      end
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
      @json['accountSetting']['links']['self']
    end

    private

    def initialize(json)
      @json = json
      @user = @json['accountSetting']['firstName'] + ' ' + @json['accountSetting']['lastName']
    end
  end
end
