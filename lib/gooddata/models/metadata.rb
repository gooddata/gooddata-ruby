module GoodData
  class MdObject
    MD_OBJ_CTG = 'obj'
    IDENTIFIERS_CFG = 'instance-identifiers'

    class << self
      def [](id)
        if id.is_a? Integer or id =~ /^\d+$/
          uri = "#{GoodData.project.md.link(MD_OBJ_CTG)}/#{id}"
        elsif id !~ /\//
          uri = identifier_to_uri id
        elsif id =~ /^\//
          uri = id
        else
          raise "Unexpected object id format: expected numeric ID, identifier with no slashes or an URI starting with a slash"
        end
        MdObject.new GoodData.get uri
      end

      private

      def identifier_to_uri(id)
        uri      = GoodData.project.md[IDENTIFIERS_CFG]
        response = GoodData.post uri, { 'identifierToUri' => [id ] }
        response['identifiers'][0]['uri']
      end
    end

    def initialize(json)
      @json = json
    end

    def delete
      raise "Project '#{title}' with id #{uri} is already deleted" if state == :deleted
      GoodData.delete @json['links']['self']
    end

    def uri
      meta['uri']
    end

    def identifier
      meta['identifier']
    end

    def title
      meta['title']
    end

    def meta
      data['meta']
    end

    def content
      data['content']
    end

    def project
      @project ||= GoodData::Project[uri.gsub /\/obj\/\d+$/, '']
    end

    private

    def data
      first_key = @json.keys[0]
      @json[first_key]
    end
  end

  class DataSet < MdObject
    SLI_CTG = 'singleloadinterface'
    DS_SLI_CTG = 'dataset-singleloadinterface'

    def sli
      GoodData.project.md.links(GoodData::Model::LDM_CTG).links(SLI_CTG)[DS_SLI_CTG]
    end
  end
end