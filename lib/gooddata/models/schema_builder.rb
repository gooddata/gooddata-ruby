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
      end

      def initialize(name = nil)
        @data = {
          name: name,
          columns: []
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

      def add_anchor(name, options = {})
        add_column({ type: :anchor, name: name }.merge(options))
        self
      end

      def add_attribute(name, options = {})
        add_column({ type: :attribute, name: name }.merge(options))
        self
      end

      def add_fact(name, options = {})
        add_column({ type: :fact, name: name }.merge(options))
        self
      end

      def add_label(name, options = {})
        add_column({ type: :label, name: name }.merge(options))
        self
      end

      def add_date(name, options = {})
        add_column({ type: :date, name: name, format: GoodData::Model::DEFAULT_DATE_FORMAT }.merge(options))
      end

      def add_reference(name, options = {})
        add_column({ type: :reference, name: name }.merge(options))
      end

      def to_json
        JSON.pretty_generate(to_hash)
      end

      def to_hash
        data
      end

      def to_blueprint
        GoodData::Model::DatasetBlueprint.new(to_hash)
      end
    end
  end
end
