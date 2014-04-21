# encoding: UTF-8

require_relative '../core/connection'
require_relative '../core/project'

module GoodData
  class MdObject
    MD_OBJ_CTG = 'obj'
    IDENTIFIERS_CFG = 'instance-identifiers'

    class << self
      def root_key(a_key)
        define_method :root_key, Proc.new { a_key.to_s }
      end

      def [](id)
        raise "Cannot search for nil #{self.class}" unless id
        uri = if id.is_a? Integer or id =~ /^\d+$/
                "#{GoodData.project.md[MD_OBJ_CTG]}/#{id}"
              elsif id !~ /\//
                identifier_to_uri id
              elsif id =~ /^\//
                id
              else
                raise 'Unexpected object id format: expected numeric ID, identifier with no slashes or an URI starting with a slash'
              end
        self.new(GoodData.get uri) unless uri.nil?
      end

      def find_by_tag(tag)
        self[:all].find_all { |r| r['tags'].split(',').include?(tag) }
      end

      def get_by_id(id)
        uri = GoodData::MdObject.id_to_uri(id)
        self[uri] unless uri.nil?
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

      def identifier_to_uri(*ids)
        raise NoProjectError.new 'Connect to a project before searching for an object' unless GoodData.project
        uri = GoodData.project.md[IDENTIFIERS_CFG]
        response = GoodData.post uri, {'identifierToUri' => ids}
        if response['identifiers'].empty?
          nil
        else
          ids = response['identifiers'].map { |x| x['uri'] }
          ids.count == 1 ? ids.first : ids
        end
      end

      alias :id_to_uri :identifier_to_uri
    end

    def initialize(json)
      @json = json
    end

    def delete
      if saved?
        GoodData.delete(uri)
        meta.delete('uri')
        # ["uri"] = nil
      end
    end

    def reload!
      if saved?
        @json = GoodData.get(uri)
      end
      self
    end

    alias :refresh :reload!

    def obj_id
      uri.split('/').last
    end

    def links
      data['links']
    end

    def uri
      meta && meta['uri']
    end

    def browser_uri
      GoodData.connection.url + meta['uri']
    end

    def identifier
      meta['identifier']
    end

    def title
      meta['title']
    end

    def summary
      meta['summary']
    end

    def title=(a_title)
      data['meta']['title'] = a_title
    end

    def summary=(a_summary)
      data['meta']['summary'] = a_summary
    end

    def tags
      data['meta']['tags']
    end

    def tags=(list_of_tags)
      data['meta']['tags'] = list_of_tags
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

    def get_usedby
      result = GoodData.get "#{GoodData.project.md['usedby2']}/#{obj_id}"
      result['entries']
    end

    def get_using
      result = GoodData.get "#{GoodData.project.md['using2']}/#{obj_id}"
      result['entries']
    end

    def to_json
      @json.to_json
    end

    def raw_data
      @json
    end

    def data
      key = methods.include?(:root_key) ? root_key : raw_data.keys.first
      raw_data[key]
    end

    def saved?
      !!uri
    end

    def save
      fail('Validation failed') unless validate

      if saved?
        GoodData.put(uri, to_json)
      else
        explicit_identifier = meta['identifier']
        # Pre-check to provide a user-friendly error rather than
        # failing later
        if explicit_identifier && MdObject[explicit_identifier] then
          raise "Identifier '#{explicit_identifier}' already in use"
        end
        result = GoodData.post(GoodData.project.md['obj'], to_json)
        saved_object = self.class[result['uri']]
        # TODO add test for explicitly provided identifier
        @json = saved_object.raw_data
        if explicit_identifier then
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
      other.uri == uri
    end

    def validate
      true
    end

    def exportable?
      false
    end

    # TODO: generate fill for other subtypes
    def is_fact?
      false
    end

    def is_attribute?
      false
    end

    def is_metric?
      false
    end

  end
end
