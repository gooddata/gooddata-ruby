module GoodData
  class DataSet < MdObject
    
    root_key :dataSet
    
    SLI_CTG = 'singleloadinterface'
    DS_SLI_CTG = 'dataset-singleloadinterface'

    def sli_enabled?
      content['mode'] == 'SLI'
    end

    def sli
      raise NoProjectError.new "Connect to a project before searching for an object" unless GoodData.project
      slis = GoodData.project.md.links(Model::LDM_CTG).links(SLI_CTG)[DS_SLI_CTG]
      uri = slis[identifier]['link']
      MdObject[uri]
    end
  end
end