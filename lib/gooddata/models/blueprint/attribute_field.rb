# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'blueprint_field'

module GoodData
  module Model
    class AttributeBlueprintField < BlueprintField
      # Returns label that is considered referencing. It is either first one or the one marked
      # with reference_label: true in blueprint
      #
      # @return [Array<GoodData::Model::LabelBlueprintField>] Returns list of labels
      def reference_label
        reference_label = labels.find { |label| label.respond_to?(:reference_label) && label.reference_label == true }
        reference_label || labels.first
      end

      # Returns list of labels on the attribute. There has to be always at least one attribute
      #
      # @return [Array] returns list of the errors represented by hash structures
      def labels
        @dataset_blueprint.labels_for_attribute(self)
      end

      # Validates the fields in the attribute
      #
      # @return [Array] returns list of the errors represented by hash structures
      def validate
        errors = validate_presence_of(:id).map do |e|
          { type: :error, message: "Field \"#{e}\" is not defined or empty for attribute \"#{id}\"" }
        end
        if labels.select(&:reference_label?).count > 1
          errors << {
            type: :error,
            message: "Anchor \"#{id}\" can have only one label with reference_label field set to true"
          }
        end
        errors
      end
    end
  end
end
