# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'schema_blueprint'

module GoodData
  module Model
    class DateDimension < GoodData::Model::SchemaBlueprint
      # Returns urn of the date dataset
      #
      # @return [String]
      def urn
        data[:urn]
      end
    end
  end
end
