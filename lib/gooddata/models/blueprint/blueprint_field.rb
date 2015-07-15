# encoding: UTF-8

module GoodData
  module Model
    class BlueprintField
      attr_reader :dataset_blueprint, :data

      def id
        @data[:id]
      end

      def initialize(data, dataset)
        @data = GoodData::Helpers.symbolize_keys(data)
        @data[:type] = @data[:type].to_sym
        @dataset_blueprint = dataset
      end

      # Returns the md object in associated project or throws error if not present
      #
      # @return [GoodData::MdObject] md object that is represented in the blueprint
      def in_project(project)
        GoodData::MdObject[id, project: project, client: project.client]
      end

      def method_missing(method_sym, *arguments, &block)
        if @data.key?(method_sym)
          @data[method_sym]
        else
          super
        end
      end

      def respond_to?(method_sym, *arguments, &block)
        if @data.key?(method_sym)
          true
        else
          super
        end
      end

      def title
        @data[:title] || GoodData::Helpers.titleize(@data[:id])
      end

      # Validates the fields in the field
      #
      # @return [Array] returns list of the errors represented by hash structures
      def validate
        []
      end

      def ==(other)
        return false unless other.respond_to?(:data)
        @data == other.data
      end

      private

      def validate_presence_of(*fields)
        fields.reduce([]) do |a, e|
          data.key?(e) && !data[e].blank? ? a : a + [e]
        end
      end
    end
  end
end
