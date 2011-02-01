require 'iconv'

##
# Module containing classes that counter-part GoodData server-side meta-data
# elements, including the server-side data model.
#
module GoodData
  module Model
    # GoodData REST API categories
    LDM_CTG = 'ldm'
    LDM_MANAGE_CTG = 'ldm-manage'

    # Model naming conventions
    FIELD_PK = 'id'
    FK_SUFFIX = '_id'
    FACT_PREFIX = 'f_'
    ATTRIBUTE_FOLDER_PREFIX = 'dim'
    FACT_FOLDER_PREFIX = 'ffld'

    class << self
      def add_dataset(title, columns, project = nil)
        schema = Schema.new 'columns' => columns, 'title' => title
        project = GoodData.project unless project
        ldm_links = GoodData.get project.md[LDM_CTG]
        ldm_uri = GoodData::Links.new(ldm_links)[LDM_MANAGE_CTG]
        GoodData.post ldm_uri, { 'manage' => { 'maql' => schema.to_maql_create } }
      end

      def to_id(str)
        Iconv.iconv('ascii//ignore//translit', 'utf-8', str) \
                .to_s.gsub(/[^\w\d_]/, '').gsub(/^[\d_]*/, '').downcase
      end
    end

    class MdObject
      attr_accessor :name, :title

      def visual
        "TITLE \"#{title_esc}\""
      end

      def title_esc
        title.gsub(/"/, "\\\"")
      end

      ##
      # Generates an identifier from the object name by transliterating
      # non-Latin character and then dropping non-alphanumerical characters.
      #
      def identifier
        @identifier ||= "#{self.type_prefix}.#{Model::to_id(name)}"
      end
    end

    ##
    # Server-side representation of a local data set; includes connection point,
    # attributes and labels, facts, folders and corresponding pieces of physical
    # model abstractions.
    #
    class Schema < MdObject
      def initialize(config, title = nil)
        config['title'] = title unless config['title']
        raise 'Schema name not specified' unless config['title']
        self.config = config
        self.title = config['title']
      end

      def config=(config)
        labels = []
        config['columns'].each do |c|
          add_attribute Attribute.new(c, self) if c['type'] == 'ATTRIBUTE'
          add_fact Fact.new(c, self) if c['type'] == 'FACT'
          @conn_point = RecordsOf.new(c, self) if c['type'] == 'CONNECTION_POINT'
          labels.push c if c['type'] == 'LABEL'
        end
        @conn_point = RecordsOf.new(nil, self) unless @conn_point
      end

      def title=(title)
        @name = title
        @title = title
      end

      def type_prefix ; 'dataset' ; end

      def attributes; @attributes ||= {} ; end
      def facts; @facts ||= {} ; end
      def folders; @folders ||= {}; end

      ##
      # Underlying fact table name
      #
      def table
        @table ||= FACT_PREFIX + Model::to_id(name)
      end

      ##
      # Generates MAQL DDL script to drop this data set and included pieces
      #
      def to_maql_drop
        maql = ""
        [ attributes, facts ].each do |obj|
          maql += obj.to_maql_drop
        end
        maql += "DROP {#{self.identifier}};\n"
      end

      ##
      # Generates MAQL DDL script to create this data set and included pieces
      #
      def to_maql_create
        maql = "# Create the '#{self.title}' data set\n"
        maql += "CREATE DATASET {#{self.identifier}} VISUAL (TITLE \"#{self.title}\");\n\n"
        [ attributes, facts, { 1 => @conn_point } ].each do |objects|
          objects.values.each do |obj|
            maql += "# Create '#{obj.title}' and add it to the '#{self.title}' data set.\n"
            maql += obj.to_maql_create
            maql += "ALTER DATASET {#{self.identifier}} ADD {#{obj.identifier}};\n\n"
          end
        end
        folders_maql = "# Create folders\n"
        folders.keys.each { |folder| folders_maql += folder.to_maql_create }
        folders_maql + "\n" + maql + "SYNCHRONIZE {#{identifier}};\n"
      end

      private

      def add_attribute(attribute)
        add_to_hash(self.attributes, attribute)
        folders[AttributeFolder.new(attribute.folder)] = 1 if attribute.folder
      end

      def add_fact(fact)
        add_to_hash(self.facts, fact)
        folders[FactFolder.new(fact.folder)] = 1 if fact.folder
      end

      def add_to_hash(hash, obj); hash[obj.identifier] = obj; end
    end

    ##
    # This is a base class for server-side LDM elements such as attributes, labels and
    # facts
    #
    class Column < MdObject
      attr_accessor :folder

      def initialize(hash, schema)
        @name    = hash['name'] || raise("Data set fields must have their names defined")
        @title   = hash['title'] || hash['name']
        @folder  = hash['folder']
        @schema  = schema
      end

      def to_maql_drop
        "DROP {#{self.identifier}};\n"
      end

      def visual
        visual = super
        visual += ", FOLDER {#{folder_prefix}.#{Model::to_id(folder)}}" if folder
        visual
      end
    end

    ##
    # GoodData attribute abstraction
    #
    class Attribute < Column
      def type_prefix ; 'attr' ; end
      def folder_prefix; ATTRIBUTE_FOLDER_PREFIX; end

      def labels
        @labels ||= []
      end

      def table
        @table ||= "d_" + Model::to_id(@schema.name) + "_" + Model::to_id(name)
      end

      def to_maql_create
        "CREATE ATTRIBUTE {#{identifier}} VISUAL (#{visual})" \
               + " AS KEYS {#{table}.#{GoodData::Model::FIELD_PK}} FULLSET;\n"
      end
    end

    ##
    # A GoodData attribute that represents a data set's connection point or a data set
    # without a connection point
    #
    class RecordsOf < Attribute
      def initialize(column, schema)
        if column then
          super
        else
          @name = 'id'
          @title = "Records of #{schema.name}"
          @folder = nil
          @schema = schema
        end
      end

      def table
        @table ||= "f_" + Model::to_id(@schema.name)
      end

      def to_maql_create
        maql = super
        maql += "\n# Connect '#{self.title}' to all attributes of this data set\n"
        @schema.attributes.values.each do |c|
          maql += "ALTER ATTRIBUTE {#{c.identifier}} ADD KEYS " \
                + "{#{table}.#{Model::to_id(c.name)}#{FK_SUFFIX}};\n"
        end
        maql
      end
    end

    ##
    # GoodData fact abstraction
    #
    class Fact < Column
      def type_prefix ; 'fact' ; end
      def folder_prefix; FACT_FOLDER_PREFIX; end

      def table
        @schema.table
      end

      def column
        @column ||= FACT_PREFIX + Model::to_id(name)
      end

      def to_maql_create
        "CREATE FACT {#{self.identifier}} VISUAL (#{visual})" \
               + " AS {#{table}.#{column}};\n"
      end
    end

    ##
    # Base class for GoodData attribute and fact folder abstractions
    #
    class Folder < MdObject
      def initialize(title)
        @title = title
        @name = title
      end

      def to_maql_create
        "CREATE FOLDER {#{type_prefix}.#{Model::to_id(name)}}" \
            + " VISUAL (#{visual}) TYPE #{type};\n"
      end
    end

    ##
    # GoodData attribute folder abstraction
    #
    class AttributeFolder < Folder
      def type; "ATTRIBUTE"; end
      def type_prefix; "dim"; end
    end

    ##
    # GoodData fact folder abstraction
    #
    class FactFolder < Folder
      def type; "FACT"; end
      def type_prefix; "ffld"; end
    end
  end
end