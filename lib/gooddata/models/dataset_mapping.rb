# encoding: UTF-8
#
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  class DatasetMapping

    DATASET_MAPPING_GET_URI = '/gdc/dataload/projects/%{project_id}/modelMapping/datasets'
    DATASET_MAPPING_UPDATE_URI = '/gdc/dataload/projects/%{project_id}/modelMapping/datasets/bulk/upsert'

    class << self

      def [](opts = { :client => GoodData.connection, :project => GoodData.project })
        client, project = GoodData.get_client_and_project(opts)
        get_uri = DATASET_MAPPING_GET_URI % { project_id: project.pid }
        res = client.get(get_uri)
        res
      end

      alias_method :get, :[]

    end

    def initialize(data)
      @data = data
    end

    def save(opts)
      client, project = GoodData.get_client_and_project(opts)

      post_uri = DATASET_MAPPING_UPDATE_URI % { project_id: project.pid }
      res = client.post(post_uri, @data, opts)
      res
    end
  end
end
