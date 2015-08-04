# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'blueprint_field'

module GoodData
  module Model
    class LabelBlueprintField < BlueprintField
      # Returns the attribute this label is referencing to
      #
      # @return [AttributeBlueprintField] the object representing attribute in the blueprint
      def attribute
        dataset_blueprint.attribute_for_label(self)
      end

      # Returns gd_data_type
      #
      # @return [String] returns gd_data_type of the label
      def gd_data_type
        data[:gd_data_type] || Model::DEFAULT_ATTRIBUTE_DATATYPE
      end

      # Returns gd_data_type
      #
      # @return [String] returns gd_type of the label
      def gd_type
        data[:gd_type] || Model::DEFAULT_TYPE
      end

      # Validates the fields in the label
      #
      # @return [Array] returns list of the errors represented by hash structures
      def validate
        validate_presence_of(:id, :reference).map do |e|
          { type: :error, message: "Field \"#{e}\" is not defined or empty for label \"#{id}\"" }
        end
      end
    end
  end
end
