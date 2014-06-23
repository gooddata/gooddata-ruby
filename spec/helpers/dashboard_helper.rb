# encoding: UTF-8

# Local requires
require 'gooddata/models/models'

require_relative 'project_helper'

module DashboardHelper
  def self.default_dashboard
    ProjectHelper.get_default_project.dashboards.first
  end
end