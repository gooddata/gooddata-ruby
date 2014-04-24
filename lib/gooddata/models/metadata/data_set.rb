# encoding: UTF-8

require_relative '../metadata.rb'
require_relative 'metadata'

module GoodData
  class DataSet < GoodData::MdObject
    root_key :dataSet

    SLI_CTG = 'singleloadinterface'
    DS_SLI_CTG = 'dataset-singleloadinterface'

    def sli_enabled?
      content['mode'] == 'SLI'
    end

    def sli
      fail(NoProjectError, 'Connect to a project before searching for an object') unless GoodData.project
      slis = GoodData.project.md.links(Model::LDM_CTG).links(SLI_CTG)[DS_SLI_CTG]
      uri = slis[identifier]['link']
      MdObject[uri]
    end

    def attributes
      content['attributes'].map { |a| GoodData::Attribute[a] }
    end

    def facts
      content['facts'].map { |a| GoodData::Attribute[a] }
    end
  end
end
