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
        fail "Cannot search for nil #{self.class}" unless id
        uri = if id.is_a?(Integer) || id =~ /^\d+$/
                "#{GoodData.project.md[MD_OBJ_CTG]}/#{id}"
              elsif id !~ /\//
                identifier_to_uri id
              elsif id =~ /^\//
                id
              else
                fail 'Unexpected object id format: expected numeric ID, identifier with no slashes or an URI starting with a slash'
              end
        new(GoodData.get uri) unless uri.nil?
      end

      def all(options = {})
        self[:all, options]
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

      # TODO: Add test
      def identifier_to_uri(*ids)
        fail(NoProjectError, 'Connect to a project before searching for an object') unless GoodData.project
        uri = GoodData.project.md[IDENTIFIERS_CFG]
        response = GoodData.post uri, 'identifierToUri' => ids
        if response['identifiers'].empty?
          nil
        else
          ids = response['identifiers'].map { |x| x['uri'] }
          ids.count == 1 ? ids.first : ids
        end
      end

      alias_method :id_to_uri, :identifier_to_uri

      alias_method :get_by_id, :[]
    end

    metadata_property_reader :uri, :identifier, :title, :summary, :tags, :deprecated, :category
    metadata_property_writer :tags, :summary, :title

    def root_key
      raw_data.keys.first
    end

    def initialize(data)
      @json = data.to_hash
    end

    def delete
      if saved?
        GoodData.delete(uri)
        meta.delete('uri')
        # ["uri"] = nil
      end
    end

    def reload!
      @json = GoodData.get(uri) if saved?
      self
    end

    alias_method :refresh, :reload!

    def obj_id
      uri.split('/').last
    end

    def links
      data['links']
    end

    def browser_uri
      GoodData.connection.url + meta['uri']
    end

    def updated
      Time.parse(meta['updated'])
    end

    def created
      Time.parse(meta['created'])
    end

    def deprecated=(flag)
      if flag == '1' || flag == 1
        meta['deprecated'] = '1'
      elsif flag == '0' || flag == 0
        meta['deprecated'] = '0'
      else
        fail 'You have to provide flag as either 1 or "1" or 0 or "0"'
      end
    end

    def data
      raw_data[root_key]
    end

    def meta
      data && data['meta']
    end

    def content
      data && data['content']
    end

    def project
      @project ||= Project[uri.gsub(/\/obj\/\d+$/, '')]
    end

    def usedby(key = nil)
      dependency("#{GoodData.project.md['usedby2']}/#{obj_id}", key)
    end

    alias_method :used_by, :usedby

    def using(key = nil)
      dependency("#{GoodData.project.md['using2']}/#{obj_id}", key)
    end

    def usedby?(obj)
      dependency?(:usedby, obj)
    end

    alias_method :used_by?, :usedby?

    def using?(obj)
      dependency?(:using, obj)
    end

    def to_json
      @json.to_json
    end

    def saved?
      !uri.nil?
    end

    def save
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
        result = GoodData.post(GoodData.project.md['obj'], to_json)
        saved_object = self.class[result['uri']]
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

    def ==(other)
      other.uri == uri && other.respond_to?(:to_hash) && other.to_hash == to_hash
    end

    def validate
      true
    end

    def exportable?
      false
    end

    # TODO: generate fill for other subtypes
    def fact?
      false
    end

    def attribute?
      false
    end

    def metric?
      false
    end

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
