# encoding: UTF-8

# Local requires
require 'gooddata/models/models'

require_relative 'project_helper'

module DashboardHelper
  DEFAULT_DASHBOARD_TAB_NAME = 'First Tab'
  DEFAULT_DASHBOARD_TAB_IDENTIFIER = 'b4deec096506'

  class << self
    # Gets the dashboard which can be used in tests
    def default_dashboard
      ProjectHelper.get_default_project.dashboards.first
    end

    # Gets the dashboard tab which can be used in tests
    def default_dashboard_tab
      default_dashboard.tabs.first
    end
  end
end