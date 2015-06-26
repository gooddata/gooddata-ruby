# encoding: UTF-8

module GoodData
  module Model
    class SchemaBlueprint
      attr_accessor :data, :project_blueprint

      def initialize(dim, blueprint)
        @data = dim
        @project_blueprint = blueprint
      end

      # Returns true if anchor is present. Currently returns always true. Probably good to remove
      #
      # @return [Boolean] is anchor on schema?l70
      def anchor?
        true
      end

      # Returns anchor
      #
      # @return [GoodData::Model::AnchorBlueprintField] anchor on schema
      def anchor
        nil
      end

      # Returns list of all references defined on the schema.
      #
      # @return [Array<GoodData::Model::ReferenceBlueprintField>] refs on schema
      def references
        []
      end

      # Returns list of all facts defined on the schema.
      #
      # @return [Array<GoodData::Model::FactBlueprintField>] facts on schema
      def facts(_id = :all, _options = {})
        []
      end

      # Returns list of all attributes defined on the schema.
      #
      # @return [Array<GoodData::Model::AttributeBlueprintField>] attributes on schema
      def attributes(_id = :all, _options = {})
        []
      end

      # Returns list of all labels defined on the schema.
      #
      # @return [Array<GoodData::Model::LabelBlueprintField>] labels on schema
      def labels(_id = :all, _options = {})
        []
      end

      # Returns list of all fields defined on the schema.
      #
      # @return [Array<GoodData::Model::BlueprintField>] all fields on schema
      def fields
        []
      end

      # Returns list of attributes and anchor.
      #
      # @return [Array<GoodData::Model::AnchorBlueprintField | GoodData::Model::AttributeBlueprintField>]
      def attributes_and_anchors
        []
      end

      # Returns list of attributes that can break facts in a given dataset.
      # This basically means that it is giving you all attributes from this
      # dataset and datasets that are referenced by given dataset transitively.
      # Includes only anchors that have labels.
      #
      # @return [Array<GoodData::Model::BlueprintField>]
      def broken_by
        attrs = attributes_and_anchors.reject { |a| a.labels.empty? }
        attrs + references.map(&:dataset).flat_map(&:broken_by)
      end

      # Returns list of attributes that are broken by attributes in this dataset. This means
      # all anchors and attributes from this dataset and the ones that are referenced by any
      # dataset. It works transitively. Includes only anchors that have labels.
      #
      # @return [Array<GoodData::Model::AnchorBlueprintField | GoodData::Model::AttributeBlueprintField>]
      def breaks
        attrs = attributes_and_anchors.reject { |a| a.labels.empty? }
        referenced_by.empty? ? attrs : attrs + referenced_by.flat_map(&:breaks)
      end

      # Relays request on finding a dataset in the associated project blueprint. Used by reference fields
      #
      # @param dataset [String] Name of a dataset
      # @param options [Hash] additional options. See ProjectBlueprint form more
      # @return [GoodData::Model::DatasetBlueprint] returns matching dataset or throws an error
      def find_dataset(dataset, options = {})
        project_blueprint.find_dataset(dataset, options)
      end

      # Returns id of the schema
      #
      # @return [String] returns id
      def id
        data[:id]
      end

      # Returns dataset that are referencing this dataset (directly through references not transitively).
      #
      # @return [Array<GoodData::Model::SchemaBlueprint>] returns id
      def referenced_by
        @project_blueprint.referencing(self)
      end

      # Returns dataset that are referenced by this dataset (directly through references not transitively).
      #
      # @return [Array<GoodData::Model::SchemaBlueprint>] returns id
      def referencing
        references.map(&:dataset)
      end

      # Returns title of the dataset. If it is not set up. It is generated for you
      # based on the name which is titleized
      #
      # @return [String]
      def title
        data[:title] || GoodData::Helpers.titleize(data[:id])
      end

      # Validates the blueprint and returns true if model is valid. False otherwise.
      #
      # @return [Boolean] is model valid?
      def valid?
        validate.empty?
      end

      # Validates the blueprint and returns array of errors.
      #
      # @return [Array<Hash>] returns array of errors or empty array
      def validate
        fields.flat_map(&:validate)
      end

      # Compares two blueprints. This is done by comapring the hash represenatation.
      # It has to be exacty identical including the order of the columns
      #
      # @param name [GoodData::Model::DatasetBlueprint] Name of a field
      # @return [Boolean] matching fields
      def ==(other)
        to_hash == other.to_hash
      end

      def to_hash
        @data
      end
    end
  end
end
