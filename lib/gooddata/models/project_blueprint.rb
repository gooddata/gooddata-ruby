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
  end
end