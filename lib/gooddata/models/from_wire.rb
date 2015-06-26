# encoding: UTF-8

require_relative 'from_wire_parse'

module GoodData
  module Model
    module FromWire
      # Converts dataset from wire format into an internal blueprint representation
      #
      # @param dataset [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.dataset_from_wire(dataset, anchor_hash)
        {}.tap do |d|
          d[:type] = :dataset
          d[:title] = dataset['dataset']['title'] if dataset['dataset']['title'] != dataset['dataset']['identifier'].split('.').last.titleize
          d[:name] = dataset['dataset']['identifier'].split('.').last
          d[:columns] = (parse_anchor(dataset) + parse_attributes(dataset) + parse_facts(dataset) + parse_references(dataset, anchor_hash))
        end
      end

      # Entry method for converting information about project mode from wire
      # format into an internal blueprint representation
      #
      # @param wire_model [Hash] Whatever comes from wire
      # @return [GoodData::Model::ProjectBlueprint] Manifest for a particular reference
      def self.from_wire(wire_model)
        model = wire_model['projectModelView']['model']['projectModel']
        datasets = model['datasets'] || []
        dims = model['dateDimensions'] || []
        anchor_hash = Hash[model['datasets'].map do |d|
          [
            d['dataset']['identifier'].split('.').last,
            d['dataset']['anchor']['attribute']['identifier'].split('.').last
          ]
        end]
        ProjectBlueprint.new(
          datasets: datasets.map { |ds| dataset_from_wire(ds, anchor_hash) },
          date_dimensions: dims.map { |dd| parse_date_dimensions(dd) }
        )
      end

      # Converts anchor from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_anchor(stuff)
        attribute = stuff['dataset']['anchor']['attribute']
        if !attribute.key?('labels')
          []
        else
          labels = attribute['labels'] || []
          default_label = attribute['defaultLabel']
          primary_label_name = attribute['identifier'].split('.').last
          dataset_name = attribute['identifier'].split('.')[1]
          primary_label_identifier = GoodData::Model.identifier_for({ name: dataset_name }, type: :primary_label, name: primary_label_name)
          primary_labels, regular_labels = labels.partition { |x| x['label']['identifier'] == primary_label_identifier }
          dl = primary_labels.map do |label|
            parse_label(attribute, label, 'anchor', default_label)
          end
          rl = regular_labels.map do |label|
            parse_label(attribute, label, 'label', default_label)
          end
          dl + rl
        end
      end

      # Converts attrbutes from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_attributes(stuff)
        dataset = stuff['dataset']
        attributes = dataset['attributes'] || []
        attributes.mapcat do |a|
          attribute = a['attribute']
          labels = attribute['labels'] || []
          default_label = attribute['defaultLabel']
          primary_label_name = attribute['identifier'].split('.').last
          dataset_name = attribute['identifier'].split('.')[1]
          primary_label_identifier = GoodData::Model.identifier_for({ name: dataset_name }, type: :primary_label, name: primary_label_name)
          primary_labels, regular_labels = labels.partition { |x| x['label']['identifier'] == primary_label_identifier }
          dl = primary_labels.map do |label|
            parse_label(attribute, label, 'attribute', default_label)
          end
          rl = regular_labels.map do |label|
            parse_label(attribute, label, 'label', default_label)
          end
          dl + rl
        end
      end

      # Converts date dimensions from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_date_dimensions(date_dim)
        {}.tap do |d|
          d[:type] = :date_dimension
          # d[:urn] = :date_dimension
          d[:name] = date_dim['dateDimension']['name']
          d[:title] = date_dim['dateDimension']['title'] if date_dim['dateDimension']['title'] != d[:name].titleize
        end
      end

      # Converts facts from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_facts(stuff)
        facts = stuff['dataset']['facts'] || []
        facts.map do |fact|
          {}.tap do |f|
            f[:type] = fact['fact']['identifier'] =~ /^dt\./ ? :date_fact : :fact
            f[:name] = fact['fact']['identifier'].split('.').last
            f[:title] = fact['fact']['title'] if fact['fact']['title'] != fact['fact']['identifier'].split('.').last.titleize
            f[:description] = fact['fact']['description'] if fact['fact']['description']
            f[:folder] = fact['fact']['folder'] if fact['fact']['folder']
            f[:gd_data_type] = fact['fact']['dataType'] if fact['fact'].key?('dataType')
          end
        end
      end

      # Converts label from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_label(attribute, label, type, default_label = nil)
        {}.tap do |l|
          l[:type] = type
          l[:reference] = attribute['identifier'].split('.').last if type == 'label'
          l[:name] = label['label']['identifier'].split('.').last
          l[:title] = label['label']['title'] if label['label']['title'] != label['label']['identifier'].split('.').last.titleize
          l[:description] = attribute['description'] if %w(attribute anchor).include?(type) && attribute['description']
          l[:folder] = attribute['folder'] if attribute['folder'] && (type == 'attribute' || type == 'anchor')
          l[:gd_data_type] = label['label']['dataType'] if label['label'].key?('dataType')
          l[:gd_type] = label['label']['type'] if label['label'].key?('type')
          l[:default_label] = true if default_label == label['label']['identifier']
        end
      end

      # Converts label from wire format into an internal blueprint representation
      #
      # @param dataset [Hash] Whatever comes from wire
      # @param anchor_hash [Hash] dataset id -> anchor id hash
      # @return [Hash] Manifest for a particular reference
      def self.parse_references(dataset, anchor_hash)
        references = dataset['dataset']['references'] || []
        references.map do |ref|
          dataset_name = ref.gsub(/^dataset\./, '')
          if ref =~ /^dataset\./
            {
              :type => :reference,
              # in case the dataset isn't in the model, take the name
              :name => anchor_hash[dataset_name] || dataset_name,
              :dataset => dataset_name
            }
          else
            {
              :type => :date,
              :name => dataset_name,
              :dataset => dataset_name
            }
          end
        end
      end
    end
  end
end
