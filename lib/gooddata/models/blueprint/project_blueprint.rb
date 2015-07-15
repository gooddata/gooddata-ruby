# encoding: UTF-8

module GoodData
  module Model
    class ProjectBlueprint
      attr_accessor :data

      # Instantiates a project blueprint either from a file or from a string containing
      # json. Also eats Hash for convenience.
      #
      # @param spec [String | Hash] value of an label you are looking for
      # @return [GoodData::Model::ProjectBlueprint]
      class << self
        def from_json(spec)
          if spec.is_a?(String)
            if File.file?(spec)
              ProjectBlueprint.new(MultiJson.load(File.read(spec), :symbolize_keys => true))
            else
              ProjectBlueprint.new(MultiJson.load(spec, :symbolize_keys => true))
            end
          else
            ProjectBlueprint.new(spec)
          end
        end

        def build(title, &block)
          pb = ProjectBuilder.create(title, &block)
          pb.to_blueprint
        end
      end

      # Removes column from from the blueprint
      #
      # @param project [Hash | GoodData::Model::ProjectBlueprint] Project blueprint
      # @param dataset [Hash | GoodData::Model::DatasetBlueprint] Dataset blueprint
      # @param column_id [String] Column id
      # @return [Hash | GoodData::Model::ProjectBlueprint] Returns changed blueprint
      def self.remove_column!(project, dataset, column_id)
        dataset = find_dataset(project, dataset)
        col = dataset[:columns].find { |c| c[:id] == column_id }
        dataset[:columns].delete(col)
        project
      end

      # Removes dataset from blueprint. Dataset can be given as either a name
      # or a DatasetBlueprint or a Hash representation.
      #
      # @param project [Hash | GoodData::Model::ProjectBlueprint] Project blueprint
      # @param dataset_name [GoodData::Model::DatasetBlueprint | String | Hash] Dataset to be removed
      # @return [Hash] new project with removed dataset
      def self.remove_dataset(project, dataset_id)
        dataset = dataset_id.is_a?(String) ? find_dataset(project, dataset_id) : dataset_name
        index = project[:datasets].index(dataset)
        dupped_project = GoodData::Helpers.deep_dup(project)
        dupped_project[:datasets].delete_at(index)
        dupped_project
      end

      # Removes dataset from blueprint. Dataset can be given as either a name
      # or a DatasetBlueprint or a Hash representation. This version mutates
      # the dataset in place
      #
      # @param project [Hash | GoodData::Model::ProjectBlueprint] Project blueprint
      # @param dataset_name [GoodData::Model::DatasetBlueprint | String | Hash] Dataset to be removed
      # @return [Hash] project with removed dataset
      def self.remove_dataset!(project, dataset_id)
        project = project.to_hash
        dataset = dataset_id.is_a?(String) ? find_dataset(project, dataset_id) : dataset_id
        index = project[:datasets].index(dataset)
        project[:datasets].delete_at(index)
        project
      end

      # Returns datasets of blueprint. Those can be optionally including
      # date dimensions
      #
      # @param project [GoodData::Model::ProjectBlueprint | Hash] Project blueprint
      # @param options [Hash] options
      # @return [Array<Hash>]
      def self.datasets(project_blueprint, options = {})
        project_blueprint = project_blueprint.to_hash
        include_date_dimensions = options[:include_date_dimensions] || options[:dd]
        ds = (project_blueprint.to_hash[:datasets] || [])
        if include_date_dimensions
          ds + date_dimensions(project_blueprint)
        else
          ds
        end
      end

      # Returns true if a dataset contains a particular dataset false otherwise
      #
      # @param project [GoodData::Model::ProjectBlueprint | Hash] Project blueprint
      # @param name [GoodData::Model::DatasetBlueprint | String | Hash] Dataset
      # @return [Boolean]
      def self.dataset?(project, name, options = {})
        find_dataset(project, name, options)
        true
      rescue
        false
      end

      # Returns dataset specified. It can check even for a date dimension
      #
      # @param project [GoodData::Model::ProjectBlueprint | Hash] Project blueprint
      # @param obj [GoodData::Model::DatasetBlueprint | String | Hash] Dataset
      # @param options [Hash] options
      # @return [GoodData::Model::DatasetBlueprint]
      def self.find_dataset(project_blueprint, obj, options = {})
        return obj.to_hash if DatasetBlueprint.dataset_blueprint?(obj)
        all_datasets = datasets(project_blueprint, options)
        name = obj.respond_to?(:to_hash) ? obj.to_hash[:id] : obj
        ds = all_datasets.find { |d| d[:id] == name }
        fail "Dataset #{name} could not be found" if ds.nil?
        ds
      end

      # Returns list of date dimensions
      #
      # @param project [GoodData::Model::ProjectBlueprint | Hash] Project blueprint
      # @return [Array<Hash>]
      def self.date_dimensions(project_blueprint)
        project_blueprint.to_hash[:date_dimensions] || []
        # dims.map {|dim| DateDimension.new(dim, project_blueprint)}
      end

      # Returns true if a date dimension of a given name exists in a bleuprint
      #
      # @param project [GoodData::Model::ProjectBlueprint | Hash] Project blueprint
      # @param name [string] Date dimension
      # @return [Boolean]
      def self.date_dimension?(project, name)
        find_date_dimension(project, name)
        true
      rescue
        false
      end

      # Finds a date dimension of a given name in a bleuprint. If a dataset is
      # not found it throws an exeception
      #
      # @param project [GoodData::Model::ProjectBlueprint | Hash] Project blueprint
      # @param name [string] Date dimension
      # @return [Hash]
      def self.find_date_dimension(project, name)
        ds = date_dimensions(project).find { |d| d[:id] == name }
        fail "Date dimension #{name} could not be found" unless ds
        ds
      end

      # Returns fields from all datasets
      #
      # @param project [GoodData::Model::ProjectBlueprint | Hash] Project blueprint
      # @return [Array<Hash>]
      def self.fields(project)
        datasets(project).mapcat { |d| DatasetBlueprint.fields(d) }
      end

      # Changes the dataset through a builder. You provide a block and an istance of
      # GoodData::Model::ProjectBuilder is passed in as the only parameter
      #
      # @return [GoodData::Model::ProjectBlueprint] returns changed project blueprint
      def change(&block)
        builder = ProjectBuilder.create_from_data(self)
        block.call(builder)
        @data = builder.to_hash
        self
      end

      # Returns datasets of blueprint. Those can be optionally including
      # date dimensions
      #
      # @param options [Hash] options
      # @return [Array<GoodData::Model::DatasetBlueprint>]
      def datasets(id = :all, options = {})
        id = id.respond_to?(:id) ? id.id : id
        dss = ProjectBlueprint.datasets(self, options).map do |d|
          case d[:type]
          when :date_dimension
            DateDimension.new(d, self)
          when :dataset
            DatasetBlueprint.new(d, self)
          end
        end
        id == :all ? dss : dss.find { |d| d.id == id }
      end

      # Adds dataset to the blueprint
      #
      # @param a_dataset [Hash | GoodData::Model::SchemaBlueprint] dataset to be added
      # @param index [Integer] number specifying at which position the new dataset should be added. If not specified it is added at the end
      # @return [GoodData::Model::ProjectBlueprint] returns project blueprint
      def add_dataset!(a_dataset, index = nil)
        if index.nil? || index > datasets.length
          data[:datasets] << a_dataset.to_hash
        else
          data[:datasets].insert(index, a_dataset.to_hash)
        end
        self
      end

      def add_date_dimension!(a_dimension, index = nil)
        dim = a_dimension.to_hash
        if index.nil? || index > date_dimensions.length
          data[:date_dimensions] << dim
        else
          data[:date_dimensions].insert(index, dim)
        end
        self
      end

      # Adds column to particular dataset in the blueprint
      #
      # @param dataset [Hash | GoodData::Model::SchemaBlueprint] dataset to be added
      # @param column_definition [Hash] Column definition to be added
      # @return [GoodData::Model::ProjectBlueprint] returns project blueprint
      def add_column!(dataset, column_definition)
        ds = ProjectBlueprint.find_dataset(to_hash, dataset)
        ds[:columns] << column_definition
        self
      end

      # Removes column to particular dataset in the blueprint
      #
      # @param dataset [Hash | GoodData::Model::SchemaBlueprint] dataset to be added
      # @param id [String] id of the column to be removed
      # @return [GoodData::Model::ProjectBlueprint] returns project blueprint
      def remove_column!(dataset, id)
        ProjectBlueprint.remove_column!(to_hash, dataset, id)
        self
      end

      # Moves column to particular dataset in the blueprint. It currently supports moving
      # of attributes and facts only. The rest of the fields probably does not make sense
      # In case of attribute it moves its labels as well.
      #
      # @param id [GoodData::Model::BlueprintField] column to be moved
      # @param from_dataset [Hash | GoodData::Model::SchemaBlueprint] dataset from which the field should be moved
      # @param to_dataset [Hash | GoodData::Model::SchemaBlueprint] dataset to which the field should be moved
      # @return [GoodData::Model::ProjectBlueprint] returns project blueprint
      def move!(col, from_dataset, to_dataset)
        from_dataset = find_dataset(from_dataset)
        to_dataset = find_dataset(to_dataset)
        column = if col.is_a?(String)
                   from_dataset.find_column_by_id(col)
                 else
                   from_dataset.find_column(col)
                 end
        fail "Column #{col} cannot be found in dataset #{from_dataset.id}" unless column
        stuff = case column.type
                when :attribute
                  [column] + column.labels
                when :fact
                  [column]
                when :reference
                  [column]
                else
                  fail 'Duplicate does not support moving #{col.type} type of field'
                end
        stuff = stuff.map(&:data)
        stuff.each { |c| remove_column!(from_dataset, c[:id]) }
        stuff.each { |c| add_column!(to_dataset, c) }
        self
      end

      def duplicate!(col, from_dataset, to_dataset)
        from_dataset = find_dataset(from_dataset)
        to_dataset = find_dataset(to_dataset)
        column = if col.is_a?(String)
                   from_dataset.find_column_by_id(col)
                 else
                   from_dataset.find_column(col)
                 end
        fail "Column #{col} cannot be found in dataset #{from_dataset.id}" unless column
        stuff = case column.type
                when :attribute
                  [column] + column.labels
                when :fact
                  [column]
                when :reference
                  [column]
                else
                  fail 'Duplicate does not support moving #{col.type} type of field'
                end
        stuff.map(&:data).each { |c| add_column!(to_dataset, c) }
        self
      end

      # Returns list of attributes from all the datasets in a blueprint
      #
      # @return [Array<Hash>]
      def attributes
        datasets.reduce([]) { |a, e| a.concat(e.attributes) }
      end

      # Returns list of attributes and anchors from all the datasets in a blueprint
      #
      # @return [Array<Hash>]
      def attributes_and_anchors
        datasets.mapcat(&:attributes_and_anchors)
      end

      # Is this a project blueprint?
      #
      # @return [Boolean] if it is
      def project_blueprint?
        true
      end

      # Returns list of date dimensions
      #
      # @return [Array<Hash>]
      def date_dimensions
        ProjectBlueprint.date_dimensions(self).map { |dd| GoodData::Model::DateDimension.new(dd, self) }
      end

      # Returns true if a dataset contains a particular dataset false otherwise
      #
      # @param name [GoodData::Model::DatasetBlueprint | String | Hash] Dataset
      # @return [Boolean]
      def dataset?(name, options = {})
        ProjectBlueprint.dataset?(to_hash, name, options)
      end

      # Returns SLI manifest for one dataset. This is used by our API to allow
      # loading data. The method is on project blueprint because you need
      # acces to whole project to be able to generate references
      #
      # @param dataset [GoodData::Model::DatasetBlueprint | Hash | String] Dataset
      # @param mode [String] Method of loading. FULL or INCREMENTAL
      # @return [Array<Hash>] a title
      def dataset_to_manifest(dataset, mode = 'FULL')
        ToManifest.dataset_to_manifest(self, dataset, mode)
      end

      # Duplicated blueprint
      #
      # @param a_blueprint [GoodData::Model::DatasetBlueprint] Dataset blueprint to be merged
      # @return [GoodData::Model::DatasetBlueprint]
      def dup
        ProjectBlueprint.new(GoodData::Helpers.deep_dup(data))
      end

      # Returns list of facts from all the datasets in a blueprint
      #
      # @return [Array<Hash>]
      def facts
        datasets.mapcat(&:facts)
      end

      # Returns list of fields from all the datasets in a blueprint
      #
      # @return [Array<Hash>]
      def fields
        datasets.flat_map(&:fields)
      end

      # Returns dataset specified. It can check even for a date dimension
      #
      # @param name [GoodData::Model::DatasetBlueprint | String | Hash] Dataset
      # @param options [Hash] options
      # @return [GoodData::Model::DatasetBlueprint]
      def find_dataset(name, options = {})
        ds = datasets(name, options)
        fail "Dataset \"#{name}\" could not be found" unless ds
        ds
      end

      # Returns a dataset of a given name. If a dataset is not found it throws an exeception
      #
      # @param project [String] Dataset title
      # @return [Array<Hash>]
      def find_dataset_by_title(title)
        ds = ProjectBlueprint.find_dataset_by_title(to_hash, title)
        DatasetBlueprint.new(ds)
      end

      # Return list of datasets that are centers of the stars in datamart.
      # This means these datasets are not referenced by anybody else
      # In a good blueprint design these should be fact tables
      #
      # @return [Array<Hash>]
      def find_star_centers
        datasets.select { |d| d.referenced_by.empty? }
      end

      # Constructor
      #
      # @param init_data [ProjectBlueprint | Hash] Blueprint or a blueprint definition. If passed a hash it is used as data for new instance. If there is a ProjectBlueprint passed it is duplicated and a new instance is created.
      # @return [ProjectBlueprint] A new project blueprint instance
      def initialize(init_data)
        some_data = if init_data.respond_to?(:project_blueprint?) && init_data.project_blueprint?
                      init_data.to_hash
                    elsif init_data.respond_to?(:to_blueprint)
                      init_data.to_blueprint.to_hash
                    else
                      init_data
                    end
        @data = GoodData::Helpers.symbolize_keys(GoodData::Helpers.deep_dup(some_data))
        (@data[:datasets] || []).each do |d|
          d[:type] = d[:type].to_sym
          d[:columns].each do |c|
            c[:type] = c[:type].to_sym
          end
        end
        (@data[:date_dimensions] || []).each do |d|
          d[:type] = d[:type].to_sym
        end
      end

      def id
        data[:id]
      end

      # Returns list of labels from all the datasets in a blueprint
      #
      # @return [Array<Hash>]
      def labels
        datasets.mapcat(&:labels)
      end

      # Experimental but a basis for automatic check of health of a project
      #
      # @param project [GoodData::Model::DatasetBlueprint | Hash | String] Dataset blueprint
      # @return [Array<Hash>]
      def lint(full = false)
        errors = []
        find_star_centers.each do |dataset|
          next unless dataset.anchor?
          errors << {
            type: :anchor_on_fact_dataset,
            dataset_name: dataset.name,
            anchor_name: dataset.anchor[:name]
          }
        end
        date_facts = datasets.mapcat(&:date_facts)
        date_facts.each do |date_fact|
          errors << {
            type: :date_fact,
            date_fact: date_fact[:name]
          }
        end

        unique_titles = fields.map { |f| Model.title(f) }.uniq
        (fields.map { |f| Model.title(f) } - unique_titles).each do |duplicate_title|
          errors << {
            type: :duplicate_title,
            title: duplicate_title
          }
        end

        datasets.select(&:wide?).each do |wide_dataset|
          errors << {
            type: :wide_dataset,
            dataset: wide_dataset.name
          }
        end

        if full
          # GoodData::Attributes.all(:full => true).select { |attr| attr.used_by}
        end
        errors
      end

      # Merging two blueprints. The self blueprint is changed in place
      #
      # @param a_blueprint [GoodData::Model::DatasetBlueprint] Dataset blueprint to be merged
      # @return [GoodData::Model::ProjectBlueprint]
      def merge!(a_blueprint)
        temp_blueprint = merge(a_blueprint)
        @data = temp_blueprint.data
        self
      end

      # Returns list of datasets which are referenced by given dataset. This can be
      # optionally switched to return even date dimensions
      #
      # @param project [GoodData::Model::DatasetBlueprint | Hash | String] Dataset blueprint
      # @return [Array<Hash>]
      def referenced_by(dataset)
        find_dataset(dataset, include_date_dimensions: true).referencing
      end

      def referencing(dataset)
        datasets(:all, include_date_dimensions: true)
          .flat_map(&:references)
          .select { |r| r.dataset == dataset }
          .map(&:dataset_blueprint)
      end

      # Removes dataset from blueprint. Dataset can be given as either a name
      # or a DatasetBlueprint or a Hash representation.
      #
      # @param dataset_name [GoodData::Model::DatasetBlueprint | String | Hash] Dataset to be removed
      # @return [Hash] project with removed dataset
      def remove_dataset(dataset_name)
        ProjectBlueprint.remove_dataset(to_hash, dataset_name)
        self
      end

      # Removes dataset from blueprint. Dataset can be given as either a name
      # or a DatasetBlueprint or a Hash representation.
      #
      # @param dataset_name [GoodData::Model::DatasetBlueprint | String | Hash] Dataset to be removed
      # @return [Hash] project with removed dataset
      def remove_dataset!(dataset_id)
        ProjectBlueprint.remove_dataset!(to_hash, dataset_id)
        self
      end

      # Removes all the labels from the anchor. This is a typical operation that people want to
      # perform on fact tables
      #
      # @return [GoodData::Model::ProjectBlueprint] Returns changed blueprint
      def strip_anchor!(dataset)
        from_dataset = find_dataset(dataset)
        stuff = dataset.anchor.labels.map(&:data)
        stuff.each { |column| remove_column!(from_dataset, column[:id]) }
        self
      end

      # Returns some reports that might get you started. They are just simple
      # reports. Currently it is implemented by getting facts from star centers
      # and randomly picking attributes form referenced datasets.
      #
      # @return [Array<Hash>]
      def suggest_reports(options = {})
        strategy = options[:strategy] || :stupid
        case strategy
        when :stupid
          reports = suggest_metrics.reduce([]) do |a, e|
            star, metrics = e
            metrics.each(&:save)
            reports_stubs = metrics.map do |m|
              breaks = broken_by(star).map { |ds, aM| ds.identifier_for(aM) }
              [breaks, m]
            end
            a.concat(reports_stubs)
          end
          reports.reduce([]) do |a, e|
            attrs, metric = e

            attrs.each do |attr|
              a << GoodData::Report.create(:title => 'Fantastic report',
                                           :top => [attr],
                                           :left => metric)
            end
            a
          end
        end
      end

      # Returns some metrics that might get you started. They are just simple
      # reports. Currently it is implemented by getting facts from star centers
      # and randomly picking attributes form referenced datasets.
      #
      # @return [Array<Hash>]
      def suggest_metrics
        stars = find_star_centers
        metrics = stars.map(&:suggest_metrics)
        stars.zip(metrics)
      end

      def to_blueprint
        self
      end

      def refactor_split_df(dataset)
        fail ValidationError unless valid?
        o = find_dataset(dataset)
        new_dataset = GoodData::Model::DatasetBlueprint.new({ type: :dataset, id: "#{o.id}_dim", columns: [] }, self)
        new_dataset.change do |d|
          d.add_anchor('vymysli_id')
          d.add_label('label.vymysli_id', reference: 'vymysli_id')
        end
        nb = merge(new_dataset.to_blueprint)
        o.attributes.each { |a| nb.move!(a, o, new_dataset.id) }
        old = nb.find_dataset(dataset)
        old.attributes.each do |a|
          remove_column!(old, a)
        end
        old.change do |d|
          d.add_reference(new_dataset.id)
        end
        nb
      end

      def refactor_split_facts(dataset, column_names, new_dataset_title)
        fail ValidationError unless valid?
        change do |p|
          p.add_dataset(new_dataset_title) do |d|
            d.add_anchor("#{new_dataset_title}.id")
          end
        end
        dataset_to_refactor = find_dataset(dataset)
        new_dataset = find_dataset(new_dataset_title)
        column_names.each { |c| move!(c, dataset_to_refactor, new_dataset) }
        dataset_to_refactor.references.each { |ref| duplicate!(ref, dataset_to_refactor, new_dataset) }
        self
      end

      # Merging two blueprints. A new blueprint is created. The self one
      # is nto mutated
      #
      # @param a_blueprint [GoodData::Model::DatasetBlueprint] Dataset blueprint to be merged
      # @return [GoodData::Model::ProjectBlueprint]
      def merge(a_blueprint)
        temp_blueprint = dup
        return temp_blueprint unless a_blueprint
        a_blueprint.datasets.each do |dataset|
          if temp_blueprint.dataset?(dataset.id)
            local_dataset = temp_blueprint.find_dataset(dataset.id)
            index = temp_blueprint.datasets.index(local_dataset)
            local_dataset.merge!(dataset)
            temp_blueprint.remove_dataset!(local_dataset.id)
            temp_blueprint.add_dataset!(local_dataset, index)
          else
            temp_blueprint.add_dataset!(dataset.dup)
          end
        end
        a_blueprint.date_dimensions.each do |dd|
          if temp_blueprint.dataset?(dd.id, dd: true)
            local_dim = temp_blueprint.find_dataset(dd.id, dd: true)
            fail "Unable to merge date dimensions #{dd.id} with defintion #{dd.data} with #{local_dim.data}" unless local_dim.data == dd.data
          else
            temp_blueprint.add_date_dimension!(dd.dup)
          end
        end
        temp_blueprint
      end

      # Helper for storing the project blueprint into a file as JSON.
      #
      # @param filename [String] Name of the file where the blueprint should be stored
      def store_to_file(filename)
        File.open(filename, 'w') do |f|
          f << JSON.pretty_generate(to_hash)
        end
      end

      # Returns title of a dataset. If not present it is generated from the name
      #
      # @return [String] a title
      def title
        Model.title(to_hash) if to_hash[:title]
      end

      # Returns title of a dataset. If not present it is generated from the name
      #
      # @return [String] a title
      def title=(a_title)
        @data[:title] = a_title
      end

      # Returns Wire representation. This is used by our API to generate and
      # change projects
      #
      # @return [Hash] a title
      def to_wire
        validate
        ToWire.to_wire(data)
      end

      # Returns SLI manifest representation. This is used by our API to allow
      # loading data
      #
      # @return [Array<Hash>] a title
      def to_manifest
        validate
        ToManifest.to_manifest(to_hash)
      end

      # Returns hash representation of blueprint
      #
      # @return [Hash] a title
      def to_hash
        @data
      end

      # Validate the blueprint in particular if all references reference existing datasets and valid fields inside them.
      #
      # @return [Array] array of errors
      def validate_references
        stuff = datasets(:all, include_date_dimensions: true).flat_map(&:references).select do |ref|
          begin
            ref.dataset
            false
          rescue RuntimeError
            true
          end
        end
        stuff.map { |r| { type: :bad_reference, reference: r.data, referencing_dataset: r.data[:dataset] } }
      end

      # Validate the blueprint and all its datasets return array of errors that are found.
      #
      # @return [Array] array of errors
      def validate
        errors = []
        errors.concat validate_references
        errors.concat datasets.reduce([]) { |a, e| a.concat(e.validate) }
        errors.concat datasets.reduce([]) { |a, e| a.concat(e.validate_gd_data_type_errors) }
        errors
      rescue
        raise GoodData::ValidationError
      end

      # Validate the blueprint and all its datasets and return true if model is valid. False otherwise.
      #
      # @return [Boolean] is model valid?
      def valid?
        validate.empty?
      end

      def ==(other)
        # to_hash == other.to_hash
        return false unless id == other.id
        return false unless title == other.title
        left = to_hash[:datasets].map { |d| d[:columns].to_set }.to_set
        right = other.to_hash[:datasets].map { |d| d[:columns].to_set }.to_set
        return false unless left == right
        true
      end
    end
  end
end
