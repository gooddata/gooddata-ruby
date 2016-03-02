# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

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
        labels = DatasetBlueprint.labels_for_attribute(dataset, a)
        [{
          'referenceKey' => 1,
          'populates' => [labels.first[:id]],
          'mode' => mode,
          'columnName' => labels.first[:column_name] || labels.first[:id]
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
        when :label
          label_to_manifest(project, dataset, c, mode)
        when :fact
          fact_to_manifest(project, dataset, c, mode)
        when :date_fact
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
        ref = "#{referenced_dataset[:id]}.date.mdyy"
        format = reference[:format] || GoodData::Model::DEFAULT_DATE_FORMAT
        GoodData.logger.info("Using date format \"#{format}\" for referencing attribute \"#{ref}\" of date dimension \"#{referenced_dataset[:id]}\"")
        [{
          'populates' => [ref],
          'mode' => mode,
          'constraints' => { 'date' => format },
          'columnName' => reference[:column_name] || reference[:dataset],
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
      def self.fact_to_manifest(_project, _dataset, fact, mode)
        [{
          'populates' => [fact[:id]],
          'mode' => mode,
          'columnName' => fact[:column_name] || fact[:id]
        }]
      end

      # Generates safe name for upload
      # @param dataset_path [String] Input name
      # @return [String] Generated upload filename
      def self.generate_upload_filename(dataset_path)
        sanitized_name = dataset_path.gsub(/[^0-9a-z]/i, '_')
        # ts = DateTime.now.strftime('%Y%m%d%H%M%S%6N')
        # "#{sanitized_name}-#{ts}.csv"
        "#{sanitized_name}.csv"
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
        labels = DatasetBlueprint.labels_for_attribute(dataset, a)

        label = {}.tap do |l|
          l['referenceKey'] = 1 if labels.first == label
          l['populates'] = [label[:id]]
          l['mode'] = mode
          l['columnName'] = label[:column_name] || label[:id]
        end
        [label]
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
              'dataSet' => dataset[:id],
              'file' => ToManifest.generate_upload_filename(dataset[:id]), # should be configurable
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
        label = DatasetBlueprint.labels_for_attribute(referenced_dataset, anchor).first
        [{
          'populates' => [label[:id]],
          'mode' => mode,
          'columnName' => reference[:column_name] || reference[:dataset],
          'referenceKey' => 1
        }]
      end
    end
  end
end
