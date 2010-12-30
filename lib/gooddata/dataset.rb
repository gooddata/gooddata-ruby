require 'iconv'

module Gooddata::Dataset
  class << self
    def to_id(str)
      Iconv.iconv('ascii//ignore//translit', 'utf-8', str) \
              .to_s.gsub(/[^\w\d_]/, '').gsub(/^[\d_]*/, '')
    end
  end

  class MdObject
    attr_accessor :name, :title, :TYPE

    ##
    # Generates an identifier from the object name by transliterating
    # non-Latin character and then dropping non-alphanumerical characters.
    #
    def identifier
      @identifier ||= "#{self.type_prefix}.#{Gooddata::Dataset::to_id(name)}"
    end
  end

  class Dataset < MdObject
    def initialize(model, title = nil)
      @title = title || model['title'] || raise("Dataset name not specified")
      @name  = @title
      labels = []
      model['columns'].each do |c|
        Attribute.new c, self.attributes if c['type'] == 'ATTRIBUTE'
        Fact.new c, self.facts if c['type'] == 'FACT'
        @connection_point = Attribute.new c if c['type'] == 'CONNECTION_POINT'
        labels.push c if c['type'] == 'LABEL'
      end
    end

    def type_prefix ; 'dataset' ; end

    def attributes; @attributes ||= {} ; end
    def facts; @facts ||= {} ; end

    def to_maql_drop
      maql = "DROP {#{self.identifier}};"
    end

    def to_maql_create
      maql = "CREATE DATASET {#{self.identifier}} VISUAL (TITLE \"#{self.title}\");\n"
      [ attributes, facts ].each do |objects|
        objects.values.each do |obj|
          maql += obj.to_maql_create
          maql += "ALTER DATASET {#{self.identifier}} ADD {#{obj.identifier}};\n"
        end
      end
      maql
    end 
  end

  class DatasetColumn < MdObject
    attr_accessor :title, :folder

    def initialize(hash, store = nil)
      @name   = hash['name'] || raise("Data set fields must have their names defined")
      @title  = hash['title'] || hash['name']
      @folder = hash['folder']
      store[self.identifier] = self if store
    end
  end

  class Attribute < DatasetColumn
    def type_prefix ; 'attr' ; end

    def labels
      @labels ||= []
    end

    def to_maql_create
      return "CREATE ATTRIBUTE {#{identifier}} AS ;\n" # TODO
    end
  end

  class Fact < DatasetColumn
    def type_prefix ; 'fact' ; end

    def to_maql_create
      folder_stmt = ", FOLDER {ffld." + sfn + "}" if folder
      return "CREATE FACT {#{self.identifier}} VISUAL (TITLE \"#{self.title}\");\n" # TODO
    end
  end
end