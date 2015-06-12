# encoding: UTF-8

module GoodData
  module Model
    class SchemaBuilder
      attr_accessor :data

      class << self
        def create_from_data(blueprint)
          sc = SchemaBuilder.new
          sc.data = blueprint.to_hash
          sc
        end

        def create(id, options = {}, &block)
          pb = SchemaBuilder.new(id, options)
          block.call(pb)
          pb
        end
      end

      def initialize(id = nil, options = {})
        @data = {
          id: id,
          type: :dataset,
          columns: []
        }.merge(options)
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

      def add_anchor(id, options = {})
        add_column({ type: :anchor, id: id }.merge(options))
        self
      end

      def add_attribute(id, options = {})
        add_column({ type: :attribute, id: id }.merge(options))
        self
      end

      def add_fact(id, options = {})
        data = { type: :fact, id: id }.merge(options)
        add_column(data)
        self
      end

      def add_label(id, options = {})
        add_column({ type: :label, id: id }.merge(options))
        self
      end

      def add_date(dataset_id, options = {})
        add_column({ type: :date, dataset: dataset_id, format: GoodData::Model::DEFAULT_DATE_FORMAT }.merge(options))
      end

      def add_reference(dataset, options = {})
        add_column({ type: :reference, dataset: dataset }.merge(options))
      end

      def to_json
        JSON.pretty_generate(to_hash)
      end

      def to_hash
        data
      end

      def to_blueprint
        GoodData::Model::ProjectBlueprint.new(datasets: [to_hash])
      end
    end
  end
end
