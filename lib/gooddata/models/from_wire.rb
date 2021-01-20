# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Model
    module FromWire
      # Converts dataset from wire format into an internal blueprint representation
      #
      # @param dataset [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.dataset_from_wire(dataset, opt)
        {}.tap do |d|
          id = dataset['dataset']['identifier']
          d[:type] = :dataset
          d[:title] = dataset['dataset']['title']
          d[:id] = id
          d[:columns] = (parse_anchor(dataset, opt) + parse_attributes(dataset, opt) + parse_facts(dataset) + parse_references(dataset) + parse_bridges(dataset))
        end
      end

      # Entry method for converting information about project mode from wire
      # format into an internal blueprint representation
      #
      # @param wire_model [Hash] Whatever comes from wire
      # @return [GoodData::Model::ProjectBlueprint] Manifest for a particular reference
      def self.from_wire(wire_model, options = {})
        model = wire_model['projectModelView']['model']['projectModel']
        datasets = model['datasets'] || []
        dims = model['dateDimensions'] || []
        @logger = RemoteSyslogLogger.new(ENV['NODE_NAME'], 514, :program => "lcm-brick", :facility => 'local2')
        ProjectBlueprint.new(
          include_ca: options[:include_ca],
          datasets: datasets.map { |ds| dataset_from_wire(ds, options) },
          date_dimensions: dims.map { |dd| parse_date_dimensions(dd) }
        )
      end

      # Converts attrbutes from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_attributes(stuff, opt)
        dataset = stuff['dataset']
        attributes = dataset['attributes'] || []
        attributes.mapcat do |a|
          parse_attribute(a['attribute'], opt)
        end
      end

      # Converts anchor from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_anchor(stuff, opt)
        anchor = stuff['dataset']['anchor']['attribute']
        parse_attribute(anchor, opt, :anchor)
      end

      def self.select_primary_label(attribute)

        return nil if attribute.nil?

        labels = attribute['labels']
        return nil if labels.nil? || labels.count == 0

        return labels.first if labels.count == 1
        attribute_id = attribute['identifier']
        attribute_id_suffix = attribute_id[ATTRIBUTE_PREFIX.size..-1]
        p_label = labels.find {  |label|
          label_id = label['label']['identifier']
          label_id_suffix = label_id[LABEL_PREFIX.size..-1]
          label if label_id_suffix == attribute_id_suffix
        }

        return p_label unless p_label.nil?

        default_label_id = attribute['defaultLabel']
        default_label = labels.find { |l| l['label']['identifier'] == default_label_id } || labels.last
        default_label
      end

      def self.parse_attribute(attribute, opt, type = :attribute)
        log = @logger
        p_label = select_primary_label(attribute)

        labels = attribute['labels'] || []
        default_label_id = attribute['defaultLabel']
        default_label = labels.find { |l| l['label']['identifier'] == default_label_id } || labels.first
        regular_labels = labels - [default_label]
        pl = default_label.nil? ? [] : [parse_label(attribute, default_label, :default_label)]
        # Write log to check default label for removing
        before_default_label = default_label.nil? ? "" : default_label['label']['identifier']
        after_default_label = p_label.nil? ? "" : p_label['label']['identifier']
        is_label_identical = before_default_label == after_default_label
        project_id = opt['pid']
        log.info("action=dataload-remove-default-label projectId=#{project_id} before_label_id=#{before_default_label} after_label_id=#{after_default_label} identical=#{is_label_identical}")

        rl = regular_labels.map do |label|
          parse_label(attribute, label, :label)
        end
        attr_sort_order = attribute['sortOrder']['attributeSortOrder'] if attribute['sortOrder']

        attribute = {}.tap do |a|
          a[:type] = type
          a[:id] = attribute['identifier']
          a[:title] = attribute['title']
          a[:description] = attribute['description']
          a[:folder] = attribute['folder']

          if attr_sort_order
            a[:order_by] = "#{attr_sort_order['label']} - #{attr_sort_order['direction']}"
          end

          if attribute['grain']
            a[:grain] = attribute['grain'].map do |g|
              case g.keys.first.to_sym
              when :dateDimension
                { date: g.values.first }
              else
                Helpers.symbolize_keys(g)
              end
            end
          end

          attribute['relations'] && a[:relations] = attribute['relations']
        end
        [attribute] + pl + rl
      end

      # Converts date dimensions from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_date_dimensions(date_dim)
        {}.tap do |d|
          d[:type] = :date_dimension
          d[:id] = date_dim['dateDimension']['name']
          d[:title] = date_dim['dateDimension']['title']
          d[:urn] = date_dim['dateDimension']['urn']
          d[:identifier_prefix] = date_dim['dateDimension']['identifierPrefix']
          d[:identifier] = date_dim['dateDimension']['identifier'] if date_dim['dateDimension']['identifier']
          d[:columns] = parse_bridges(date_dim)
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
            f[:type] = resolve_fact_type(fact)
            f[:id] = fact['fact']['identifier']
            f[:title] = fact['fact']['title']
            f[:description] = fact['fact']['description'] if fact['fact']['description']
            f[:folder] = fact['fact']['folder']
            f[:gd_data_type] = fact['fact']['dataType'] || GoodData::Model::DEFAULT_FACT_DATATYPE
            f[:restricted] = fact['fact']['restricted'] if fact['fact']['restricted']
          end
        end
      end

      # Converts label from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_label(attribute, label, type)
        {}.tap do |l|
          l[:type] = :label
          l[:id] = label['label']['identifier']
          l[:reference] = attribute['identifier']
          l[:title] = label['label']['title']
          l[:gd_data_type] = label['label']['dataType'] || GoodData::Model::DEFAULT_ATTRIBUTE_DATATYPE
          l[:gd_type] = label['label']['type'] || GoodData::Model::DEFAULT_TYPE
          l[:default_label] = true if type == :default_label
        end
      end

      # Converts label from wire format into an internal blueprint representation
      #
      # @param dataset [Hash] Whatever comes from wire
      # @param anchor_hash [Hash] dataset id -> anchor id hash
      # @return [Hash] Manifest for a particular reference
      def self.parse_references(dataset)
        references = dataset['dataset']['references'] || []
        references.map do |ref|
          {
            :type => ref =~ /^dataset\./ ? :reference : :date,
            :dataset => ref
          }
        end
      end

      # Converts bridges from wire format into an internal blueprint representation
      #
      # @param dataset [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular bridge
      def self.parse_bridges(dataset)
        references = !dataset['dataset'].nil? && !dataset['dataset']['bridges'].nil? ? dataset['dataset']['bridges'] : []
        references = !dataset['dateDimension'].nil? && !dataset['dateDimension']['bridges'].nil? ? dataset['dateDimension']['bridges'] : references
        references.map do |ref|
          if ref =~ /^dataset\./
            {
              :type => :bridge,
              :dataset => ref
            }
          else
            {}
          end
        end
      end

      private

      def self.resolve_fact_type(fact)
        if fact['fact']['type'].to_s.downcase == 'hll'
          :hll
        elsif fact['fact']['identifier'] =~ /^dt\./
          :date_fact
        else
          :fact
        end
      end
    end
  end
end
