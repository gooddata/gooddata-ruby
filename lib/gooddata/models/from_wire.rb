# encoding: UTF-8

module GoodData
  module Model
    module FromWire
      # Converts dataset from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.dataset_from_wire(stuff)
        Hash.new.tap do |d|
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
          default_label_id = attribute['defaultLabel']
          default_labels, regular_labels = labels.partition { |x| x['label']['identifier'] == default_label_id }
          dl = default_labels.map do |label|
            parse_label(attribute, label, 'anchor')
          end
          rl = regular_labels.map do |label|
            parse_label(attribute, label, 'label')
          end
          dl + rl
        end
      end

      # Converts attrbutes from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_attributes(stuff)
        attributes = stuff['dataset']['attributes'] || []
        attributes.mapcat do |attribute|
          labels = attribute['attribute']['labels'] || []
          default_label_id = attribute['attribute']['defaultLabel']
          default_labels, regular_labels = labels.partition { |x| x['label']['identifier'] == default_label_id }
          dl = default_labels.map do |label|
            parse_label(attribute['attribute'], label, 'attribute')
          end
          rl = regular_labels.map do |label|
            parse_label(attribute['attribute'], label, 'label')
          end
          dl + rl
        end
      end

      # Converts date dimensions from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_date_dimensions(stuff)
        Hash.new.tap do |d|
          d[:type] = :date_dimension
          # d[:urn] = :date_dimension
          d[:name] = stuff['dateDimension']['name']
          d[:title] = stuff['dateDimension']['title'] if stuff['dateDimension']['title'] != stuff['dateDimension']['title'].titleize
        end
      end

      # Converts facts from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_facts(stuff)
        facts = stuff['dataset']['facts'] || []
        facts.map do |fact|
          Hash.new.tap do |f|
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
      def self.parse_label(attribute, label, type)
        Hash.new.tap do |l|
          l[:type] = type
          l[:reference] = attribute['identifier'].split('.').last if type == 'label'
          l[:name] = label['label']['identifier'].split('.').last
          l[:title] = label['label']['title'] if label['label']['title'] != label['label']['identifier'].split('.').last.titleize
          l[:gd_data_type] = label['label']['dataType'] if label['label'].key?('dataType')
          l[:gd_type] = label['label']['type'] if label['label'].key?('type')
        end
      end

      # Converts label from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_references(stuff)
        references = stuff['dataset']['references'] || []
        references.map do |ref|
          {
            :type => :reference,
            :name => ref.gsub('dataset.', ''),
            :dataset => ref.gsub('dataset.', '')
          }
        end
      end
    end
  end
end
