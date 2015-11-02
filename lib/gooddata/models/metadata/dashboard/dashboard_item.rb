# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../../../rest/resource'

module GoodData
  class DashboardItem < Rest::Resource
    attr_reader :tab
    attr_accessor :json

    ASSIGNABLE_MEMBERS = [
      :pos_x,
      :pos_y,
      :position_x,
      :position_y,
      :size_x,
      :size_y
    ]

    def initialize(tab, json)
      @tab = tab
      @json = json
    end

    def filters
      data['filters']
    end

    def filters=(new_filters)
      data['filters'] = new_filters
    end

    def position_x
      data['positionX']
    end

    alias_method :pos_x, :position_x

    def position_x=(new_position_x)
      data['positionX'] = new_position_x
    end

    alias_method :pos_x=, :position_x=

    def position_y
      data['positionY']
    end

    alias_method :pos_y, :position_y

    def position_y=(new_position_y)
      data['positionY'] = new_position_y
    end

    alias_method :pos_y=, :position_y=

    def size_x
      data['sizeX']
    end

    def size_x=(new_size_x)
      data['sizeX'] = new_size_x
    end

    def size_y
      data['sizeY']
    end

    def size_y=(new_size_y)
      data['sizeY'] = new_size_y
    end
  end
end
