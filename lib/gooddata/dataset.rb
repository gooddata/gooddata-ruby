require 'iconv'

##
# Module containing classes that counter-part GoodData server-side meta-data
# elements, including the server-side data model.
#
module Gooddata::Dataset
  FIELD_PK = 'id'
  FACT_PREFIX = 'f_'

  class << self
    def to_id(str)
      Iconv.iconv('ascii//ignore//translit', 'utf-8', str) \
              .to_s.gsub(/[^\w\d_]/, '').gsub(/^[\d_]*/, '').downcase
    end
  end

  class MdObject
    attr_accessor :name, :title

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
        add_to_hash self.attributes, Attribute.new(c, self) if c['type'] == 'ATTRIBUTE'
        add_to_hash self.facts, Fact.new(c, self) if c['type'] == 'FACT'
        @connection_point = Attribute.new(c, self) if c['type'] == 'CONNECTION_POINT'
        labels.push c if c['type'] == 'LABEL'
      end
    end

    def type_prefix ; 'dataset' ; end

    def attributes; @attributes ||= {} ; end
    def facts; @facts ||= {} ; end

    def table
      @table ||= FACT_PREFIX + Gooddata::Dataset::to_id(name)
    end

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

    def add_to_hash(hash, obj)
      hash[obj.identifier] = obj
    end
    private :add_to_hash
  end

  class DatasetColumn < MdObject
    attr_accessor :folder

    def initialize(hash, dataset)
      @name    = hash['name'] || raise("Data set fields must have their names defined")
      @title   = hash['title'] || hash['name']
      @folder  = hash['folder']
      @dataset = dataset
    end

    def title_esc
      title.gsub(/"/, "\\\"")
    end
    private :title_esc
  end

  class Attribute < DatasetColumn
    def type_prefix ; 'attr' ; end

    def labels
      @labels ||= []
    end

    def table
      @table ||= "d_" + Gooddata::Dataset::to_id(@dataset.name) + "_" + Gooddata::Dataset::to_id(name)
    end

    def to_maql_create
      "CREATE ATTRIBUTE {#{identifier}} VISUAL (TITLE \"#{title_esc}\")" \
             + " AS {#{table}.#{Gooddata::Dataset::FIELD_PK}};\n"
    end
  end

  class Fact < DatasetColumn
    def type_prefix ; 'fact' ; end

    def table
      @dataset.table
    end

    def column
      @column ||= FACT_PREFIX + Gooddata::Dataset::to_id(name)
    end

    def to_maql_create
      folder_stmt = ", FOLDER {ffld." + sfn + "}" if folder
      "CREATE FACT {#{self.identifier}} VISUAL (TITLE \"#{title_esc}\")" \
             + " AS {#{table}.#{column}};\n"
    end
  end
end