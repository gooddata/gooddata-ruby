# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../rest/resource'

module GoodData
  class StyleSetting < Rest::Resource
    STYLE_SETTING_PATH = '/gdc/projects/%s/styleSettings'

    EMPTY_OBJECT = {
      'styleSettings' => {
        'chartPalette' => []
      }
    }

    attr_reader :colors

    class << self
      def current(opts = { client: GoodData.connection, project: GoodData.project })
        client, project = GoodData.get_client_and_project(opts)
        uri = STYLE_SETTING_PATH % project.pid
        data = client.get(uri)
        client.create(StyleSetting, data)
      end

      def create(colors, opts = { client: GoodData.connection, project: GoodData.project })
        client, project = GoodData.get_client_and_project(opts)
        colors &= colors # remove duplicate colors
        uri = STYLE_SETTING_PATH % project.pid
        data_to_send = GoodData::Helpers.deep_dup(EMPTY_OBJECT).tap do |d|
          d['styleSettings']['chartPalette'] = colors
                                                .each_with_index
                                                .map do |color, index|
                                                  {
                                                    'guid' => "guid#{index + 1}",
                                                    'fill' => GoodData::Helpers.stringify_keys(color)
                                                  }
                                                end
        end
        style = client.create(StyleSetting, data_to_send)
        client.put(uri, data_to_send)
        style
      end

      def reset(opts = { client: GoodData.connection, project: GoodData.project })
        client, project = GoodData.get_client_and_project(opts)
        uri = STYLE_SETTING_PATH % project.pid
        client.delete(uri)
      end
    end

    def initialize(json)
      super
      @json = json
      @colors = (json ? data['chartPalette'] : []).map do |color|
        {
          r: color['fill']['r'],
          g: color['fill']['g'],
          b: color['fill']['b']
        }
      end
    end
  end
end
