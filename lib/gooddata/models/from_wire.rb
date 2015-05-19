# encoding: UTF-8

require_relative 'from_wire_parse'

module GoodData
  module Model
    module FromWire
      # Converts dataset from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.dataset_from_wire(stuff)
        {}.tap do |d|
          d[:type] = :dataset
          d[:title] = stuff['dataset']['title'] if stuff['dataset']['title'] != stuff['dataset']['identifier'].split('.').last.titleize
          d[:name] = stuff['dataset']['identifier'].split('.').last
          d[:columns] = (parse_anchor(stuff) + parse_attributes(stuff) + parse_facts(stuff) + parse_references(stuff))
        end
      end

      # Entry method for converting information about project mode from wire
      # format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [GoodData::Model::ProjectBlueprint] Manifest for a particular reference
      def self.from_wire(stuff)
        model = stuff['projectModelView']['model']['projectModel']
        datasets = model['datasets'] || []
        dims = model['dateDimensions'] || []
        ProjectBlueprint.new(
          datasets: datasets.map { |ds| dataset_from_wire(ds) },
          date_dimensions: dims.map { |dd| parse_date_dimensions(dd) }
        )
      end
    end
  end
end
