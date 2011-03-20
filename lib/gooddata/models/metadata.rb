require 'gooddata/model'

module GoodData
  class MdObject
    MD_OBJ_CTG = 'obj'
    IDENTIFIERS_CFG = 'instance-identifiers'

    class << self
      def [](id)
        raise "Cannot search for nil #{self.class}" unless id
        if id.is_a? Integer or id =~ /^\d+$/
          uri = "#{GoodData.project.md.link(MD_OBJ_CTG)}/#{id}"
        elsif id !~ /\//
          uri = identifier_to_uri id
        elsif id =~ /^\//
          uri = id
        else
          raise "Unexpected object id format: expected numeric ID, identifier with no slashes or an URI starting with a slash"
        end
        self.new((GoodData.get uri).values[0])
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
      @json['meta']
    end

    def content
      @json['content']
    end

    def project
      @project ||= Project[uri.gsub(/\/obj\/\d+$/, '')]
    end
  end

  class DataSet < MdObject
    SLI_CTG = 'singleloadinterface'
    DS_SLI_CTG = 'dataset-singleloadinterface'

    def sli_enabled?
      content['mode'] == 'SLI'
    end

    def sli
      slis = GoodData.project.md.links(Model::LDM_CTG).links(SLI_CTG)[DS_SLI_CTG]
      uri = slis[identifier]['link']
      MdObject[uri]
    end
  end
end
