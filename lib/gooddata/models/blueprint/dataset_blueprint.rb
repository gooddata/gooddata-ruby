# encoding: UTF-8

require_relative 'schema_builder'
require_relative 'schema_blueprint'

module GoodData
  module Model
    class DatasetBlueprint < SchemaBlueprint
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
        find_column_by_type(dataset, :anchor)
      end

      # Returns attributes of a dataset
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the attribute or an empty array
      def self.attributes(dataset)
        find_columns_by_type(dataset, :attribute, :all)
      end

      # Returns attributes and anchor defined on a dataset
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the attributes
      def self.attributes_and_anchors(dataset)
        [anchor(dataset)] + attributes(dataset)
      end

      # Returns all labels that is referenced by a label
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the labels or an empty array
      def self.attribute_for_label(dataset, label)
        find_columns_by_type(dataset, :attribute, :anchor).find { |a| label[:reference] == a[:id] }
      end

      # Returns all the fields of a dataset. This means facts, attributes, references
      #
      # @param ds [Hash] Dataset blueprint
      # @return [Boolean]
      def self.columns(ds)
        (ds.to_hash[:columns] || [])
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
        find_column_by_type(dataset, :date_fact)
      end

      # Returns label that is marked as default for a particular attribtue.
      # This does not necessarily need to be the first one. This is a default label
      # in terms of what is displayed on the UI
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the labels or an empty array
      def self.default_label_for_attribute(dataset, attribute)
        default_label = labels_for_attribute(dataset, attribute).find { |l| l[:default_label] == true }
        default_label
      end

      # Returns facts of a dataset
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the attribute or an empty array
      def self.facts(dataset)
        find_columns_by_type(dataset, :fact, :date_fact)
      end

      # Finds a specific column given a name
      #
      # @param dataset [Hash] Dataset blueprint
      # @param name [String] Name of a field
      # @param all [Symbol] if :all is passed all mathching objects are returned
      # Otherwise only the first one is
      # @return [Array<Hash>] matching fields
      def self.find_column_by_id(dataset, name, all = nil)
        if all == :all
          columns(dataset).select { |c| c[:id].to_s == name }
        else
          columns(dataset).find { |c| c[:id].to_s == name }
        end
      end

      # Returns first field of a specified type.
      #
      # @param dataset [Hash | GoodData::Model::ProjectBlueprint] Dataset blueprint
      # @param types [String | Symbol | Array[Symbol] | Array[String]] Type or types you would like to get
      # as third parameter it return all object otherwise it returns the first one
      # @return [Array<Hash>] matching fields
      def self.find_column_by_type(dataset, *types)
        columns(dataset).find { |c| types.any? { |t| t.to_s == c[:type].to_s } }
      end

      # Returns all the fields of a specified type. You can specify more types
      # if you need more than one type.
      #
      # @param dataset [Hash | GoodData::Model::ProjectBlueprint] Dataset blueprint
      # @param types [String | Symbol | Array[Symmbol] | Array[String]] Type or types you would like to get
      # @return [Array<Hash>] matching fields
      def self.find_columns_by_type(dataset, *types)
        columns(dataset).select { |c| types.any? { |t| t.to_s == c[:type].to_s } }
      end

      # Returns labels facts of a dataset
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the label or an empty array
      def self.labels(dataset)
        find_columns_by_type(dataset, :label)
      end

      # Returns labels for a particular attribute
      #
      # @param dataset [Hash] Dataset blueprint
      # @param attribute [Hash] Attribute
      # @return [Array<Hash>] returns the labels or an empty array
      def self.labels_for_attribute(dataset, attribute)
        labels(dataset).select { |l| l[:reference] == attribute[:id] }
      end

      # Returns references of a dataset
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the references or an empty array
      def self.references(dataset)
        find_columns_by_type(dataset, :reference, :date)
      end

      # Returns anchor of a dataset
      #
      # @return [Hash] returns the anchor or nil
      def anchor
        find_column_by_type(:anchor)
      end

      # Checks if a dataset has an anchor.
      #
      # @return [Boolean] returns true if dataset has an anchor
      def anchor?
        columns.any? { |c| c.type == :anchor }
      end

      # Returns attributes of a dataset
      #
      # @return [Array<Hash>] returns the attribute or an empty array
      def attributes(id = :all)
        return id if id.is_a?(AttributeBlueprintField)
        ats = find_columns_by_type(:attribute)
        id == :all ? ats : ats.find { |a| a.id == id }
      end

      # Returns attributes and anchor defined on a dataset
      #
      # @return [Array<GoodData::Model::DatasetBlueprint>] returns the attributes
      def attributes_and_anchors
        attributes + [anchor]
      end

      # Changes the dataset through a builder. You provide a block and an istance of
      # GoodData::Model::SchemaBuilder is passed in as the only parameter
      #
      # @return [GoodData::Model::SchemaBlueprint] returns changed dataset blueprint
      def change(&block)
        builder = SchemaBuilder.create_from_data(self)
        block.call(builder)
        @data = builder.to_hash
        self
      end

      # Returns all the fields of a dataset. This means anchor, facts, attributes, references
      # This method will cast them to correct types
      #
      # @return [Boolean]
      def columns
        DatasetBlueprint.columns(to_hash).map do |c|
          case c[:type].to_sym
          when :anchor
            GoodData::Model::AnchorBlueprintField.new(c, self)
          when :attribute
            GoodData::Model::AttributeBlueprintField.new(c, self)
          when :fact
            GoodData::Model::FactBlueprintField.new(c, self)
          when :label
            GoodData::Model::LabelBlueprintField.new(c, self)
          when :reference
            GoodData::Model::ReferenceBlueprintField.new(c, self)
          when :date
            GoodData::Model::ReferenceBlueprintField.new(c, self)
          else
            GoodData::Model::BlueprintField.new(c, self)
          end
        end
      end
      alias_method :fields, :columns

      # Creates a metric which counts numnber of lines in dataset. Works for both
      # datasets with or without anchor
      #
      # @return [Boolean]
      def count(project)
        anchor.in_project(project).create_metric.execute
      end

      # Returns date facts of a dataset
      #
      # @return [Array<Hash>] returns the attribute or an empty array
      def date_facts
        find_columns_by_type(:date_fact)
      end

      # Duplicates the DatasetBlueprint. It is done as a deep duplicate
      #
      # @return [GoodData::Model::DatasetBlueprint] matching fields
      def dup
        DatasetBlueprint.new(GoodData::Helpers.deep_dup(data), project_blueprint)
      end

      # Returns facts of a dataset
      #
      # @return [Array<Hash>] returns the attribute or an empty array
      def facts(id = :all)
        return id if id.is_a?(FactBlueprintField)
        fs = find_columns_by_type(:fact)
        id == :all ? fs : fs.find { |a| a.id == id }
      end

      # Finds a specific column given a col
      #
      # @param col [GoodData::Model::BlueprintField | Hash] Field
      # @return [GoodData::Model::BlueprintField] matching fields
      def find_column(col)
        columns.find { |c| c == col }
      end

      # Finds a specific column given an id
      #
      # @param id [String] Id of a field
      # @param all [Symbol] if :all is passed all mathching objects are returned
      # Otherwise only the first one is
      # @return [Array<Hash>] matching fields
      def find_column_by_id(id)
        id = id.respond_to?(:id) ? id.id : id
        columns.find { |c| c.id == id }
      end

      # Returns first field of a specified type.
      #
      # @param type [String | Symbol | Array[Symmbol] | Array[String]] Type or types you would like to get
      # @return [GoodData::Model::BlueprintField] returns matching field
      def find_column_by_type(*types)
        columns.find { |c| types.any? { |t| t.downcase.to_sym == c.type } }
      end

      # Returns all the fields of a specified type. You can specify more types
      # as an array if you need more than one type.
      #
      # @param type [String | Symbol | Array[Symmbol] | Array[String]] Type or types you would like to get
      # as third parameter it return all object otherwise it returns the first one
      # @return [Array<GoodData::Model::BlueprintField>] matching fields
      def find_columns_by_type(*types)
        columns.select { |c| types.any? { |t| t.downcase.to_sym == c.type } }
      end

      # Creates a DatasetBlueprint
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [DatasetBlueprint] returns the labels or an empty array
      def initialize(init_data, blueprint)
        super
        @data[:type] = @data.key?('type') ? @data['type'].to_sym : @data[:type]
        @data[:columns].each do |c|
          c[:type] = c[:type].to_sym
        end
      end

      # Returns labels facts of a dataset
      #
      # @param dataset [Hash] Dataset blueprint
      # @return [Array<Hash>] returns the label or an empty array
      def labels(id = :all)
        return id if id.is_a?(LabelBlueprintField)
        labs = find_columns_by_type(:label)
        id == :all ? labs : labs.find { |l| l.id == id }
      end

      def attribute_for_label(label)
        l = labels(label)
        attributes_and_anchors.find { |a| a.id == l.reference }
      end

      def labels_for_attribute(attribute)
        a = attributes(attribute)
        labels.select { |l| l.reference == a.id }
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

      # Returns references of a dataset
      #
      # @return [Array<Hash>] returns the references or an empty array
      def references
        find_columns_by_type(:reference, :date)
      end

      # Removes column from from the blueprint
      #
      # @param id [String] Id of the column to be removed
      # @return [GoodData::Model::ProjectBlueprint] Returns changed blueprint
      def remove_column!(id)
        @project_blueprint.remove_column!(self, id)
      end

      # Removes all the labels from the anchor. This is a typical operation that people want to perform
      #
      # @return [GoodData::Model::ProjectBlueprint] Returns changed blueprint
      def strip_anchor!
        @project_blueprint.strip_anchor!(self)
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
            :title => GoodData::Helpers.titleize(fact[:name]),
            :expression => "SELECT SUM(![#{id}])")
        end
      end

      def to_blueprint
        GoodData::Model::ProjectBlueprint.new(datasets: [to_hash])
      end

      # Validate the blueprint return array of errors that are found.
      #
      # @return [Array] array of errors
      def validate
        errors = []
        errors.concat(validate_more_anchors)
        errors.concat(validate_some_anchors)
        errors.concat(validate_label_references)
        errors.concat(validate_gd_data_type_errors)
        errors.concat(fields.flat_map(&:validate))
        errors.concat(validate_attribute_has_one_label)
        errors
      end

      # Validate if the dataset has more than zero anchors defined.
      #
      # @return [Array] array of errors
      def validate_some_anchors
        find_columns_by_type(:anchor).count == 0 ? [{ type: :no_anchor, dataset: id }] : []
      end

      # Validate if the dataset does not have more than one anchor defined.
      #
      # @return [Array] array of errors
      def validate_more_anchors
        find_columns_by_type(:anchor).count > 1 ? [{ type: :more_than_on_anchor, dataset: id }] : []
      end

      # Validate if the attribute does have at least one label
      #
      # @return [Array] array of errors
      def validate_attribute_has_one_label
        find_columns_by_type(:attribute)
          .select { |a| a.labels.empty? }
          .map { |e| { type: :attribute_without_label, attribute: e.id } }
      end

      # Validate the that any labels are pointing to the existing attribute. If not returns the list of errors. Currently just violating labels.
      #
      # @return [Array] array of errors
      def validate_label_references
        labels.select { |r| r.attribute.nil? }
          .map { |er_ref| { type: :wrong_label_reference, label: er_ref.id, wrong_reference: er_ref.data[:reference] } }
      end

      # Validate the the used gd_data_types are one of the allowed types. The data types are checked on lables and facts.
      #
      # @return [Array] array of errors
      def validate_gd_data_type_errors
        (labels + facts)
          .select { |x| x.gd_data_type && !GoodData::Model.check_gd_data_type(x.gd_data_type) }
          .map { |e| { :error => :invalid_gd_data_type_specified, :column => e.id } }
      end

      # Helper methods to decide wheather the dataset is considered wide.
      # Currently the wider datasets have both performance and usability
      # penalty
      #
      # @return [Boolean] matching fields
      def wide?
        fields.count > 32
      end
    end
  end
end
