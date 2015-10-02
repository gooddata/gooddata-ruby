# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'user_filter'

module GoodData
  class VariableUserFilter < UserFilter
    # Creates or updates the variable user filter on the server
    #
    # @return [String]
    def save
      res = client.post(uri, :variable => @json)
      @json[:uri] = res['uri']
      self
    end

    # Method used for replacing values in their state according to mapping. Can be used to replace any values but it is typically used to replace the URIs. Returns a new object of the same type.
    #
    # @param [Array<Array>]Mapping specifying what should be exchanged for what. As mapping should be used output of GoodData::Helpers.prepare_mapping.
    # @return [GoodData::VariableUserFilter]
    def replace(mapping)
      x = GoodData::MdObject.replace_quoted(self, mapping)
      x = GoodData::MdObject.replace_bracketed(x, mapping)
      vals = GoodData::MdObject.find_replaceable_values(x, mapping)
      GoodData::MdObject.replace_bracketed(x, vals)
    end
  end
end
