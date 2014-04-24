# encoding: UTF-8

require_relative 'schema_builder'

module GoodData
  module Model
    class SchemaBlueprint
      attr_accessor :data

      def change(&block)
        builder = SchemaBuilder.create_from_data(self)
        block.call(builder)
        @data = builder.to_hash
        self
      end

      def initialize(init_data)
        @data = init_data
      end

      def upload(source, options = {})
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

      def anchor?
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

      def attributes_and_anchors
        attributes + [anchor]
      end

      def find_column_by_type(type, all = :all)
        type = type.to_s
        if all == :all
          columns.select { |c| c[:type].to_s == type }
        else
          columns.find { |c| c[:type].to_s == type }
        end
      end

      def find_column_by_name(type, all = :all)
        type = type.to_s
        if all == :all
          columns.select { |c| c[:name].to_s == type }
        else
          columns.find { |c| c[:name].to_s == type }
        end
      end

      def suggest_metrics
        identifiers = facts.map { |f| identifier_for(f) }
        identifiers.zip(facts).map do |id, fact|
          Metric.xcreate(
            :title => fact[:name].titleize,
            :expression => "SELECT SUM(![#{id}])")
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
        printer.text columns.map do |c|
          "  #{c[:name]}: #{c[:type]}"
        end.join("\n")
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

      def eql?(other)
        to_hash == other.to_hash
      end

      def identifier_for(column)
        column = find_column_by_name(column) if column.is_a?(String)
        case column[:type].to_sym
        when :attribute
          "attr.#{name}.#{column[:name]}"
        when :anchor
          "attr.#{name}.#{column[:name]}"
        when :fact
          "fact.#{name}.#{column[:name]}"
        end
      end
    end
  end
end
