# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'blueprint_field'

module GoodData
  module Model
    class AttributeBlueprintField < BlueprintField
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
        validate_presence_of(:id).map do |e|
          { type: :error, message: "Field \"#{e}\" is not defined or empty for attribute \"#{id}\"" }
        end
      end
    end
  end
end
