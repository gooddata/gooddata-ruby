# encoding: UTF-8

module GoodData
  module Model
    module ToManifest
      # Converts attribute or anchor to manifest
      #
      # @param project [GoodData::Model::ProjectBlueprint] Project blueprint
      # @param dataset [GoodData::Model::SchemaBlueprint] Dataset blueprint
      # @param attribute [Hash] Attribute or Anchor
      # @param mode [String] Mode of the load. Either FULL or INCREMENTAL
      # @return [Hash] Manifest for a particular reference
      def self.attribute_to_manifest(_project, dataset, a, mode)
        [{
          'referenceKey' => 1,
          'populates' => [GoodData::Model.identifier_for(dataset, a.merge(type: :primary_label))],
          'mode' => mode,
          'columnName' => a[:name]
        }]
      end

      # Sets the active project
      #
      # @param project A project identifier
      #
      # ### Examples
      #
      # The following calls are equivalent
      #
      def self.column_to_manifest(project, dataset, c, mode)
        case c[:type].to_sym
        when :attribute
          attribute_to_manifest(project, dataset, c, mode)
        when :label
          label_to_manifest(project, dataset, c, mode)
        when :anchor
          attribute_to_manifest(project, dataset, c, mode)
        when :fact
          fact_to_manifest(project, dataset, c, mode)
        when :reference
          reference_to_manifest(project, dataset, c, mode)
        when :date
          date_ref_to_manifest(project, dataset, c, mode)
        else
          []
        end
      end

      # Converts dataset into manifest. Since for manifest of a dataset you need to
      # have access to the whole project blueprint it requires both project and
      # dataset blueprints. It generates the manifest for blueprint and then selects
      # only the one for particular dataset
      #
      # @param project [GoodData::Model::ProjectBlueprint] Project blueprint
      # @param dataset [GoodData::Model::SchemaBlueprint] Dataset blueprint
      # @param mode [String] Mode of the load. Either FULL or INCREMENTAL
      # @return [Hash] Manifest for a particular dataset
      def self.dataset_to_manifest(project, dataset, mode = 'FULL')
        dataset = dataset.is_a?(String) ? Model::ProjectBlueprint.find_dataset(project, dataset) : dataset
        dataset = dataset.to_hash
        res = Model::ProjectBlueprint.datasets(project).zip(to_manifest(project, mode)).find do |ds|
          ds.first == dataset
        end
        res[1]
      end

      # Converts data reference to manifest
      #
      # @param project [GoodData::Model::ProjectBlueprint] Project blueprint
      # @param dataset [GoodData::Model::SchemaBlueprint] Dataset blueprint
      # @param reference [Hash] Reference
      # @param mode [String] Mode of the load. Either FULL or INCREMENTAL
      # @return [Hash] Manifest for a particular date reference
      def self.date_ref_to_manifest(project, _dataset, reference, mode)
        referenced_dataset = ProjectBlueprint.find_date_dimension(project, reference[:dataset])
        [{
          'populates' => [GoodData::Model.identifier_for(referenced_dataset, type: :date_ref)],
          'mode' => mode,
          'constraints' => { 'date' => 'dd/MM/yyyy' },
          'columnName' => reference[:name],
          'referenceKey' => 1
        }]
      end

      # Converts fact to manifest
      #
      # @param project [GoodData::Model::ProjectBlueprint] Project blueprint
      # @param dataset [GoodData::Model::SchemaBlueprint] Dataset blueprint
      # @param fact [Hash] Fact
      # @param mode [String] Mode of the load. Either FULL or INCREMENTAL
      # @return [Hash] Manifest for a particular fact
      def self.fact_to_manifest(_project, dataset, fact, mode)
        [{
          'populates' => [GoodData::Model.identifier_for(dataset, fact)],
          'mode' => mode,
          'columnName' => fact[:name]
        }]
      end

      # Converts label to manifest
      #
      # @param project [GoodData::Model::ProjectBlueprint] Project blueprint
      # @param dataset [GoodData::Model::SchemaBlueprint] Dataset blueprint
      # @param label [Hash] Label
      # @param mode [String] Mode of the load. Either FULL or INCREMENTAL
      # @return [Hash] Manifest for a particular label
      def self.label_to_manifest(_project, dataset, label, mode)
        a = DatasetBlueprint.attribute_for_label(dataset, label)
        [{
          'populates' => [GoodData::Model.identifier_for(dataset, label, a)],
          'mode' => mode,
          'columnName' => label[:name]
        }]
      end

      # The entry function of the module. Converts the ProjectBlueprint to manifest
      # to be used with SLI (GD loading interface).
      #
      # @param project [GoodData::Model::ProjectBlueprint] Project blueprint
      # @param mode [String] Mode of the load. Either FULL or INCREMENTAL
      # @return [Hash] Manifest for a particular project
      def self.to_manifest(project, mode = 'FULL')
        ProjectBlueprint.datasets(project.to_hash).map do |dataset|
          columns = GoodData::Model::DatasetBlueprint.columns(dataset)
          {
            'dataSetSLIManifest' => {
              'parts' => columns.mapcat { |c| column_to_manifest(project, dataset, c, mode) },
              'dataSet' => GoodData::Model.identifier_for(dataset),
              'file' => 'data.csv', # should be configurable
              'csvParams' => {
                'quoteChar' => '"',
                'escapeChar' => '"',
                'separatorChar' => ',',
                'endOfLine' => "\n"
              }
            }
          }
        end
      end

      # Converts reference to manifest
      #
      # @param project [GoodData::Model::ProjectBlueprint] Project blueprint
      # @param dataset [GoodData::Model::SchemaBlueprint] Dataset blueprint
      # @param reference [Hash] Reference
      # @param mode [String] Mode of the load. Either FULL or INCREMENTAL
      # @return [Hash] Manifest for a particular reference
      def self.reference_to_manifest(project, _dataset, reference, mode)
        referenced_dataset = ProjectBlueprint.find_dataset(project, reference[:dataset])
        anchor = DatasetBlueprint.anchor(referenced_dataset)
        [{
          'populates' => [GoodData::Model.identifier_for(referenced_dataset, anchor.merge(type: :primary_label))],
          'mode' => mode,
          'columnName' => reference[:name],
          'referenceKey' => 1
        }]
      end
    end
  end
end
