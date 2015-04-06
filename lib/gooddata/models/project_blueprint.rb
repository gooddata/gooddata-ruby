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

      # Removes dataset from blueprint. Dataset can be given as either a name
      # or a DatasetBlueprint or a Hash representation.
      #
      # @param project [Hash] Project blueprint
      # @param dataset_name [GoodData::Model::DatasetBlueprint | String | Hash] Dataset to be removed
      # @return [Hash] project with removed dataset
      def self.remove_dataset(project, dataset_name)
        dataset = dataset_name.is_a?(String) ? find_dataset(project, dataset_name) : dataset_name
        index = project[:datasets].index(dataset)
        dupped_project = project.deep_dup
        dupped_project[:datasets].delete_at(index)
        dupped_project
      end

      # Removes dataset from blueprint. Dataset can be given as either a name
      # or a DatasetBlueprint or a Hash representation. This version mutates
      # the dataset in place
      #
      # @param project [Hash] Project blueprint
      # @param dataset_name [GoodData::Model::DatasetBlueprint | String | Hash] Dataset to be removed
      # @return [Hash] project with removed dataset
      def self.remove_dataset!(project, dataset_name)
        dataset = dataset_name.is_a?(String) ? find_dataset(project, dataset_name) : dataset_name
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
      def self.datasets(project, options = {})
        include_date_dimensions = options[:include_date_dimensions] || options[:dd]
        ds = (project.to_hash[:datasets] || [])
        if include_date_dimensions
          ds + date_dimensions(project)
        else
          ds
        end
      end

      # Returns true if a dataset contains a particular dataset false otherwise
      #
      # @param project [GoodData::Model::ProjectBlueprint | Hash] Project blueprint
      # @param name [GoodData::Model::DatasetBlueprint | String | Hash] Dataset
      # @return [Boolean]
      def self.dataset?(project, name)
        find_dataset(project, name)
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
      def self.find_dataset(project, obj, options = {})
        include_date_dimensions = options[:include_date_dimensions] || options[:dd]
        return obj.to_hash if DatasetBlueprint.dataset_blueprint?(obj)
        all_datasets = if include_date_dimensions
                         datasets(project) + date_dimensions(project)
                       else
                         datasets(project)
                       end
        name = obj.respond_to?(:key?) ? obj[:name] : obj
        ds = all_datasets.find { |d| d[:name] == name }
        fail "Dataset #{name} could not be found" if ds.nil?
        ds
      end

      # Returns list of date dimensions
      #
      # @param project [GoodData::Model::ProjectBlueprint | Hash] Project blueprint
      # @return [Array<Hash>]
      def self.date_dimensions(project)
        project.to_hash[:date_dimensions] || []
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
        ds = date_dimensions(project).find { |d| d[:name] == name }
        fail "Date dimension #{name} could not be found" if ds.nil?
        ds
      end

      # Returns fields from all datasets
      #
      # @param project [GoodData::Model::ProjectBlueprint | Hash] Project blueprint
      # @return [Array<Hash>]
      def self.fields(project)
        datasets(project).mapcat { |d| DatasetBlueprint.fields(d) }
      end

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
      def datasets(options = {})
        ProjectBlueprint.datasets(to_hash, options).map { |d| DatasetBlueprint.new(d) }
      end

      def add_dataset!(a_dataset, index = nil)
        if index.nil? || index > datasets.length
          data[:datasets] << a_dataset.to_hash
        else
          data[:datasets].insert(index, a_dataset.to_hash)
        end
      end

      # Removes dataset from blueprint. Dataset can be given as either a name
      # or a DatasetBlueprint or a Hash representation.
      #
      # @param dataset_name [GoodData::Model::DatasetBlueprint | String | Hash] Dataset to be removed
      # @return [Hash] project with removed dataset
      def remove_dataset(dataset_name)
        ProjectBlueprint.remove_dataset(to_hash, dataset_name)
      end

      # Removes dataset from blueprint. Dataset can be given as either a name
      # or a DatasetBlueprint or a Hash representation.
      #
      # @param dataset_name [GoodData::Model::DatasetBlueprint | String | Hash] Dataset to be removed
      # @return [Hash] project with removed dataset
      def remove_dataset!(dataset_name)
        ProjectBlueprint.remove_dataset!(to_hash, dataset_name)
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
        ProjectBlueprint.date_dimensions(to_hash)
      end

      # Returns true if a dataset contains a particular dataset false otherwise
      #
      # @param name [GoodData::Model::DatasetBlueprint | String | Hash] Dataset
      # @return [Boolean]
      def dataset?(name)
        ProjectBlueprint.dataset?(to_hash, name)
      end

      # Returns dataset specified. It can check even for a date dimension
      #
      # @param name [GoodData::Model::DatasetBlueprint | String | Hash] Dataset
      # @param options [Hash] options
      # @return [GoodData::Model::DatasetBlueprint]
      def find_dataset(name, options = {})
        DatasetBlueprint.new(ProjectBlueprint.find_dataset(to_hash, name, options))
      end

      # Returns a dataset of a given name. If a dataset is not found it throws an exeception
      #
      # @param project [String] Dataset title
      # @return [Array<Hash>]
      def find_dataset_by_title(title)
        ds = ProjectBlueprint.find_dataset_by_title(to_hash, title)
        DatasetBlueprint.new(ds)
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
        @data = some_data.deep_dup
      end

      # Validate the blueprint in particular if all references reference existing datasets and valid fields inside them.
      #
      # @return [Array] array of errors
      def validate_references
        if datasets.count == 1
          []
        else
          x = datasets.reduce([]) { |a, e| e.anchor? ? a << [e.name] : a } + date_dimensions.map { |y| [y[:name]] }
          refs = datasets.reduce([]) do |a, e|
            a.concat(e.references)
          end
          refs.reduce([]) do |a, e|
            x.include?([e[:dataset]]) ? a : a.concat([e])
          end
        end
      end

      # Validate the blueprint and all its datasets return array of errors that are found.
      #
      # @return [Array] array of errors
      def validate
        refs_errors = validate_references
        labels_errors = datasets.reduce([]) { |a, e| a.concat(e.validate) }
        refs_errors.concat(labels_errors)
      end

      # Validate the blueprint and all its datasets and return true if model is valid. False otherwise.
      #
      # @return [Boolean] is model valid?
      def valid?
        validate.empty?
      end

      # Returns list of datasets which are referenced by given dataset. This can be
      # optionally switched to return even date dimensions
      #
      # @param project [GoodData::Model::DatasetBlueprint | Hash | String] Dataset blueprint
      # @return [Array<Hash>]
      def referenced_by(dataset)
        find_dataset(dataset, include_date_dimensions: true).references.map do |ref|
          find_dataset(ref[:dataset], include_date_dimensions: true)
        end
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

      # Returns list of labels from all the datasets in a blueprint
      #
      # @return [Array<Hash>]
      def labels
        datasets.mapcat(&:labels)
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
        ProjectBlueprint.fields(to_hash)
      end

      # Returns list of attributes that can break facts in a given dataset.
      # This basically means that it is giving you all attributes from the
      # datasets that are references by given dataset. Currently does not
      # work transitively
      #
      # @param project [GoodData::Model::DatasetBlueprint | Hash | String] Dataset blueprint
      # @return [Array<Hash>]
      def can_break(dataset)
        dataset = find_dataset(dataset) if dataset.is_a?(String)
        (referenced_by(dataset) + [dataset]).mapcat do |ds|
          ds.attributes_and_anchors.map do |attr|
            [ds, attr]
          end
        end
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

      # Return list of datasets that are centers of the stars in datamart.
      # This means these datasets are not referenced by anybody else
      # In a good blueprint design these should be fact tables
      #
      # @return [Array<Hash>]
      def find_star_centers
        referenced = datasets.mapcat { |d| referenced_by(d) }
        referenced.flatten!
        res = datasets.map(&:to_hash) - referenced.map(&:to_hash)
        res.map { |d| DatasetBlueprint.new(d) }
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
              breaks = can_break(star).map { |ds, aM| ds.identifier_for(aM) }
              # [breaks.sample((breaks.length/10.0).ceil), m]
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

      # Merging two blueprints. The self blueprint is changed in place
      #
      # @param a_blueprint [GoodData::Model::DatasetBlueprint] Dataset blueprint to be merged
      # @return [GoodData::Model::ProjectBlueprint]
      def merge!(a_blueprint)
        temp_blueprint = merge(a_blueprint)
        @data = temp_blueprint.data
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
          if temp_blueprint.dataset?(dataset.name)
            local_dataset = temp_blueprint.find_dataset(dataset.name)
            index = temp_blueprint.datasets.index(local_dataset)
            local_dataset.merge!(dataset)
            temp_blueprint.remove_dataset!(local_dataset.name)
            temp_blueprint.add_dataset!(local_dataset, index)
          else
            temp_blueprint.add_dataset!(dataset.dup)
          end
        end
        temp_blueprint
      end

      # Duplicated blueprint
      #
      # @param a_blueprint [GoodData::Model::DatasetBlueprint] Dataset blueprint to be merged
      # @return [GoodData::Model::DatasetBlueprint]
      def dup
        ProjectBlueprint.new(data.deep_dup)
      end

      # Returns title of a dataset. If not present it is generated from the name
      #
      # @return [String] a title
      def title
        Model.title(to_hash)
      end

      # Returns Wire representation. This is used by our API to generate and
      # change projects
      #
      # @return [Hash] a title
      def to_wire
        ToWire.to_wire(data)
      end

      # Returns SLI manifest representation. This is used by our API to allow
      # loading data
      #
      # @return [Array<Hash>] a title
      def to_manifest
        ToManifest.to_manifest(to_hash)
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

      # Returns hash representation of blueprint
      #
      # @return [Hash] a title
      def to_hash
        @data
      end

      def ==(other)
        to_hash == other.to_hash
      end

      def eql?(other)
        to_hash == other.to_hash
      end
    end
  end
end
