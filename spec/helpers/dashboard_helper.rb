# encoding: UTF-8

# Local requires
require 'gooddata/models/models'

require_relative 'project_helper'

module DashboardHelper
  DASHBOARD_TITLE = 'Test Dashboard'
  TAB_TITLE = 'Test Title'

  DEFAULT_OPTIONS = {
    :title => DashboardHelper::DASHBOARD_TITLE,
    :tabs => []
  }

  DASHBOARD_DEFINITION = {
    :title => "#{DashboardHelper::DASHBOARD_TITLE} #{Time.new.strftime('%Y%m%d%H%M%S')}",
    :tabs => [
      # First tab
      {
        :title => "First Tab #{Time.new.strftime('%Y%m%d%H%M%S')}",
        :items => [
          # First row
          [],

          # Second row
          []
        ]
      },

      # Second tab
      {
        :title => "Second Tab #{Time.new.strftime('%Y%m%d%H%M%S')}",
        :items => [
          # First row
          [],

          # Second row
          []
        ]
      }
    ]
  }

  DEFAULT_DASHBOARD_TAB_NAME = DASHBOARD_DEFINITION[:tabs].first[:title]

  # TODO: Set this when dashboard is created
  DEFAULT_DASHBOARD_TAB_IDENTIFIER = 'ajIVX3NWeNUk'

  class << self
    def create_default_dashboard(project = ProjectHelper.default_project, options = DEFAULT_OPTIONS)
      return GoodData::Model::DashboardBuilder.create(DASHBOARD_DEFINITION.merge(options)) do |dashboard|
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

    def remove_default_dashboard
      dashboard = default_dashboard
      dashboard.delete
    end

  end
end