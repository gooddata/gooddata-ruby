# encoding: UTF-8

require_relative 'metadata'
require_relative 'md_object'

module GoodData
  class Fact < GoodData::MdObject
    root_key :fact

    class << self
      def [](id)
        if id == :all
          GoodData.get(GoodData.project.md['query'] + '/facts/')['query']['entries']
        else
          super
        end
      end
    end
  end

  module Model
  end
end
