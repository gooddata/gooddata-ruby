# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  class AnalyticalVisualizationObject < GoodData::MdObject
    class << self
      # Create a specify object in the specify project
      #
      # @param object_data [Hash] the data of object will be created
      # @param klass [Class] A class used for instantiating the returned data
      # @param empty_data_object [Hash] the empty data of object will be created
      # @param assignable_properties [Hash] the properties allow updating
      # @param options [Hash] The project that the object will be created in
      # @return klass object
      def create(object_data, klass, empty_data_object = {}, assignable_properties = [], options = { :client => GoodData.client, :project => GoodData.project })
        client, project = GoodData.get_client_and_project(GoodData::Helpers.symbolize_keys(options))

        res = client.create(klass, GoodData::Helpers.deep_dup(GoodData::Helpers.stringify_keys(empty_data_object)), :project => project)
        object_data.each do |k, v|
          res.send("#{k}=", v) if assignable_properties.include? k
        end
        res
      end
    end
  end
end
