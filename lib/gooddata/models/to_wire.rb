# encoding: UTF-8

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
        if DatasetBlueprint.anchor(dataset)
          attribute_to_wire(dataset, DatasetBlueprint.anchor(dataset))
        else
          {
            attribute: {
              identifier: GoodData::Model.identifier_for(dataset, type: :anchor_no_label),
              title: "Records of #{ GoodData::Model.title(dataset) }",
              folder: dataset[:folder] || GoodData::Model.title(dataset)
            }
          }
        end
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
        default_label = DatasetBlueprint.default_label_for_attribute(dataset, attribute)
        label = default_label[:type].to_sym == :label ? default_label : default_label.merge(type: :primary_label)
        payload = {
          attribute: {
            identifier: GoodData::Model.identifier_for(dataset, attribute),
            title: GoodData::Model.title(attribute),
            folder: attribute[:folder] || dataset[:folder] || GoodData::Model.title(dataset),
            labels: ([attribute.merge(type: :primary_label)] + DatasetBlueprint.labels_for_attribute(dataset, attribute)).map do |l|
              {
                label: {
                  identifier: GoodData::Model.identifier_for(dataset, l, attribute),
                  title: GoodData::Model.title(l),
                  type: l[:gd_type],
                  dataType: l[:gd_data_type]
                }
              }
            end,
            defaultLabel: GoodData::Model.identifier_for(dataset, label, attribute)
          }
        }
        payload.tap do |p|
          p[:attribute][:description] = GoodData::Model.description(attribute) if GoodData::Model.description(attribute)
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
            identifier: GoodData::Model.identifier_for(dataset),
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
      def self.date_dimensions_to_wire(_project, dataset)
        {
          dateDimension: {
            name: dataset[:name],
            title: GoodData::Model.title(dataset)
          }
        }
      end

      # Converts fact to wire format.
      #
      # @param dataset [Hash] Dataset blueprint hash represenation
      # @param fact [Hash] Fact blueprint
      # @return [Hash] Manifest for a particular reference
      def self.fact_to_wire(dataset, fact)
        payload = {
          fact: {
            identifier: GoodData::Model.identifier_for(dataset, fact),
            title: GoodData::Model.title(fact),
            folder: fact[:folder] || dataset[:folder] || GoodData::Model.title(dataset),
            dataType: fact[:gd_data_type] || DEFAULT_FACT_DATATYPE
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
      def self.references_to_wire(project, dataset)
        DatasetBlueprint.references(dataset).map do |r|
          if ProjectBlueprint.date_dimension?(project, r[:dataset])
            ProjectBlueprint.find_date_dimension(project, r[:dataset])[:name]
          elsif ProjectBlueprint.dataset?(project, r[:dataset])
            ds = ProjectBlueprint.find_dataset(project, r[:dataset])
            'dataset.' + ds[:name]
          else
            fail 'This dataset does not exist'
          end
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
                dateDimensions: (what[:date_dimensions] || []).map { |d| date_dimensions_to_wire(what, d) }
              }
            }
          }
        }
      end
    end
  end
end
