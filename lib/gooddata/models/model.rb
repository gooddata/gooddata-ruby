# encoding: UTF-8

require 'open-uri'
require 'active_support/all'
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
    FACT_COLUMN_PREFIX = 'f_'
    DATE_COLUMN_PREFIX = 'dt_'
    TIME_COLUMN_PREFIX = 'tm_'
    LABEL_COLUMN_PREFIX = 'nm_'
    ATTRIBUTE_FOLDER_PREFIX = 'dim'
    ATTRIBUTE_PREFIX = 'attr'
    LABEL_PREFIX = 'label'
    FACT_PREFIX = 'fact'
    DATE_FACT_PREFIX = 'dt'
    DATE_ATTRIBUTE = 'date'
    DATE_ATTRIBUTE_DEFAULT_DISPLAY_FORM = 'mdyy'
    TIME_FACT_PREFIX = 'tm.dt'
    TIME_ATTRIBUTE_PREFIX = 'attr.time'
    FACT_FOLDER_PREFIX = 'ffld'

    SKIP_FIELD = false

    class << self
      def add_dataset(name, columns, project = nil)
        Schema.new('columns' => columns, 'name' => name)
        add_schema(schema, project)
      end

      def add_schema(schema, project = nil)
        unless schema.respond_to?(:to_maql_create) || schema.is_a?(String) then
          raise ArgumentError.new("Schema object or schema file path expected, got '#{schema}'")
        end
        schema = Schema.load(schema) unless schema.respond_to?(:to_maql_create)
        project = GoodData.project unless project
        ldm_links = GoodData.get project.md[LDM_CTG]
        ldm_uri = Links.new(ldm_links)[LDM_MANAGE_CTG]
        GoodData.post ldm_uri, {'manage' => {'maql' => schema.to_maql_create}}
      end

      # Load given file into a data set described by the given schema
      def upload_data(path, manifest, options={})
        project = options[:project] || GoodData.project
        # mode = options[:mode] || "FULL"
        path = path.path if path.respond_to? :path
        inline_data = path.is_a?(String) ? false : true

        # create a temporary zip file
        dir = Dir.mktmpdir
        begin
          Zip::File.open("#{dir}/upload.zip", Zip::File::CREATE) do |zip|
            # TODO make sure schema columns match CSV column names
            zip.get_output_stream('upload_info.json') { |f| f.puts JSON.pretty_generate(manifest) }
            if inline_data
              zip.get_output_stream('data.csv') do |f|
                path.each do |row|
                  f.puts row.to_csv
                end
              end
            else
              zip.add('data.csv', path)
            end
          end

          # upload it
          GoodData.upload_to_user_webdav("#{dir}/upload.zip", :directory => File.basename(dir))
        ensure
          FileUtils.rm_rf dir
        end

        # kick the load
        pull = {'pullIntegration' => File.basename(dir)}
        link = project.md.links('etl')['pull']
        task = GoodData.post link, pull
        while GoodData.get(task['pullTask']['uri'])['taskStatus'] === 'RUNNING' || GoodData.get(task['pullTask']['uri'])['taskStatus'] === 'PREPARED'
          sleep 30
        end
        if GoodData.get(task['pullTask']['uri'])['taskStatus'] == 'ERROR'
          s = StringIO.new
          GoodData.download_form_user_webdav(File.basename(dir) + '/upload_status.json', s)
          js = JSON.parse(s.string)
          fail "Load Failed with error #{JSON.pretty_generate(js)}"
        end
      end

      def merge_dataset_columns(a_schema_blueprint, b_schema_blueprint)
        a_schema_blueprint = a_schema_blueprint.to_hash
        b_schema_blueprint = b_schema_blueprint.to_hash
        d = Marshal.load(Marshal.dump(a_schema_blueprint))
        d[:columns] = d[:columns] + b_schema_blueprint[:columns]
        d[:columns].uniq!
        columns_that_failed_to_merge = d[:columns].group_by { |x| x[:name] }.map { |k, v| [k, v.count] }.find_all { |x| x[1] > 1 }
        fail "Columns #{columns_that_failed_to_merge} failed to merge. When merging columns with the same name they have to be identical." unless columns_that_failed_to_merge.empty?
        d
      end
    end

    class ProjectBlueprint
      attr_accessor :data

      def self.from_json(spec)
        if spec.is_a?(String)
          ProjectBlueprint.new(JSON.parse(File.read(spec), :symbolize_names => true))
        else
          ProjectBlueprint.new(spec)
        end
      end

      def change(&block)
        builder = ProjectBuilder.create_from_data(self)
        block.call(builder)
        builder
        @data = builder.to_hash
        self
      end

      def datasets
        data[:datasets].map { |d| SchemaBlueprint.new(d) }
      end

      def add_dataset(a_dataset, index=nil)
        if index.nil? || index > datasets.length
          data[:datasets] << a_dataset.to_hash
        else
          data[:datasets].insert(index, a_dataset.to_hash)
        end
      end

      def remove_dataset(dataset_name)
        x = data[:datasets].find { |d| d[:name] == dataset_name }
        index = data[:datasets].index(x)
        data[:datasets].delete_at(index)
      end

      def date_dimensions
        data[:date_dimensions]
      end

      def get_dataset(name)
        ds = data[:datasets].find { |d| d[:name] == name }
        SchemaBlueprint.new(ds) unless ds.nil?
      end

      def initialize(init_data)
        @data = init_data
      end

      def model_validate
        if datasets.count == 1
          []
        else
          x = datasets.reduce([]) { |memo, schema| schema.has_anchor? ? memo << [schema.name, schema.anchor[:name]] : memo }
          refs = datasets.reduce([]) do |memo, dataset|
            memo.concat(dataset.references)
          end
          refs.reduce([]) do |memo, ref|
            x.include?([ref[:dataset], ref[:reference]]) ? memo : memo.concat([ref])
          end
        end
      end

      def model_valid?
        errors = model_validate
        errors.empty? ? true : false
      end

      def merge!(a_blueprint)
        temp_blueprint = dup
        a_blueprint.datasets.each do |dataset|
          local_dataset = temp_blueprint.get_dataset(dataset.name)
          if local_dataset.nil?
            temp_blueprint.add_dataset(dataset.dup)
          else
            index = temp_blueprint.datasets.index(local_dataset)
            local_dataset.merge!(dataset)
            temp_blueprint.remove_dataset(local_dataset.name)
            temp_blueprint.add_dataset(local_dataset, index)
          end
        end
        @data = temp_blueprint.data
        self
      end

      def dup
        deep_copy = Marshal.load(Marshal.dump(data))
        ProjectBlueprint.new(deep_copy)
      end

      def title
        data[:title]
      end

      def to_wire_model
        {
          'diffRequest' => {
            'targetModel' => {
              'projectModel' => {
                'datasets' => datasets.map { |d| d.to_wire_model },
                'dateDimensions' => date_dimensions.map { |d|
                  {
                    'dateDimension' => {
                      'name' => d[:name],
                      'title' => d[:title] || d[:name].humanize
                    }
                  } }
              }}}}
      end

      def to_hash
        @data
      end
    end

    class SchemaBlueprint
      attr_accessor :data

      def change(&block)
        builder = SchemaBuilder.create_from_data(self)
        block.call(builder)
        builder
        @data = builder.to_hash
        self
      end

      def initialize(init_data)
        @data = init_data
      end

      def upload(source, options={})
        project = options[:project] || GoodData.project
        fail 'You have to specify a project into which you want to load.' if project.nil?
        mode = options[:load] || 'FULL'
        project.upload(source, to_schema, mode)
      end

      def merge!(a_blueprint)
        new_blueprint = GoodData::Model.merge_dataset_columns(self, a_blueprint)
        @data = new_blueprint
        self
      end

      def name
        data[:name]
      end

      def title
        data[:title]
      end

      def to_hash
        data
      end

      def columns
        data[:columns]
      end

      def has_anchor?
        columns.any? { |c| c[:type].to_s == 'anchor' }
      end

      def anchor
        find_column_by_type(:anchor, :first)
      end

      def references
        find_column_by_type(:reference)
      end

      def attributes
        find_column_by_type(:attribute)
      end

      def facts
        find_column_by_type(:fact)
      end

      def find_column_by_type(type, all=:all)
        type = type.to_s
        if all == :all
          columns.find_all { |c| c[:type].to_s == type }
        else
          columns.find { |c| c[:type].to_s == type }
        end
      end

      def find_column_by_name(type, all=:all)
        type = type.to_s
        if all == :all
          columns.find_all { |c| c[:name].to_s == type }
        else
          columns.find { |c| c[:name].to_s == type }
        end
      end

      def to_schema
        Schema.new(to_hash)
      end

      def to_manifest
        to_schema.to_manifest
      end

      def pretty_print(printer)
        printer.text "Schema <#{object_id}>:\n"
        printer.text " Name: #{name}\n"
        printer.text " Columns: \n"
        printer.text columns.map { |c| "  #{c[:name]}: #{c[:type]}" }.join("\n")
      end

      def dup
        deep_copy = Marshal.load(Marshal.dump(data))
        SchemaBlueprint.new(deep_copy)
      end

      def to_wire_model
        to_schema.to_wire_model
      end

      def ==(other)
        to_hash == other.to_hash
      end
    end

    class ProjectBuilder
      attr_reader :title, :datasets, :reports, :metrics, :uploads, :users, :assert_report, :date_dimensions

      class << self
        def create_from_data(blueprint, title = 'Title')
          pb = ProjectBuilder.new(title)
          pb.data = blueprint.to_hash
          pb
        end

        def create(title, options={}, &block)
          pb = ProjectBuilder.new(title)
          block.call(pb)
          pb
        end
      end

      def initialize(title)
        @title = title
        @datasets = []
        @reports = []
        @assert_tests = []
        @metrics = []
        @uploads = []
        @users = []
        @dashboards = []
        @date_dimensions = []
      end

      def add_date_dimension(name, options = {})
        dimension = {
          urn: options[:urn],
          name: name,
          title: options[:title]
        }

        @date_dimensions << dimension
      end

      def add_dataset(name, &block)
        builder = GoodData::Model::SchemaBuilder.new(name)
        block.call(builder)
        if @datasets.any? { |item| item[:name] == name }
          ds = @datasets.find { |item| item[:name] == name }
          index = @datasets.index(ds)
          stuff = GoodData::Model.merge_dataset_columns(ds, builder.to_hash)
          @datasets.delete_at(index)
          @datasets.insert(index, stuff)
        else
          @datasets << builder.to_hash
        end
      end

      def add_report(title, options={})
        @reports << {:title => title}.merge(options)
      end

      def add_metric(title, options={})
        @metrics << {:title => title}.merge(options)
      end

      def add_dashboard(title, &block)
        db = DashboardBuilder.new(title)
        block.call(db)
        @dashboards << db.to_hash
      end

      def load_metrics(file)
        new_metrics = JSON.parse(open(file).read, :symbolize_names => true)
        @metrics = @metrics + new_metrics
      end

      def load_datasets(file)
        new_metrics = JSON.parse(open(file).read, :symbolize_names => true)
        @datasets = @datasets + new_metrics
      end

      def assert_report(report, result)
        @assert_tests << {:report => report, :result => result}
      end

      def upload(data, options={})
        mode = options[:mode] || 'FULL'
        dataset = options[:dataset]
        @uploads << {
          :source => data,
          :mode => mode,
          :dataset => dataset
        }
      end

      def add_users(users)
        @users << users
      end

      def to_json(options={})
        eliminate_empty = options[:eliminate_empty] || false

        if eliminate_empty
          JSON.pretty_generate(to_hash.reject { |k, v| v.is_a?(Enumerable) && v.empty? })
        else
          JSON.pretty_generate(to_hash)
        end
      end

      def to_hash
        {
          :title => @title,
          :datasets => @datasets,
          :uploads => @uploads,
          :dashboards => @dashboards,
          :metrics => @metrics,
          :reports => @reports,
          :users => @users,
          :assert_tests => @assert_tests,
          :date_dimensions => @date_dimensions
        }
      end

      def get_dataset(name)
        datasets.find { |d| d.name == name }
      end
    end

    class DashboardBuilder
      def initialize(title)
        @title = title
        @tabs = []
      end

      def add_tab(tab, &block)
        tb = TabBuilder.new(tab)
        block.call(tb)
        @tabs << tb
        tb
      end

      def to_hash
        {
          :name => @name,
          :tabs => @tabs.map { |tab| tab.to_hash }
        }
      end
    end

    class TabBuilder
      def initialize(title)
        @title = title
        @stuff = []
      end

      def add_report(options={})
        @stuff << {:type => :report}.merge(options)
      end

      def to_hash
        {
          :title => @title,
          :items => @stuff
        }
      end
    end

    class SchemaBuilder
      attr_accessor :data

      class << self
        def create_from_data(blueprint)
          sc = SchemaBuilder.new
          sc.data = blueprint.to_hash
          sc
        end
      end

      def initialize(name=nil)
        @data = {
          :name => name,
          :columns => []
        }
      end

      def name
        data[:name]
      end

      def columns
        data[:columns]
      end

      def add_column(column_def)
        columns.push(column_def)
        self
      end

      def add_anchor(name, options={})
        add_column({:type => :anchor, :name => name}.merge(options))
        self
      end

      def add_attribute(name, options={})
        add_column({:type => :attribute, :name => name}.merge(options))
        self
      end

      def add_fact(name, options={})
        add_column({:type => :fact, :name => name}.merge(options))
        self
      end

      def add_label(name, options={})
        add_column({:type => :label, :name => name}.merge(options))
        self
      end

      def add_date(name, options={})
        add_column({:type => :date, :name => name}.merge(options))
      end

      def add_reference(name, options={})
        add_column({:type => :reference, :name => name}.merge(options))
      end

      def to_json
        JSON.pretty_generate(to_hash)
      end

      def to_hash
        data
      end

      def to_schema
        Schema.new(to_hash)
      end
    end

    class ProjectCreator
      class << self
        def migrate(options={})
          spec = options[:spec] || fail('You need to provide spec for migration')
          spec = spec.to_hash

          token = options[:token]
          project = options[:project] || GoodData::Project.create(:title => spec[:title], :auth_token => token)
          fail('You need to specify token for project creation') if token.nil? && project.nil?

          begin
            GoodData.with_project(project) do |p|
              # migrate_date_dimensions(p, spec[:date_dimensions] || [])
              migrate_datasets(p, spec)
              load(p, spec)
              migrate_metrics(p, spec[:metrics] || [])
              migrate_reports(p, spec[:reports] || [])
              migrate_dashboards(p, spec[:dashboards] || [])
              migrate_users(p, spec[:users] || [])
              execute_tests(p, spec[:assert_tests] || [])
              p
            end
          end
        end

        def migrate_date_dimensions(project, spec)
          spec.each do |dd|
            Model.add_schema(DateDimension.new(dd), project)
          end
        end

        def migrate_datasets(project, spec)
          bp = ProjectBlueprint.new(spec)
          # schema = Schema.load(schema) unless schema.respond_to?(:to_maql_create)
          # project = GoodData.project unless project
          uri = "/gdc/projects/#{GoodData.project.pid}/model/diff"
          result = GoodData.post(uri, bp.to_wire_model)
          link = result['asyncTask']['link']['poll']
          response = GoodData.get(link, :process => false)
          # pp response
          while response.code != 200
            sleep 1
            GoodData.connection.retryable(:tries => 3, :on => RestClient::InternalServerError) do
              sleep 1
              response = GoodData.get(link, :process => false)
              # pp response
            end
          end
          response = GoodData.get(link)
          ldm_links = GoodData.get project.md[LDM_CTG]
          ldm_uri = Links.new(ldm_links)[LDM_MANAGE_CTG]
          chunks = response['projectModelDiff']['updateScripts'].find_all { |script| script['updateScript']['preserveData'] == true && script['updateScript']['cascadeDrops'] == false }.map { |x| x['updateScript']['maqlDdlChunks'] }.flatten
          chunks.each do |chunk|
            GoodData.post ldm_uri, {'manage' => {'maql' => chunk}}
          end

          bp.datasets.each do |ds|
            schema = ds.to_schema
            GoodData::ProjectMetadata["manifest_#{schema.name}"] = schema.to_manifest.to_json
          end
        end

        def migrate_reports(project, spec)
          spec.each do |report|
            project.add_report(report)
          end
        end

        def migrate_dashboards(project, spec)
          spec.each do |dash|
            project.add_dashboard(dash)
          end
        end

        def migrate_metrics(project, spec)
          spec.each do |metric|
            project.add_metric(metric)
          end
        end

        def migrate_users(project, spec)
          spec.each do |user|
            puts "Would migrate user #{user}"
            # project.add_user(user)
          end
        end

        def load(project, spec)
          if spec.has_key?(:uploads)
            spec[:uploads].each do |load|
              schema = GoodData::Model::Schema.new(spec[:datasets].detect { |d| d[:name] == load[:dataset] })
              project.upload(load[:source], schema, load[:mode])
            end
          end
        end

        def execute_tests(project, spec)
          spec.each do |assert|
            result = GoodData::ReportDefinition.execute(assert[:report])
            fail "Test did not pass. Got #{result.table.inspect}, expected #{assert[:result].inspect}" if result.table != assert[:result]
          end
        end
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
        @identifier ||= "#{self.type_prefix}.#{name}"
      end
    end

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

      def initialize(config, name = nil)
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
        config[:title] = config[:title] || config[:name].humanize
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

    ##
    # This is a base class for server-side LDM elements such as attributes, labels and
    # facts
    #
    class Column < MdObject
      attr_accessor :folder, :name, :title, :schema

      def initialize(hash, schema)
        super()
        raise ArgumentError.new("Schema must be provided, got #{schema.class}") unless schema.is_a? Schema
        @name = hash[:name] || raise('Data set fields must have their names defined')
        @title = hash[:title] || hash[:name].humanize
        @folder = hash[:folder]
        @schema = schema
      end

      ##
      # Generates an identifier from the object name by transliterating
      # non-Latin character and then dropping non-alphanumerical characters.
      #
      def identifier
        @identifier ||= "#{self.type_prefix}.#{@schema.name}.#{name}"
      end

      def to_maql_drop
        "DROP {#{self.identifier}};\n"
      end

      def visual
        visual = super
        visual += ", FOLDER {#{folder_prefix}.#{(folder)}}" if folder
        visual
      end

      def to_csv_header(row)
        name
      end

      def to_csv_data(headers, row)
        row[name]
      end


      # Overriden to prevent long strings caused by the @schema attribute
      #
      def inspect
        to_s.sub(/>$/, " @title=#{@title.inspect}, @name=#{@name.inspect}, @folder=#{@folder.inspect}," \
                       " @schema=#{@schema.to_s.sub(/>$/, ' @title=' + @schema.name.inspect + '>')}" \
                       ">")
      end
    end

    ##
    # GoodData attribute abstraction
    #
    class Attribute < Column
      attr_reader :primary_label, :labels

      def type_prefix;
        ATTRIBUTE_PREFIX;
      end

      def folder_prefix;
        ATTRIBUTE_FOLDER_PREFIX;
      end

      def initialize(hash, schema)
        super hash, schema
        @labels = []
        @primary_label = Label.new hash, self, schema
      end

      def table
        @table ||= 'd_' + @schema.name + '_' + name
      end

      def key;
        "#{@name}#{FK_SUFFIX}";
      end

      def to_maql_create
        maql = "CREATE ATTRIBUTE {#{identifier}} VISUAL (#{visual})" \
               + " AS KEYS {#{table}.#{Model::FIELD_PK}} FULLSET;\n"
        maql += @primary_label.to_maql_create if @primary_label
        maql
      end

      def to_manifest_part(mode)
        {
          'referenceKey' => 1,
          'populates' => [@primary_label.identifier],
          'mode' => mode,
          'columnName' => name
        }
      end

      def to_wire_model
        {
          'attribute' => {
            'identifier' => identifier,
            'title' => title,
            'labels' => labels.map do |l|
              {
                'label' => {
                  'identifier' => l.identifier,
                  'title' => l.title,
                  'type' => 'GDC.text'
                }
              }
            end
          }
        }
      end
    end

    ##
    # GoodData display form abstraction. Represents a default representation
    # of an attribute column or an additional representation defined in a LABEL
    # field
    #
    class Label < Column
      attr_accessor :attribute

      def type_prefix;
        'label';
      end

      # def initialize(hash, schema)
      def initialize(hash, attribute, schema)
        super hash, schema
        attribute = attribute.nil? ? schema.fields.find { |field| field.name === hash[:reference] } : attribute
        @attribute = attribute
        attribute.labels << self
      end

      def to_maql_create
        '# LABEL FROM LABEL'
        "ALTER ATTRIBUTE {#{@attribute.identifier}} ADD LABELS {#{identifier}}" \
              + " VISUAL (TITLE #{title.inspect}) AS {#{column}};\n"
      end

      def to_manifest_part(mode)
        {
          'populates' => [identifier],
          'mode' => mode,
          'columnName' => name
        }
      end

      def column
        "#{@attribute.table}.#{LABEL_COLUMN_PREFIX}#{name}"
      end

      alias :inspect_orig :inspect

      def inspect
        inspect_orig.sub(/>$/, " @attribute=#{@attribute.to_s.sub(/>$/, " @name=#{@attribute.name}")}>")
      end
    end

    ##
    # A GoodData attribute that represents a data set's connection point or a data set
    # without a connection point
    #
    class Anchor < Attribute
      def initialize(column, schema)
        if column then
          super
        else
          super({:type => 'anchor', :name => 'id'}, schema)
          @labels = []
          @primary_label = nil
        end
      end

      def table
        @table ||= 'f_' + @schema.name
      end

      def to_maql_create
        maql = super
        maql += "\n# Connect '#{self.title}' to all attributes of this data set\n"
        @schema.attributes.values.each do |c|
          maql += "ALTER ATTRIBUTE {#{c.identifier}} ADD KEYS " \
                + "{#{table}.#{c.key}};\n"
        end
        maql
      end
    end

    ##
    # GoodData fact abstraction
    #
    class Fact < Column
      def type_prefix;
        FACT_PREFIX;
      end

      def column_prefix;
        FACT_COLUMN_PREFIX;
      end

      def folder_prefix;
        FACT_FOLDER_PREFIX;
      end

      def table
        @schema.table
      end

      def column
        @column ||= table + '.' + column_prefix + name
      end

      def to_maql_create
        "CREATE FACT {#{self.identifier}} VISUAL (#{visual})" \
               + " AS {#{column}};\n"
      end

      def to_manifest_part(mode)
        {
          'populates' => [identifier],
          'mode' => mode,
          'columnName' => name
        }
      end

      def to_wire_model
        {
          'fact' => {
            'identifier' => identifier,
            'title' => title
          }
        }
      end
    end

    ##
    # Reference to another data set
    #
    class Reference < Column
      attr_accessor :reference, :schema_ref

      def initialize(column, schema)
        super column, schema
        # pp column
        @name = column[:name]
        @reference = column[:reference]
        @schema_ref = column[:dataset]
        @schema = schema
      end

      ##
      # Generates an identifier of the referencing attribute using the
      # schema name derived from schemaReference and column name derived
      # from the reference key.
      #
      def identifier
        @identifier ||= "#{ATTRIBUTE_PREFIX}.#{@schema_ref}.#{@reference}"
      end

      def key;
        "#{@name}_id";
      end

      def label_column
        "#{LABEL_PREFIX}.#{@schema_ref}.#{@reference}"
      end

      def to_maql_create
        "ALTER ATTRIBUTE {#{self.identifier}} ADD KEYS {#{@schema.table}.#{key}};\n"
      end

      def to_maql_drop
        "ALTER ATTRIBUTE {#{self.identifier} DROP KEYS {#{@schema.table}.#{key}};\n"
      end

      def to_manifest_part(mode)
        {
          'populates' => [label_column],
          'mode' => mode,
          'columnName' => name,
          'referenceKey' => 1
        }
      end
    end

    ##
    # Date as a reference to a date dimension
    #
    class DateReference < Reference
      attr_accessor :format, :output_format, :urn

      def initialize(column, schema)
        super column, schema
        @output_format = column['format'] || 'dd/MM/yyyy'
        @format = @output_format.gsub('yyyy', '%Y').gsub('MM', '%m').gsub('dd', '%d')
        @urn = column[:urn] || 'URN:GOODDATA:DATE'
      end

      def identifier
        @identifier ||= "#{@schema_ref}.#{DATE_ATTRIBUTE}"
      end

      def to_manifest_part(mode)
        {
          'populates' => ["#{identifier}.#{DATE_ATTRIBUTE_DEFAULT_DISPLAY_FORM}"],
          'mode' => mode,
          'constraints' => {'date' => output_format},
          'columnName' => name,
          'referenceKey' => 1
        }
      end

      # def to_maql_create
      #   # urn:chefs_warehouse_fiscal:date
      #   super_maql = super
      #   maql = ""
      #   # maql = "# Include date dimensions\n"
      #   # maql += "INCLUDE TEMPLATE \"#{urn}\" MODIFY (IDENTIFIER \"#{name}\", TITLE \"#{title || name}\");\n"
      #   maql += super_maql
      # end
    end

    ##
    # Date field that's not connected to a date dimension
    #
    class DateAttribute < Attribute
      def key;
        "#{DATE_COLUMN_PREFIX}#{super}";
      end

      def to_manifest_part(mode)
        {
          'populates' => ['label.stuff.mmddyy'],
          'format' => 'unknown',
          'mode' => mode,
          'referenceKey' => 1
        }
      end
    end

    ##
    # Fact representation of a time of a day
    #
    class TimeFact < Fact
      def column_prefix;
        TIME_COLUMN_PREFIX;
      end

      def type_prefix;
        TIME_FACT_PREFIX;
      end
    end

    ##
    # Time as a reference to a time-of-a-day dimension
    #
    class TimeReference < Reference
    end

    ##
    # Time field that's not connected to a time-of-a-day dimension
    #
    class TimeAttribute < Attribute
      def type_prefix;
        TIME_ATTRIBUTE_PREFIX;
      end

      def key;
        "#{TIME_COLUMN_PREFIX}#{super}";
      end

      def table;
        @table ||= "#{super}_tm";
      end
    end

    ##
    # Date column. A container holding the following
    # parts: date fact, a date reference or attribute and an optional time component
    # that contains a time fact and a time reference or attribute.
    #
    class DateColumn < Column
      attr_reader :parts, :facts, :attributes, :references

      def initialize(column, schema)
        super column, schema
        @parts = {}; @facts = []; @attributes = []; @references = []

        # @facts << @parts[:date_fact] = DateFact.new(column, schema)
        if column[:dataset] then
          @parts[:date_ref] = DateReference.new column, schema
          @references << @parts[:date_ref]
        else
          @attributes << @parts[:date_attr] = DateAttribute.new(column, schema)
        end
        # if column['datetime'] then
        #   puts "*** datetime"
        #   @facts << @parts[:time_fact] = TimeFact.new(column, schema)
        #   if column['schema_reference'] then
        #     @parts[:time_ref] = TimeReference.new column, schema
        #   else
        #     @attributes << @parts[:time_attr] = TimeAttribute.new(column, schema)
        #   end
        # end
      end

      def to_maql_create
        @parts.values.map { |v| v.to_maql_create }.join "\n"
      end

      def to_maql_drop
        @parts.values.map { |v| v.to_maql_drop }.join "\n"
      end

      def to_csv_header(row)
        SKIP_FIELD
      end

      def to_csv_data(headers, row)
        SKIP_FIELD
      end

      def to_manifest_part(mode)
        nil
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
        "CREATE FOLDER {#{type_prefix}.#{name}}" \
            + " VISUAL (#{visual}) TYPE #{type};\n"
      end
    end

    ##
    # GoodData attribute folder abstraction
    #
    class AttributeFolder < Folder
      def type;
        'ATTRIBUTE'
      end

      def type_prefix;
        'dim'
      end
    end

    ##
    # GoodData fact folder abstraction
    #
    class FactFolder < Folder
      def type;
        'FACT'
      end

      def type_prefix;
        'ffld'
      end
    end

    class DateDimension < MdObject
      def initialize(spec={})
        super()
        @name = spec[:name]
        @title = spec[:title] || @name
        @urn = spec[:urn] || 'URN:GOODDATA:DATE'
      end

      def to_maql_create
        # urn = "urn:chefs_warehouse_fiscal:date"
        # title = "title"
        # name = "name"

        maql = ''
        maql += "INCLUDE TEMPLATE \"#{@urn}\" MODIFY (IDENTIFIER \"#{@name}\", TITLE \"#{@title}\");"
        maql
      end
    end
  end
end