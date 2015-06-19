# encoding: UTF-8

require_relative 'schema_builder'

module GoodData
  module Model
    class DatasetBlueprint
      attr_accessor :data
      # Checks if a dataset has an anchor.
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Boolean] returns true if dataset has an anchor
      def self.anchor?(dataset)
        columns(dataset).any? { |c| c[:type].to_s == 'anchor' }
      end

      # Returns anchor of a dataset
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Hash] returns the anchor or nil
      def self.anchor(dataset)
        find_column_by_type(dataset, :anchor, :first)
      end

      # Returns attributes of a dataset
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the attribute or an empty array
      def self.attributes(dataset)
        find_column_by_type(dataset, :attribute, :all)
      end

      # Returns all labels that is referenced by a label
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the labels or an empty array
      def self.attribute_for_label(dataset, label)
        find_column_by_type(dataset, [:attribute, :anchor], :all).find { |a| label[:reference] == a[:name] }
      end

      # Returns all the fields of a dataset. This means facts, attributes, references
      #
      # @param ds [Hash] Dataset blueprint
      # @return [Boolean]
      def self.columns(ds)
        ds[:columns] || []
      end
      singleton_class.send(:alias_method, :fields, :columns)

      # Tells you if the object is a dataset. It consumes both Hash represenation
      # or the GoodData::Model::DatasetBlueprint
      #
      # @param ds [Object] Value to be tested
      # @return [Boolean]
      def self.dataset_blueprint?(ds)
        if ds.is_a?(DatasetBlueprint)
          true
        elsif ds.respond_to?(:[]) && ds.is_a?(Hash) && ds[:type].to_sym == :dataset
          true
        else
          false
        end
      end

      # Returns date facts of a dataset
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the attribute or an empty array
      def self.date_facts(dataset)
        find_column_by_type(dataset, :date_fact, :all)
      end

      # Returns label that is marked as default for a particular attribtue.
      # This does not necessarily need to be the first one. This is a default label
      # in terms of what is displayed on the UI
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the labels or an empty array
      def self.default_label_for_attribute(dataset, attribute)
        default_label = labels_for_attribute(dataset, attribute).find { |l| l[:default_label] == true }
        default_label || attribute
      end

      # Returns facts of a dataset
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the attribute or an empty array
      def self.facts(dataset)
        find_column_by_type(dataset, [:fact, :date_fact], :all)
      end

      # Finds a specific column given a name
      #
      # @param dataset [Hash] Dataset blueprint
      # @param name [String] Name of a field
      # @param all [Symbol] if :all is passed all mathching objects are returned
      # Otherwise only the first one is
      # @return [Array<Hash>] matching fields
      def self.find_column_by_name(dataset, name, all = nil)
        if all == :all
          columns(dataset).select { |c| c[:name].to_s == name }
        else
          columns(dataset).find { |c| c[:name].to_s == name }
        end
      end

      # Returns all the fields of a specified type. You can specify more types
      # as an array if you need more than one type.
      #
      # @param dataset [Hash] Dataset blueprint
      # @param type [String | Symbol | Array[Symmbol] | Array[String]] Type or types you would like to get
      # @param all [Symbol] if :all is passed
      # as third parameter it return all object otherwise it returns the first one
      # @return [Array<Hash>] matching fields
      def self.find_column_by_type(dataset, type, all = nil)
        types = if type.is_a?(Enumerable)
                  type
                else
                  [type]
                end
        if all == :all
          columns(dataset).select { |c| types.any? { |t| t.to_s == c[:type].to_s } }
        else
          columns(dataset).find { |c| types.any? { |t| t.to_s == c[:type].to_s } }
        end
      end

      # Returns labels facts of a dataset
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the label or an empty array
      def self.labels(dataset)
        find_column_by_type(dataset, :label, :all)
      end

      # Returns labels for a particular attribute
      #
      # @param dataset [Hash] Dataset blueprint
      # @param attribute [Hash] Attribute
      # @return [Array<Hash>] returns the labels or an empty array
      def self.labels_for_attribute(dataset, attribute)
        labels(dataset).select { |l| l[:reference] == attribute[:name] }
      end

      # Returns references of a dataset
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the references or an empty array
      def self.references(dataset)
        find_column_by_type(dataset, [:reference, :date], :all)
      end

      # Returns anchor of a dataset
      #
      # @return [Hash] returns the anchor or nil
      def anchor
        find_column_by_type(:anchor, :first)
      end

      # Checks if a dataset has an anchor.
      #
      # @return [Boolean] returns true if dataset has an anchor
      def anchor?
        columns.any? { |c| c[:type].to_s == 'anchor' }
      end

      # Returns attributes of a dataset
      #
      # @return [Array<Hash>] returns the attribute or an empty array
      def attributes
        DatasetBlueprint.attributes(to_hash)
      end

      def attributes_and_anchors
        anchor? ? attributes + [anchor] : attributes
      end

      # Changes the dataset through a builder. You provide a block with an istance of
      # GoodData::Model::SchemaBuilder and you
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the labels or an empty array
      def change(&block)
        builder = SchemaBuilder.create_from_data(self)
        block.call(builder)
        @data = builder.to_hash
        self
      end

      # Returns all the fields of a dataset. This means facts, attributes, references
      #
      # @return [Boolean]
      def columns
        DatasetBlueprint.columns(to_hash)
      end
      alias_method :fields, :columns

      # Creates a metric which counts numnber of lines in dataset. Works for both
      # datasets with or without anchor
      #
      # @return [Boolean]
      def count(project)
        id = if anchor?
               GoodData::Model.identifier_for(to_hash, anchor)
             else
               GoodData::Model.identifier_for(to_hash, type: :anchor_no_label)
             end
        attribute = project.attributes(id)
        attribute.create_metric.execute
      end

      # Returns date facts of a dataset
      #
      # @return [Array<Hash>] returns the attribute or an empty array
      def date_facts
        DatasetBlueprint.date_facts(to_hash)
      end

      # Duplicates the DatasetBlueprint. It is done as a deep duplicate
      #
      # @return [GoodData::Model::DatasetBlueprint] matching fields
      def dup
        DatasetBlueprint.new(data.deep_dup)
      end

      # Compares two blueprints. This is done by comapring the hash represenatation.
      # It has to be exacty identical including the order of the columns
      #
      # @param name [GoodData::Model::DatasetBlueprint] Name of a field
      # @return [Boolean] matching fields
      def eql?(other)
        to_hash == other.to_hash
      end

      # Returns facts of a dataset
      #
      # @return [Array<Hash>] returns the attribute or an empty array
      def facts
        DatasetBlueprint.facts(to_hash)
      end

      # Finds a specific column given a name
      #
      # @param name [String] Name of a field
      # @param all [Symbol] if :all is passed all mathching objects are returned
      # Otherwise only the first one is
      # @return [Array<Hash>] matching fields
      def find_column_by_name(type, all = :all)
        DatasetBlueprint.find_column_by_name(to_hash, type, all)
      end

      # Returns all the fields of a specified type. You can specify more types
      # as an array if you need more than one type.
      #
      # @param type [String | Symbol | Array[Symmbol] | Array[String]] Type or types you would like to get
      # @param all [Symbol] if :all is passed
      # as third parameter it return all object otherwise it returns the first one
      # @return [Array<Hash>] matching fields
      def find_column_by_type(type, all = nil)
        DatasetBlueprint.find_column_by_type(to_hash, type, all)
      end

      # Returns identifier for dataset
      #
      # @return [String] identifier
      def identifier
        GoodData::Model.identifier_for(to_hash)
      end

      # Creates a DatasetBlueprint
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [DatasetBlueprint] returns the labels or an empty array
      def initialize(init_data)
        @data = init_data
      end

      # Returns labels facts of a dataset
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the label or an empty array
      def labels
        DatasetBlueprint.labels(to_hash)
      end

      # Merges two schemas together. This method changes the blueprint
      # in place. If you would prefer the method that generates a new blueprint
      # use merge method
      #
      # @param a_blueprint [GoodData::Model::DatasetBlueprint] Dataset blueprint to be merged
      # @return [GoodData::Model::DatasetBlueprint] returns itself changed
      def merge!(a_blueprint)
        new_blueprint = GoodData::Model.merge_dataset_columns(self, a_blueprint)
        @data = new_blueprint
        self
      end

      # Returns name of the dataset
      #
      # @return [String]
      def name
        data[:name]
      end

      # Returns references of a dataset
      #
      # @return [Array<Hash>] returns the references or an empty array
      def references
        DatasetBlueprint.references(to_hash)
      end

      # Method for suggest a couple of metrics that might get you started
      # Idea is that we will provide couple of strategies. Currently the metrics
      # are created in the random way but they should work.
      #
      # @return [Array<GoodData::Metric>] matching fields
      def suggest_metrics
        identifiers = facts.map { |f| identifier_for(f) }
        identifiers.zip(facts).map do |id, fact|
          Metric.xcreate(
            :title => fact[:name].titleize,
            :expression => "SELECT SUM(![#{id}])")
        end
      end

      # Returns title of the dataset. If it is not set up. It is generated for you
      # based on the name which is titleized
      #
      # @return [String]
      def title
        data[:title] || name.titleize
      end

      # Returns hash representation which is much better suited for processing
      #
      # @return [Hash]
      def to_hash
        data
      end

      # Validate the blueprint return array of errors that are found.
      #
      # @return [Array] array of errors
      def validate
        more_than_one_anchor = find_column_by_type(:anchor, :all).count > 1 ? [{ :anchor => 2 }] : []
        validate_label_references.concat(more_than_one_anchor)
      end

      # Validate the blueprint and return true if model is valid. False otherwise.
      #
      # @return [Boolean] is model valid?
      def valid?
        validate.empty?
      end

      # Validate the that any labels are pointing to the existing attribute. If not returns the list of errors. Currently just violating labels.
      #
      # @return [Array] array of errors
      def validate_label_references
        labels.select do |label|
          find_column_by_name(label[:reference]).empty?
        end
      end

      def validate_gd_data_type_errors
        columns
          .select { |x| x[:gd_data_type] && !GoodData::Model.check_gd_data_type(x[:gd_data_type]) }
          .map { |e| { :error => :invalid_gd_data_type_specified, :column => e } }
      end

      # Helper methods to decide wheather the dataset is considered wide.
      # Currently the wider datasets have both performance and usability
      # penalty
      #
      # @return [Boolean] matching fields
      def wide?
        fields.count > 32
      end

      # Compares two blueprints. This is done by comapring the hash represenatation.
      # It has to be exacty identical including the order of the columns
      #
      # @param name [GoodData::Model::DatasetBlueprint] Name of a field
      # @return [Boolean] matching fields
      def ==(other)
        to_hash == other.to_hash
      end
    end
  end
end
