# encoding: UTF-8

require_relative 'blueprint_field'

module GoodData
  module Model
    class ReferenceBlueprintField < BlueprintField
      # Returns the schema that is referenced by this ref
      #
      # @return [GoodData::Model::SchemaBlueprint] the referencesd schema
      def dataset
        dataset_blueprint.find_dataset(reference, include_date_dimensions: true)
      end

      # Returns the string reference of the ref which is string Id of dataset that is referenced.
      #
      # @return [String] Id of the referenced dataset
      def reference
        data[:dataset]
      end

      # Validates the fields in the ref
      #
      # @return [Array] returns list of the errors represented by hash structures
      def validate
        validate_presence_of(:dataset).map do |e|
          { type: :error, message: "Field \"#{e}\" is not defined or empty for reference \"#{data}\"" }
        end
      end

      # Returns the md object in associated project or throws error if not present
      #
      # @return [GoodData::MdObject] md object that is represented in the blueprint
      def in_project(_project)
        fail NotImplementedError, 'Reference does not have representation as an object in datamart'
      end
    end
  end
end
