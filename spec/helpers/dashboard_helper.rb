# encoding: UTF-8

# Local requires
require 'gooddata/models/models'

require_relative 'project_helper'

module DashboardHelper
  DASHBOARD_TITLE = 'Test Dashboard'
  TAB_TITLE = 'Test Title'

  DEFAULT_DASHBOARD_TAB_NAME = 'First Tab'
  DEFAULT_DASHBOARD_TAB_IDENTIFIER = 'aaOQ0StaaI7o'

  DEFAULT_OPTIONS = {
    :title => DashboardHelper::DASHBOARD_TITLE,
    :tabs => [
      # First tab
      {
        :title => 'First tab'
      },

      # Second tab
      {
        :title => 'Second tab'
      }
    ]
  }

  class << self
    def create_default_dashboard(project = ProjectHelper.default_project, title = DASHBOARD_TITLE, options = DEFAULT_OPTIONS)
      return GoodData::Model::DashboardBuilder.create(title, options) do |dashboard|
        dashboard.save(project)
      end
    end

    # Gets the dashboard which can be used in tests
    def default_dashboard(project = ProjectHelper.default_project, title = DASHBOARD_TITLE)
      project.dashboard(title)
    end

    # Gets the dashboard tab which can be used in tests
    def default_dashboard_tab(project = ProjectHelper.default_project, dashboard_title = DASHBOARD_TITLE, tab_name = TAB_TITLE)
      default_dashboard(project, dashboard_title).tab(tab_name)
    end
  end
end