# encoding: UTF-8

module GoodData
  module Model
    class ProjectBlueprint
      attr_accessor :data

      def self.from_json(spec)
        if spec.is_a?(String)
          ProjectBlueprint.new(MultiJson.load(File.read(spec), :symbolize_keys => true))
        else
          ProjectBlueprint.new(spec)
        end
      end

      def change(&block)
        builder = ProjectBuilder.create_from_data(self)
        block.call(builder)
        @data = builder.to_hash
        self
      end

      def datasets
        data[:datasets].map { |d| DatasetBlueprint.new(d) }
      end

      def add_dataset(a_dataset, index = nil)
        if index.nil? || index > datasets.length
          data[:datasets] << a_dataset.to_hash
        else
          data[:datasets].insert(index, a_dataset.to_hash)
        end
      end

      def remove_dataset(dataset_name)
        dataset = dataset_name.is_a?(String) ? find_dataset(dataset_name) : dataset_name
        index = data[:datasets].index(dataset)
        data[:datasets].delete_at(index)
      end

      def date_dimensions
        data[:date_dimensions]
      end

      def dataset?(name)
        found = data[:datasets].find { |d| d[:name] == name }
        found != nil
      end

      def find_dataset(name)
        ds = data[:datasets].find { |d| d[:name] == name }
        fail "Dataset #{name} could not be found" if ds.nil?
        DatasetBlueprint.new(ds)
      end

      def initialize(init_data)
        @data = init_data
      end

      def validate_references
        if datasets.count == 1
          []
        else
          x = datasets.reduce([]) { |a, e| e.anchor? ? a << [e.name, e.anchor[:name]] : a }
          refs = datasets.reduce([]) do |a, e|
            a.concat(e.references)
          end
          refs.reduce([]) do |a, e|
            x.include?([e[:dataset], e[:reference]]) ? a : a.concat([e])
          end
        end
      end

      def validate_labels_references
        datasets.reduce([]) { |a, e| a.concat(e.validate_label_references) }
      end

      def validate_model
        refs_errors = validate_references
        labels_errors = validate_labels_references
        refs_errors.concat(labels_errors)
      end

      def model_valid?
        refs_errors = validate_references
        labels_errors = validate_labels_references
        errors = refs_errors.concat(labels_errors)
        errors.empty? ? true : false
      end

      def referenced_by(dataset)
        dataset = find_dataset(dataset) if dataset.is_a?(String)
        dataset.references.map do |ds|
          find_dataset(ds[:dataset])
        end
      end

      def attributes
        datasets.reduce([]) { |a, e| a.concat(e.attributes) }
      end

      def attributes_and_anchors
        datasets.reduce([]) { |a, e| a.concat(e.attributes_and_anchors) }
      end

      def labels
        datasets.reduce([]) { |a, e| a.concat(e.labels) }
      end

      def facts
        datasets.reduce([]) { |a, e| a.concat(e.facts) }
      end

      def can_break(dataset)
        dataset = find_dataset(dataset) if dataset.is_a?(String)
        referenced_by(dataset).reduce([]) do |a, e|
          e.attributes_and_anchors.each do |attr|
            a.push([e, attr])
          end
          a
        end
      end

      def find_star_centers
        referenced = datasets.map { |d| referenced_by(d) }
        referenced.flatten!
        res = datasets.map(&:to_hash) - referenced.map(&:to_hash)
        res.map { |d| DatasetBlueprint.new(d) }
      end

      def suggest_reports(options = {})
        strategy = options[:strategy] || :stupid
        case strategy
        when :stupid
          reports = suggest_metrics.reduce([]) do |a, e|
            star, metrics = e
            metrics.each { |m| m.save }
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
              a << GoodData::Report.create(
                    :title => 'Fantastic report',
                    :top => [attr],
                    :left => metric)
            end
            a
          end
        end
      end

      def suggest_metrics
        stars = find_star_centers
        metrics = stars.map { |s| s.suggest_metrics }
        stars.zip(metrics)
      end

      def merge!(a_blueprint)
        temp_blueprint = merge(a_blueprint)
        @data = temp_blueprint.data
        self
      end

      def merge(a_blueprint)
        temp_blueprint = dup
        a_blueprint.datasets.each do |dataset|
          if temp_blueprint.dataset?(dataset.name)
            local_dataset = temp_blueprint.find_dataset(dataset.name)
            index = temp_blueprint.datasets.index(local_dataset)
            local_dataset.merge!(dataset)
            temp_blueprint.remove_dataset(local_dataset.name)
            temp_blueprint.add_dataset(local_dataset, index)
          else
            temp_blueprint.add_dataset(dataset.dup)
          end
        end
        temp_blueprint
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
                'dateDimensions' => date_dimensions.map do |d|
                  {
                    'dateDimension' => {
                      'name' => d[:name],
                      'title' => d[:title] || d[:name].humanize
                    }
                  }
                end
              }
            }
          }
        }
      end

      def to_hash
        @data
      end
    end
  end
end
