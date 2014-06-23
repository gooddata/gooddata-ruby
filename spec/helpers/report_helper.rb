# encoding: UTF-8

# Local requires
require 'gooddata/models/models'

require_relative 'project_helper'

module ReportHelper
  def self.default_report
    ProjectHelper.get_default_project.reports.first
  end
end
