# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Model
    module ToWire
      # Converts anchor to wire format. There is difference between datsets that
      # do not have anchor and those that do. Even if there is no acnhor you
      # stil have to generate. If there is anchor it behaves exactly like am
      # attribute
      #
      # @param project [Hash] Project blueprint hash represenation
      # @param dataset [Hash] Dataset blueprint hash represenation
      # @return [Hash] Manifest for a particular reference
      def self.anchor_to_wire(_project, dataset)
        attribute_to_wire(dataset, DatasetBlueprint.anchor(dataset))
      end

      # Converts atttribute to wire format.
      #
      # @param project [Hash] Project blueprint hash represenation
      # @param dataset [Hash] Dataset blueprint hash represenation
      # @return [Hash] Manifest for a particular reference
      def self.attributes_to_wire(_project, dataset)
        DatasetBlueprint.attributes(dataset).map do |a|
          attribute_to_wire(dataset, a)
        end
      end

      # Converts atttribute to wire format.
      #
      # @param dataset [Hash] Dataset blueprint hash represenation
      # @param attribute [Hash] Attribute
      # @return [Hash] Manifest for a particular reference
      def self.attribute_to_wire(dataset, attribute)
        ls = DatasetBlueprint.labels_for_attribute(dataset, attribute)
        labels = ls.map do |l|
          {
            label: {
              identifier: l[:id],
              title: GoodData::Model.title(l),
              type: l[:gd_type] || Model::DEFAULT_TYPE,
              dataType: GoodData::Model.normalize_gd_data_type(l[:gd_data_type]) || Model::DEFAULT_ATTRIBUTE_DATATYPE
            }
          }
        end
        {}.tap do |a|
          a[:attribute] = {}
          a[:attribute][:identifier] = attribute[:id]
          a[:attribute][:title] = Model.title(attribute)
          a[:attribute][:folder] = attribute[:folder] || dataset[:folder] || GoodData::Model.title(dataset)
          a[:attribute][:labels] = labels unless labels.empty?
          a[:attribute][:description] = GoodData::Model.description(attribute) if GoodData::Model.description(attribute)
          default = ls.find { |l| l[:default_label] }
          a[:attribute][:defaultLabel] = (default && default[:id]) || ls.first[:id] unless ls.empty?
        end
      end

      # Converts dataset to wire format.
      #
      # @param project [Hash] Project blueprint hash represenation
      # @param dataset [Hash] Dataset blueprint hash represenation
      # @return [Hash] Manifest for a particular reference
      def self.dataset_to_wire(project, dataset)
        {
          dataset: {
            identifier: dataset[:id],
            title: GoodData::Model.title(dataset),
            anchor: anchor_to_wire(project, dataset),
            attributes: attributes_to_wire(project, dataset),
            facts: DatasetBlueprint.facts(dataset).map { |f| fact_to_wire(dataset, f) },
            references: references_to_wire(project, dataset)
          }
        }
      end

      # Converts date dimension to wire format.
      #
      # @param project [Hash] Project blueprint hash represenation
      # @param dataset [Hash] Dataset blueprint hash represenation
      # @return [Hash] Manifest for a particular reference
      def self.date_dimension_to_wire(_project, dataset)
        payload = {}.tap do |dd|
          dd[:name] = dataset[:id]
          dd[:urn] = dataset[:urn] if dataset[:urn]
          dd[:title] = GoodData::Model.title(dataset)
        end
        { dateDimension: payload }
      end

      # Converts fact to wire format.
      #
      # @param dataset [Hash] Dataset blueprint hash represenation
      # @param fact [Hash] Fact blueprint
      # @return [Hash] Manifest for a particular reference
      def self.fact_to_wire(dataset, fact)
        payload = {
          fact: {
            identifier: fact[:id],
            title: GoodData::Model.title(fact),
            folder: fact[:folder] || dataset[:folder] || GoodData::Model.title(dataset),
            dataType: GoodData::Model.normalize_gd_data_type(fact[:gd_data_type]) || DEFAULT_FACT_DATATYPE
          }
        }
        payload.tap do |p|
          p[:fact][:description] = GoodData::Model.description(fact) if GoodData::Model.description(fact)
        end
      end

      # Converts references to wire format.
      #
      # @param fact [Hash] Project blueprint hash represenation
      # @param dataset [Hash] Dataset blueprint hash represenation
      # @return [Hash] Manifest for a particular reference
      def self.references_to_wire(_project, dataset)
        DatasetBlueprint.references(dataset).map do |r|
          r[:dataset]
        end
      end

      # Entry method. Converts ProjectBlueprint representation into wire format
      # which is understood by the API
      #
      # @param fact [Hash] Project blueprint represenation
      # @param dataset [Hash] Dataset blueprint hash represenation
      # @return [Hash] Manifest for a particular reference
      def self.to_wire(what)
        {
          diffRequest: {
            targetModel: {
              projectModel: {
                datasets: (what[:datasets] || []).map { |d| dataset_to_wire(what, d) },
                dateDimensions: (what[:date_dimensions] || []).map { |d| date_dimension_to_wire(what, d) }
              }
            }
          }
        }
      end
    end
  end
end
