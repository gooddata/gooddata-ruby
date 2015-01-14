# encoding: UTF-8

module GoodData
  module Model
    module ToManifest
      class << self
        # Converts attribute or anchor to manifest
        #
        # @param [GoodData::Model::ProjectBlueprint] _project Project blueprint
        # @param [GoodData::Model::SchemaBlueprint] dataset Dataset blueprint
        # @param [Hash] attribute Attribute or Anchor
        # @param [String] mode Mode of the load. Either FULL or INCREMENTAL
        # @return [Hash] Manifest for a particular reference
        def attribute_to_manifest(_project, dataset, attribute, mode)
          [{
             'referenceKey' => 1,
             'populates' => [GoodData::Model.identifier_for(dataset, attribute.merge(type: :primary_label))],
             'mode' => mode,
             'columnName' => attribute[:name]
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
        def column_to_manifest(project, dataset, c, mode)
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
        # @param [GoodData::Model::ProjectBlueprint] project Project blueprint
        # @param [GoodData::Model::SchemaBlueprint] dataset Dataset blueprint
        # @param [String] mode Mode of the load. Either FULL or INCREMENTAL
        # @return [Hash] Manifest for a particular dataset
        def dataset_to_manifest(project, dataset, mode = 'FULL')
          dataset = dataset.is_a?(String) ? Model::ProjectBlueprint.find_dataset(project, dataset) : dataset
          dataset = dataset.to_hash
          res = Model::ProjectBlueprint.datasets(project).zip(to_manifest(project, mode)).find do |ds|
            ds.first == dataset
          end
          res[1]
        end

        # Converts data reference to manifest
        #
        # @param [GoodData::Model::ProjectBlueprint] project Project blueprint
        # @param [GoodData::Model::SchemaBlueprint] _dataset Dataset blueprint
        # @param [Hash] reference Reference
        # @param [String] mode Mode of the load. Either FULL or INCREMENTAL
        # @return [Hash] Manifest for a particular date reference
        def date_ref_to_manifest(project, _dataset, reference, mode)
          referenced_dataset = ProjectBlueprint.find_date_dimension(project, reference[:dataset])
          [{
             'populates' => [GoodData::Model.identifier_for(referenced_dataset, type: :date_ref)],
             'mode' => mode,
             'constraints' => {'date' => 'dd/MM/yyyy'},
             'columnName' => reference[:name],
             'referenceKey' => 1
           }]
        end

        # Converts fact to manifest
        #
        # @param [GoodData::Model::ProjectBlueprint] _project Project blueprint
        # @param [GoodData::Model::SchemaBlueprint] dataset Dataset blueprint
        # @param [Hash] fact Fact
        # @param [String] mode Mode of the load. Either FULL or INCREMENTAL
        # @return [Hash] Manifest for a particular fact
        def fact_to_manifest(_project, dataset, fact, mode)
          [{
             'populates' => [GoodData::Model.identifier_for(dataset, fact)],
             'mode' => mode,
             'columnName' => fact[:name]
           }]
        end

        # Converts label to manifest
        #
        # @param [GoodData::Model::ProjectBlueprint] _project Project blueprint
        # @param [GoodData::Model::SchemaBlueprint] dataset Dataset blueprint
        # @param [Hash] label Label
        # @param [String] mode Mode of the load. Either FULL or INCREMENTAL
        # @return [Hash] Manifest for a particular label
        def label_to_manifest(_project, dataset, label, mode)
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
        def to_manifest(project, mode = 'FULL')
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
        # @param [GoodData::Model::ProjectBlueprint] project Project blueprint
        # @param [GoodData::Model::SchemaBlueprint] _dataset Dataset blueprint
        # @param [Hash] reference Reference
        # @param [String] mode Mode of the load. Either FULL or INCREMENTAL
        # @return [Hash] Manifest for a particular reference
        def reference_to_manifest(project, _dataset, reference, mode)
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
end
