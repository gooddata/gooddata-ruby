require 'gooddata/model'

module GoodData
  class MdObject
    MD_OBJ_CTG = 'obj'
    IDENTIFIERS_CFG = 'instance-identifiers'

    class << self
      def root_key(a_key)
        define_method :root_key, Proc.new { a_key.to_s}
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
          raise "Unexpected object id format: expected numeric ID, identifier with no slashes or an URI starting with a slash"
        end
        self.new(GoodData.get uri) unless uri.nil?
      end

      def find_by_tag(tag)
        self[:all].find_all {|r| r["tags"].split(",").include?(tag)}
      end

      def find_first_by_title(title)
        item = self[:all].find {|r| r["title"] == title}
        self[item["link"]]
      end

      private

      def identifier_to_uri(id)
        raise NoProjectError.new "Connect to a project before searching for an object" unless GoodData.project
        uri      = GoodData.project.md[IDENTIFIERS_CFG]
        response = GoodData.post uri, { 'identifierToUri' => [id ] }
        if response['identifiers'].empty?
          nil
        else
          response['identifiers'][0]['uri']
        end
      end
    end

    def initialize(json)
      @json = json
    end

    def delete
      GoodData.delete(uri)
    end

    def obj_id
      uri.split('/').last
    end

    def links
      data['links']
    end

    def uri
      meta['uri']
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
      data["meta"]["title"] = a_title
    end

    def summary=(a_summary)
      data["meta"]["summary"] = a_summary
    end

    def tags
      data["meta"]["tags"]
    end

    def tags=(list_of_tags)
      data["meta"]["tags"] = tags
    end

    def meta
      data['meta']
    end

    def content
      data['content']
    end

    def project
      @project ||= Project[uri.gsub(/\/obj\/\d+$/, '')]
    end

    def get_usedby
      result = GoodData.get "#{GoodData.project.md['usedby2']}/#{obj_id}"
      result["entries"]
    end

    def get_using
      result = GoodData.get "#{GoodData.project.md['using2']}/#{obj_id}"
      result["entries"]
    end

    def to_json
      @json.to_json
    end

    def raw_data
      @json
    end

    def data
      raw_data[root_key]
    end

    def saved?
      !!uri
    end

    def save
      fail("Validation failed") unless validate

      if saved?
        GoodData.put(uri, to_json)
      else
        result = GoodData.post(GoodData.project.md['obj'], to_json)
        saved_object = self.class[result["uri"]]
        @json = saved_object.raw_data
      end
      self
    end

    def ==(other)
      other.uri == uri
    end

    def validate
      true
    end
  end
end
