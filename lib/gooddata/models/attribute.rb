require File.join(File.dirname(__FILE__), "metadata")

module GoodData
  class Attribute < GoodData::MdObject 

    root_key :attribute

    class << self
      def [](id)
        if id == :all
          GoodData.get(GoodData.project.md['query'] + '/attributes/')['query']['entries']
        else 
          super
        end
      end
    end

    def display_forms
      content["displayForms"].map {|df| GoodData::DisplayForm[df["meta"]["uri"]]}
    end
    alias :labels :display_forms

    def is_attribute?
      true
    end
  end
end