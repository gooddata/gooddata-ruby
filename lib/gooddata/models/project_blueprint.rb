# encoding: UTF-8

module GoodData
  module Model
    class ProjectBlueprint
      attr_accessor :data

      def self.from_json(spec)
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

      def referenced_by(dataset)
        dataset = get_dataset(dataset) if dataset.is_a?(String)
        dataset.references.map do |ds|
          get_dataset(ds[:dataset])
        end
      end

      def can_break(dataset)
        dataset = get_dataset(dataset) if dataset.is_a?(String)
        referenced_by(dataset).reduce([]) do |memo, ds|
          ds.attributes_and_anchors.each do |attr|
            memo.push([ds, attr])
          end
          memo
        end
      end

      def find_star_centers
        referenced = datasets.map {|d| referenced_by(d)}
        referenced.flatten!
        res = datasets.map(&:to_hash) - referenced.map(&:to_hash)
        res.map {|d| SchemaBlueprint.new(d)}
      end

      def suggest_reports(options = {})
        strategy = options[:strategy] || :stupid
        case strategy
        when :stupid
          reports = suggest_metrics.reduce([]) do |memo, items|
            star, metrics = items
            metrics.each {|m| m.save}
            reports_stubs = metrics.map do |m|
              breaks = can_break(star).map {|ds, a| ds.identifier_for(a)}
              # [breaks.sample((breaks.length/10.0).ceil), m]
              [breaks, m]
            end
            memo.concat(reports_stubs)
          end
          reports.reduce([]) do |memo, items|
            attrs, metric = items

            attrs.each do |a|
              memo << GoodData::Report.create(
                    :title => "Fantastic report",
                    :top => [a],
                    :left => metric)
            end
            memo
          end
        end
      end

      def suggest_metrics
        stars = find_star_centers
        metrics = stars.map {|s| s.suggest_metrics}
        stars.zip(metrics)
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
  end
end