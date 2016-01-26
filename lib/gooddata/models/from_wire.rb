# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Model
    module FromWire
      # Converts dataset from wire format into an internal blueprint representation
      #
      # @param dataset [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.dataset_from_wire(dataset)
        {}.tap do |d|
          id = dataset['dataset']['identifier']

          d[:type] = :dataset
          d[:title] = dataset['dataset']['title']
          d[:id] = id
          d[:columns] = (parse_anchor(dataset) + parse_attributes(dataset) + parse_facts(dataset) + parse_references(dataset))
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

        ProjectBlueprint.new(
          datasets: datasets.map { |ds| dataset_from_wire(ds) },
          date_dimensions: dims.map { |dd| parse_date_dimensions(dd) }
        )
      end

      # Converts attrbutes from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_attributes(stuff)
        dataset = stuff['dataset']
        attributes = dataset['attributes'] || []
        attributes.mapcat do |a|
          parse_attribute(a['attribute'])
        end
      end

      # Converts anchor from wire format into an internal blueprint representation
      #
      # @param stuff [Hash] Whatever comes from wire
      # @return [Hash] Manifest for a particular reference
      def self.parse_anchor(stuff)
        anchor = stuff['dataset']['anchor']['attribute']
        parse_attribute(anchor, :anchor)
      end

      def self.parse_attribute(attribute, type = :attribute)
        labels = attribute['labels'] || []
        default_label_id = attribute['defaultLabel']
        default_label = labels.find { |l| l['label']['identifier'] == default_label_id } || labels.first
        regular_labels = labels - [default_label]
        pl = default_label.nil? ? [] : [parse_label(attribute, default_label, :default_label)]
        rl = regular_labels.map do |label|
          parse_label(attribute, label, :label)
        end
        attribute = {}.tap do |a|
          a[:type] = type
          a[:id] = attribute['identifier']
          a[:title] = attribute['title']
          a[:description] = attribute['description']
          a[:folder] = attribute['folder']
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
            f[:id] = fact['fact']['identifier']
            f[:title] = fact['fact']['title']
            f[:description] = fact['fact']['description'] if fact['fact']['description']
            f[:folder] = fact['fact']['folder']
            f[:gd_data_type] = fact['fact']['dataType'] || GoodData::Model::DEFAULT_FACT_DATATYPE
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
          if ref =~ /^dataset\./
            {
              :type => :reference,
              :dataset => ref
            }
          else
            {
              :type => :date,
              :dataset => ref
            }
          end
        end
      end
    end
  end
end
