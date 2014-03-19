# encoding: UTF-8

require File.join(File.dirname(__FILE__), 'metadata.rb')

module GoodData
  class DataSet < MdObject
    root_key :dataSet

    SLI_CTG = 'singleloadinterface'
    DS_SLI_CTG = 'dataset-singleloadinterface'

    def sli_enabled?
      content['mode'] == 'SLI'
    end

    def sli
      raise NoProjectError.new 'Connect to a project before searching for an object' unless GoodData.project
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