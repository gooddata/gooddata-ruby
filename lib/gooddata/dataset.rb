require 'iconv'

module Gooddata::Dataset
  class Dataset
    def initialize(model)
      labels = []
      model['columns'].each do |c|
        Attribute.new c, self.attributes if c['type'] == 'ATTRIBUTE'
        Fact.new c, self.facts if c['type'] == 'FACT'
        @connection_point = Attribute.new c if c['type'] == 'CONNECTION_POINT'
        labels.push c if c['type'] == 'LABEL'
      end
    end

    def attributes; @attributes ||= {} ; end
    def facts; @facts ||= {} ; end

    def to_maql
      return "# MAQL representation should be here\n# And should be actually posted to server rather than just displayed"
    end 
  end

  class Object
    attr_accessor :title, :name, :folder

    def initialize(hash, store = nil)
      @name   = hash['name']
      @title  = hash['title']
      @folder = hash['folder']
      store[self.identifier] = self if store
    end

    def identifier
      @identifier ||= Iconv.iconv('ascii//ignore//translit', 'utf-8', name).to_s \
                        .gsub(/[^\w\d_]/, '').gsub(/^[\d_]*/, '')
    end
  end

  class Attribute < Object
    def labels
      @labels ||= []
    end

    def to_maql
    
    end
  end

  class Fact < Object
    def to_maql
    
    end
  end
end