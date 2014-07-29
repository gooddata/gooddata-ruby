# encoding: UTF-8

# Local requires
require 'gooddata/models/models'

require_relative 'date_time_helper'
require_relative 'project_helper'

module DashboardHelper
  DASHBOARD_TITLE = "Test Dashboard #{DateTimeHelper::TIMESTAMP}"
  TAB_TITLE = 'Test Tab'

  DEFAULT_OPTIONS = {
    :title => DASHBOARD_TITLE,
    :tabs => []
  }

  DASHBOARD_DEFINITION = {
    :title => DEFAULT_OPTIONS[:title],
    :tabs => [
      # First tab
      {
        :title => "First #{TAB_TITLE} #{DateTimeHelper::TIMESTAMP}",
        :items => [
          # First row
          [],

          # Second row
          []
        ]
      },

      # Second tab
      {
        :title => "Second #{TAB_TITLE} #{DateTimeHelper::TIMESTAMP}",
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
    def create_default_dashboard(project = ProjectHelper.default_project, options = DASHBOARD_DEFINITION)
      return GoodData::Model::DashboardBuilder.create(DEFAULT_OPTIONS.merge(options)) do |dashboard|
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

    def remove_dashboards(project = ProjectHelper.default_project)
      dashboards = project.dashboards
      dashboards.each do |dashboard|
        puts "Deleting dashboard #{dashboard.title} - #{dashboard.uri}"
        dashboard.delete
      end
    end
  end
end