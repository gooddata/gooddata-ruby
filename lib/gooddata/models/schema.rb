# encoding: UTF-8

require_relative 'md_object'

module GoodData
  module Model
    ##
    # Server-side representation of a local data set; includes connection point,
    # attributes and labels, facts, folders and corresponding pieces of physical
    # model abstractions.
    #
    class Schema < MdObject
      attr_reader :fields, :attributes, :facts, :folders, :references, :labels, :name, :title, :anchor

      def self.load(file)
        Schema.new JSON.load(open(file))
      end

      def initialize(config, name = 'Default Name', title = 'Default Title')
        super()
        @fields = []
        @attributes = []
        @facts = []
        @folders = {
          :facts => {},
          :attributes => {}
        }
        @references = []
        @labels = []

        config[:name] = name unless config[:name]
        config[:title] = config[:name] unless config[:title]
        config[:title] = title unless config[:title]
        config[:title] = config[:title].humanize

        fail 'Schema name not specified' unless config[:name]
        self.name = config[:name]
        self.title = config[:title]
        self.config = config
      end

      def config=(config)
        config[:columns].each do |c|
          case c[:type].to_s
            when 'attribute'
              add_attribute c
            when 'fact'
              add_fact c
            when 'date'
              add_date c
            when 'anchor'
              set_anchor c
            when 'label'
              add_label c
            when 'reference'
              add_reference c
            else
              fail "Unexpected type #{c[:type]} in #{c.inspect}"
          end
        end
        @anchor = Anchor.new(nil, self) unless @anchor
      end

      def type_prefix
        'dataset'
      end

      ##
      # Underlying fact table name
      #
      def table
        @table ||= FACT_COLUMN_PREFIX + name
      end

      ##
      # Generates MAQL DDL script to drop this data set and included pieces
      #
      def to_maql_drop
        maql = ''
        [attributes, facts].each do |obj|
          maql += obj.to_maql_drop
        end
        maql += "DROP {#{self.identifier}};\n"
      end

      ##
      # Generates MAQL DDL script to create this data set and included pieces
      #
      def to_maql_create
        # TODO: Use template (.erb)
        maql = "# Create the '#{self.title}' data set\n"
        maql += "CREATE DATASET {#{self.identifier}} VISUAL (TITLE \"#{self.title}\");\n\n"
        [attributes, facts, {1 => @anchor}].each do |objects|
          objects.values.each do |obj|
            maql += "# Create '#{obj.title}' and add it to the '#{self.title}' data set.\n"
            maql += obj.to_maql_create
            maql += "ALTER DATASET {#{self.identifier}} ADD {#{obj.identifier}};\n\n"
          end
        end

        labels.each do |label|
          maql += "# Creating Labels\n"
          maql += label.to_maql_create
        end

        references.values.each do |ref|
          maql += "# Creating references\n"
          maql += ref.to_maql_create
        end

        folders_maql = "# Create folders\n"
        (folders[:attributes].values + folders[:facts].values).each { |folder| folders_maql += folder.to_maql_create }
        folders_maql + "\n" + maql + "SYNCHRONIZE {#{identifier}};\n"
      end

      def upload(path, project = nil, mode = 'FULL')
        if path =~ URI::regexp
          Tempfile.open('remote_file') do |temp|
            temp << open(path).read
            temp.flush
            upload_data(temp, mode)
          end
        else
          upload_data(path, mode)
        end
      end

      def upload_data(path, mode)
        GoodData::Model.upload_data(path, to_manifest(mode))
      end

      # Generates the SLI manifest describing the data loading
      #
      def to_manifest(mode = 'FULL')
        {
          'dataSetSLIManifest' => {
            'parts' => fields.reduce([]) { |memo, f| val = f.to_manifest_part(mode); memo << val unless val.nil?; memo },
            'dataSet' => self.identifier,
            'file' => 'data.csv', # should be configurable
            'csvParams' => {
              'quoteChar' => '"',
              'escapeChar' => '"',
              'separatorChar' => ',',
              'endOfLine' => "\n"
            }
          }
        }
      end

      def to_wire_model
        {
          'dataset' => {
            'identifier' => identifier,
            'title' => title,
            'anchor' => @anchor.to_wire_model,
            'facts' => facts.map { |f| f.to_wire_model },
            'attributes' => attributes.map { |a| a.to_wire_model },
            'references' => references.map { |r| r.is_a?(DateReference) ? r.schema_ref : type_prefix + '.' + r.schema_ref }}
        }
      end

      private

      def add_attribute(column)
        attribute = Attribute.new column, self
        fields << attribute
        attributes << attribute
        add_attribute_folder(attribute.folder)
        # folders[AttributeFolder.new(attribute.folder)] = 1 if attribute.folder
      end

      def add_attribute_folder(name)
        return if name.nil?
        return if folders[:attributes].has_key?(name)
        folders[:attributes][name] = AttributeFolder.new(name)
      end

      def add_fact(column)
        fact = Fact.new column, self
        fields << fact
        facts << fact
        add_fact_folder(fact.folder)
        # folders[FactFolder.new(fact.folder)] = 1 if fact.folder
      end

      def add_fact_folder(name)
        return if name.nil?
        return if folders[:facts].has_key?(name)
        folders[:facts][name] = FactFolder.new(name)
      end

      def add_label(column)
        label = Label.new(column, nil, self)
        labels << label
        fields << label
      end

      def add_reference(column)
        reference = Reference.new(column, self)
        fields << reference
        references << reference
      end

      def add_date(column)
        date = DateColumn.new column, self
        @fields << date
        date.parts.values.each { |p| @fields << p }
        date.facts.each { |f| facts << f }
        date.attributes.each { |a| attributes << a }
        date.references.each { |r| references << r }
      end

      def set_anchor(column)
        @anchor = Anchor.new column, self
        @fields << @anchor
      end
    end
  end
end
