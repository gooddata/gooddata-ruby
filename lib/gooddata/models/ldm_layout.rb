# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2022 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  class LdmLayout
    DEFAULT_EMPTY_LDM_LAYOUT = {
      "ldmLayout" => {
        "layout" => []
      }
    }

    LDM_LAYOUT_URI = '/gdc/dataload/internal/projects/%<project_id>s/ldmLayout'

    class << self
      def get(opts = { :client => GoodData.connection, :project => GoodData.project })
        client, project = GoodData.get_client_and_project(opts)
        get_uri = LDM_LAYOUT_URI % { project_id: project.pid }

        client.get(get_uri)
      end
    end

    def initialize(data)
      @data = data
    end

    def save(opts)
      client, project = GoodData.get_client_and_project(opts)
      post_uri = LDM_LAYOUT_URI % { project_id: project.pid }

      client.post(post_uri, @data, opts)
    end
  end
end
