# encoding: UTF-8

module GoodData
  module Model
    module FromWire
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
      def self.parse_date_dimensions(stuff)
        {}.tap do |d|
          d[:type] = :date_dimension
          # d[:urn] = :date_dimension
          d[:name] = stuff['dateDimension']['name']
          d[:title] = stuff['dateDimension']['title'] if stuff['dateDimension']['title'] != d[:name].titleize
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
          l[:gd_data_type] = label['label']['dataType'] if label['label'].key?('dataType')
          l[:gd_type] = label['label']['type'] if label['label'].key?('type')
          l[:default_label] = true if default_label == label['label']['identifier']
        end
      end

      # Converts label from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_references(stuff)
        references = stuff['dataset']['references'] || []
        references.map do |ref|
          if ref =~ /^dataset\./
            {
              :type => :reference,
              :name => ref.gsub(/^dataset\./, ''),
              :dataset => ref.gsub(/^dataset\./, '')
            }
          else
            {
              :type => :date,
              :name => ref.gsub(/^dataset\./, ''),
              :dataset => ref.gsub(/^dataset\./, '')
            }
          end
        end
      end
    end
  end
end
