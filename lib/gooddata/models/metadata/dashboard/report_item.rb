# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'dashboard_item'

module GoodData
  class ReportItem < DashboardItem
    def initialize(tab, json)
      super
    end

    def filters
      data['filters']
    end

    def filters=(new_filters)
      data['filters'] = new_filters
    end

    def obj
      GoodData::MdObject[data['obj'], :client => tab.dashboard.client, :project => tab.dashboard.project]
    end

    alias_method :object, :obj

    def obj=(new_obj)
      data['obj'] = new_obj.is_a?(String) ? new_obj : new_obj.uri
    end

    alias_method :object=, :obj=

    def style
      data['style']
    end

    def style=(new_style)
      data['style'] = new_style
    end

    def visualization
      data['visualization']
    end

    def visualization=(new_visualization)
      data['visualization'] = new_visualization
    end
  end
end
