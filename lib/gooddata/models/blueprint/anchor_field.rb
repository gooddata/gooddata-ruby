# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'attribute_field'

module GoodData
  module Model
    class AnchorBlueprintField < AttributeBlueprintField
      # Returns true if it is an anchor
      #
      # @return [Boolean] returns true
      def anchor?
        true
      end

      # Removes all the labels from the anchor. This is a typical operation that people want to perform
      #
      # @return [GoodData::Model::ProjectBlueprint] Returns changed blueprint
      def strip!
        dataset_blueprint.strip_anchor!
      end

      # Alias for strip!. Removes all the labels from the anchor. This is a typical operation that people want to perform
      #
      # @return [GoodData::Model::ProjectBlueprint] Returns changed blueprint
      def remove!
        strip!
      end

      # Returns labels for anchor or empty array if there are none
      #
      # @return [Array<GoodData::Model::LabelBlueprintField>] Returns list of labels
      def labels
        dataset_blueprint.labels_for_attribute(self)
      end

      # Validates the field for presence of mandatory fields
      #
      # @return [Array<Hash>] Returns list of errors as hashes
      def validate
        validate_presence_of(:id).map do |e|
          { type: :error, message: "Field \"#{e}\" is not defined or empty for anchor \"#{id}\"" }
        end
      end
    end
  end
end
