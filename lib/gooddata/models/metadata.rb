# encoding: UTF-8

require_relative '../core/connection'
require_relative '../core/project'

module GoodData
  class MdObject
    MD_OBJ_CTG = 'obj'
    IDENTIFIERS_CFG = 'instance-identifiers'

    attr_reader :json

    alias_method :raw_data, :json
    alias_method :to_hash, :json
    alias_method :data, :json

    class << self
      def root_key(a_key)
        define_method :root_key, proc { a_key.to_s }
      end

      def metadata_property_reader(*props)
        props.each do |prop|
          define_method prop, proc { meta[prop.to_s] }
        end
      end

      def metadata_property_writer(*props)
        props.each do |prop|
          define_method "#{prop}=", proc { |val| meta[prop.to_s] = val }
        end
      end

      # Returns either list of objects or a specific object. This method is reimplemented in subclasses to leverage specific implementation for specific type of objects. Options is used in subclasses specifically to provide shorthand for getting a full objects after getting a list of hashes from query resource
      # @param [Object] id id can be either a number a String (as a URI). Subclasses should also be abel to deal with getting the instance of MdObject already and a :all symbol
      # @param [Hash] options the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [MdObject] if id is a String or number single object is returned
      # @return [Array] if :all was provided as an id, list of objects should be returned. Note that this is implemented only in the subclasses. MdObject does not support this since API has no means to return list of all types of objects
      def [](id, options = {})
        project = options[:project] || GoodData.project
        klass = options[:class] || self

        fail "You have to provide an \"id\" to be searched for." unless id
        fail(NoProjectError, 'Connect to a project before searching for an object') unless project
        return klass.all(options) if id == :all
        return id if id.is_a?(MdObject)
        uri = if id.is_a?(Integer) || id =~ /^\d+$/
                "#{project.md[MD_OBJ_CTG]}/#{id}"
              elsif id !~ /\//
                identifier_to_uri id
              elsif id =~ /^\//
                id
              else
                fail 'Unexpected object id format: expected numeric ID, identifier with no slashes or an URI starting with a slash'
              end
        klass.new(GoodData.get uri) unless uri.nil?
      end

      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = {})
        fail NotImplementedError, 'Method should be implemented in subclass. Currently there is no way hoe to get all metadata objects on API.'
      end

      def find_by_tag(tag)
        self[:all].select { |r| r['tags'].split(',').include?(tag) }
      end

      def find_first_by_title(title)
        all = self[:all]
        item = if title.is_a?(Regexp)
                 all.find { |r| r['title'] =~ title }
               else
                 all.find { |r| r['title'] == title }
               end
        self[item['link']] unless item.nil?
      end

      # Finds a specific type of the object by title. Returns all matches. Returns full object.
      #
      # @param title [String] title that has to match exactly
      # @param title [Regexp] regular expression that has to match
      # @return [Array<GoodData::MdObject>] Array of MdObject
      def find_by_title(title)
        all = self[:all]
        items = if title.is_a?(Regexp)
                  all.select { |r| r['title'] =~ title }
                else
                  all.select { |r| r['title'] == title }
                end
        items.map { |item| self[item['link']] unless item.nil? }
      end

      # TODO: Add test
      def identifier_to_uri(*ids)
        fail(NoProjectError, 'Connect to a project before searching for an object') unless GoodData.project
        uri = GoodData.project.md[IDENTIFIERS_CFG]
        response = GoodData.post uri, 'identifierToUri' => ids
        if response['identifiers'].empty?
          nil
        else
          identifiers = response['identifiers']
          ids_lookup = identifiers.reduce({}) do |a, e|
            a[e['identifier']] = e['uri']
            a
          end
          uris = ids.map { |x| ids_lookup[x] }
          uris.count == 1 ? uris.first : uris
        end
      end

      alias_method :id_to_uri, :identifier_to_uri

      alias_method :get_by_id, :[]

      private

      # Method intended to be called by individual classes in their all
      # implementations. It abstracts the way interacting with query resources.
      # It either returns the array of hashes from query. If asked it also
      # goes and brings the full objects. Due to performance reasons
      # :full => false is the default. This will most likely change
      #
      # @param query_obj_type [String] string used in URI to distinguish different query resources for different objects
      # @param klass [Class] A class used for instantiating the returned data
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def query(query_obj_type, klass, options = {})
        project = options[:project] || GoodData.project
        fail(NoProjectError, 'Connect to a project before searching for an object') unless project
        query_result = GoodData.get(project.md['query'] + "/#{query_obj_type}/")['query']['entries']
        options[:full] ? query_result.map { |item| klass[item['link'], :project => project] } : query_result
      end
    end

    metadata_property_reader :uri, :identifier, :title, :summary, :tags, :deprecated, :category
    metadata_property_writer :tags, :summary, :title, :identifier

    # Gets autor of this object
    #
    # @return [GoodData::Profile] Author
    def author
      url = json[root_key]['meta']['author']
      raw = GoodData.get url
      GoodData::Profile.new(raw)
    end

    # Gets contributor of this object
    #
    # @return [GoodData::Profile] Contributor
    def contributor
      url = json[root_key]['meta']['contributor']
      raw = GoodData.get url
      GoodData::Profile.new(raw)
    end

    # Gets name of root element wrapping all the json, ie. 'report', 'user', etc
    def root_key
      raw_data.keys.first
    end

    # Initializes metadata from raw JSON
    def initialize(data)
      @json = data.to_hash
    end

    # Deletes the MD resource
    def delete
      if saved?
        GoodData.delete(uri)
        meta.delete('uri')
        # ["uri"] = nil
      end
    end

    # Forces fetch of resource from remote endpoint
    def reload!
      @json = GoodData.get(uri) if saved?
      self
    end

    alias_method :refresh, :reload!

    # Gets ID of MD object
    def obj_id
      uri.split('/').last
    end

    # Returns links related to this MD object
    def links
      data['links']
    end

    # Returns URI openable in browser
    def browser_uri
      GoodData.connection.url + meta['uri']
    end

    # Returns timestamp of last update as Time object
    def updated
      Time.parse(meta['updated'])
    end

    # Returns timestamp of creating as Time object
    def created
      Time.parse(meta['created'])
    end

    # Sets the deprecated flag
    def deprecated=(flag)
      if flag == '1' || flag == 1
        meta['deprecated'] = '1'
      elsif flag == '0' || flag == 0
        meta['deprecated'] = '0'
      else
        fail 'You have to provide flag as either 1 or "1" or 0 or "0"'
      end
    end

    # Gets raw data wrapped in root_key
    def data
      raw_data[root_key]
    end

    # Gets metadata section
    def meta
      data && data['meta']
    end

    # Gets content section
    def content
      data && data['content']
    end

    # Gets project from URI
    def project
      @project ||= Project[uri.gsub(%r{\/obj\/\d+$}, '')]
    end

    # Returns which objects uses this MD resource
    def usedby(key = nil)
      dependency("#{GoodData.project.md['usedby2']}/#{obj_id}", key)
    end

    alias_method :used_by, :usedby

    # Returns which objects this MD resource uses
    def using(key = nil)
      dependency("#{GoodData.project.md['using2']}/#{obj_id}", key)
    end

    def usedby?(obj)
      dependency?(:usedby, obj)
    end

    alias_method :used_by?, :usedby?

    # Checks if obj is using this MD resource
    def using?(obj)
      dependency?(:using, obj)
    end

    # Converts this object
    def to_json
      @json.to_json
    end

    # Checks if is this MD object saved
    def saved?
      res = uri.nil?
      !res
    end

    # Saves this MD object
    def save(project = GoodData.project)
      fail('Validation failed') unless validate

      if saved?
        GoodData.put(uri, to_json)
      else
        explicit_identifier = meta['identifier']
        # Pre-check to provide a user-friendly error rather than
        # failing later
        if explicit_identifier && MdObject[explicit_identifier]
          fail "Identifier '#{explicit_identifier}' already in use"
        end
        result = GoodData.post(project.md['obj'], to_json)
        saved_object = self.class[result['uri'], :project => project]
        # TODO: add test for explicitly provided identifier
        @json = saved_object.raw_data
        if explicit_identifier
          # Object creation API discards the identifier. If an identifier
          # was explicitely provided in the origina object, we need to set
          # it explicitly with an extra PUT call.
          meta['identifier'] = explicit_identifier
          begin
            GoodData.put(uri, to_json)
          rescue => e
            # Cannot change the identifier (perhaps because it's in use
            # already?), cleaning up.
            GoodData.delete(uri)
            raise e
          end
        end
      end
      self
    end

    # Saves an object with a different name
    #
    # @param new_title [String] New title. If not provided one is provided
    # @return [GoodData::MdObject] MdObject that has been saved as
    def save_as(new_title = "Clone of #{title}")
      dupped = Marshal.load(Marshal.dump(raw_data))
      dupped[root_key]['meta'].delete('uri')
      dupped[root_key]['meta'].delete('identifier')
      dupped[root_key]['meta']['title'] = new_title
      x = self.class.new(dupped)
      x.save
    end

    # Compares if two MD objects are same
    def ==(other)
      other.respond_to?(:uri) && other.uri == uri && other.respond_to?(:to_hash) && other.to_hash == to_hash
    end

    # Validates MD object
    def validate
      true
    end

    # Checks if is the project exportable
    def exportable?
      false
    end

    # Returns true if the object is a fact false otherwise
    # @return [Boolean]
    def fact?
      false
    end

    # Returns true if the object is an attribute false otherwise
    # @return [Boolean]
    def attribute?
      false
    end

    # Returns true if the object is a metric false otherwise
    # @return [Boolean]
    def metric?
      false
    end

    # Returns true if the object is a label false otherwise
    # @return [Boolean]
    def label?
      false
    end
    alias_method :display_form?, :label?

    private

    def dependency(uri, key = nil)
      result = GoodData.get("#{uri}/#{obj_id}")['entries']
      if key.nil?
        result
      elsif key.respond_to?(:category)
        result.select { |item| item['category'] == key.category }
      else
        result.select { |item| item['category'] == key }
      end
    end

    # Checks for dependency
    def dependency?(type, uri)
      objs = case type
             when :usedby
               usedby
             when :using
               using
             end
      uri = uri.respond_to?(:uri) ? uri.uri : uri
      objs.any? { |obj| obj['link'] == uri }
    end
  end
end
